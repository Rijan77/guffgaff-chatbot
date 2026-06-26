import json
import re
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from app.config import MANUAL_DATA_PATH
from app.schemas.schemas import ManualEntry, ManualEntryCreate, ManualEntryUpdate


def _tokenize(text: str) -> set[str]:
    return {w.lower() for w in re.findall(r"\b[a-zA-Z]{2,}\b", text)}


def _jaccard(a: set[str], b: set[str]) -> float:
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


@dataclass
class ScoredEntry:
    entry: ManualEntry
    score: float


class ManualService:
    def __init__(self):
        self._path = Path(MANUAL_DATA_PATH)
        self._entries: list[ManualEntry] = []
        self._load()

    # ── Persistence ─────────────────────────────────────────────────────────

    def _load(self):
        if self._path.exists():
            data = json.loads(self._path.read_text(encoding="utf-8"))
            self._entries = [ManualEntry(**item) for item in data]

    def _save(self):
        self._path.write_text(
            json.dumps([e.model_dump() for e in self._entries], indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    # ── Scoring ──────────────────────────────────────────────────────────────

    def _score(self, query: str, entry: ManualEntry) -> float:
        query_tokens = _tokenize(query)

        # Score against the question text
        question_tokens = _tokenize(entry.question)
        question_score = _jaccard(query_tokens, question_tokens)

        # Score against keywords (each keyword is a phrase; flatten to tokens)
        kw_tokens = set()
        for kw in entry.keywords:
            kw_tokens.update(_tokenize(kw))

        if kw_tokens:
            kw_score = len(query_tokens & kw_tokens) / len(kw_tokens)
        else:
            kw_score = 0.0

        # Weighted combination — keywords carry more signal than open question text
        return question_score * 0.45 + kw_score * 0.55

    # ── Public API ───────────────────────────────────────────────────────────

    def search(self, query: str) -> list[ScoredEntry]:
        results = [ScoredEntry(entry=e, score=self._score(query, e)) for e in self._entries]
        results.sort(key=lambda x: x.score, reverse=True)
        return results

    def get_all(self) -> list[ManualEntry]:
        return list(self._entries)

    def get_by_id(self, entry_id: str) -> Optional[ManualEntry]:
        return next((e for e in self._entries if e.id == entry_id), None)

    def create(self, data: ManualEntryCreate) -> ManualEntry:
        entry = ManualEntry(id=str(uuid.uuid4()), **data.model_dump())
        self._entries.append(entry)
        self._save()
        return entry

    def update(self, entry_id: str, data: ManualEntryUpdate) -> Optional[ManualEntry]:
        for i, e in enumerate(self._entries):
            if e.id == entry_id:
                updated = e.model_dump()
                patch = {k: v for k, v in data.model_dump().items() if v is not None}
                updated.update(patch)
                self._entries[i] = ManualEntry(**updated)
                self._save()
                return self._entries[i]
        return None

    def delete(self, entry_id: str) -> bool:
        original_len = len(self._entries)
        self._entries = [e for e in self._entries if e.id != entry_id]
        if len(self._entries) < original_len:
            self._save()
            return True
        return False


manual_service = ManualService()
