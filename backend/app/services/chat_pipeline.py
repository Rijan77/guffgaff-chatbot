"""
Hybrid chat pipeline — three-stage decision tree:

  Stage 1 — Manual override
      Score every manual entry against the incoming query.
      If the top score ≥ EXACT_MATCH_THRESHOLD, return that curated answer
      directly (source = "manual").  No Gemini call is made.

  Stage 2 — Context-injected Gemini  (RAG-lite)
      If the top score is below the exact threshold but at least one entry
      scores ≥ CONTEXT_MATCH_THRESHOLD, inject the top-N matching entries into
      Gemini's system prompt as trusted reference data and stream the reply
      (source = "gemini+context").

  Stage 3 — Pure Gemini fallback
      Nothing is relevant.  Call Gemini with the base system prompt
      (source = "gemini").
"""

from typing import AsyncGenerator

from app.config import EXACT_MATCH_THRESHOLD, CONTEXT_MATCH_THRESHOLD, MAX_CONTEXT_ENTRIES
from app.schemas.schemas import HistoryItem
from app.services.gemini_service import gemini_service
from app.services.manual_service import manual_service


async def process(
    message: str,
    history: list[HistoryItem],
) -> AsyncGenerator[tuple[str, str, bool], None]:
    """
    Yields (text_chunk, source, is_done) tuples.
    The final yield always has is_done=True and text_chunk="".
    """
    scored = manual_service.search(message)
    best_score = scored[0].score if scored else 0.0

    # ── Stage 1: manual override ─────────────────────────────────────────────
    if best_score >= EXACT_MATCH_THRESHOLD:
        answer = scored[0].entry.answer
        yield answer, "manual", True
        return

    # ── Stage 2 or 3: Gemini ─────────────────────────────────────────────────
    context_entries = [
        s.entry
        for s in scored
        if s.score >= CONTEXT_MATCH_THRESHOLD
    ][:MAX_CONTEXT_ENTRIES]

    source = "gemini+context" if context_entries else "gemini"

    async for chunk in gemini_service.stream(message, history, context_entries or None):
        yield chunk, source, False

    yield "", source, True
