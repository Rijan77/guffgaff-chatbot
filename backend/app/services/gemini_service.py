import google.generativeai as genai
from typing import AsyncGenerator

from app.config import GEMINI_API_KEY, GEMINI_MODEL, GEMINI_SYSTEM_PROMPT
from app.schemas.schemas import HistoryItem, ManualEntry


def _build_context_block(entries: list[ManualEntry]) -> str:
    lines = ["<trusted_reference>"]
    for e in entries:
        lines.append(f"Q: {e.question}")
        lines.append(f"A: {e.answer}")
        lines.append("")
    lines.append("</trusted_reference>")
    lines.append(
        "Use the above reference data when relevant. "
        "If it directly answers the question, rely on it. "
        "Otherwise answer from your own knowledge."
    )
    return "\n".join(lines)


def _convert_history(history: list[HistoryItem]) -> list[dict]:
    converted = []
    for msg in history:
        role = "model" if msg.role == "assistant" else "user"
        converted.append({"role": role, "parts": [{"text": msg.content}]})
    return converted


class GeminiService:
    def __init__(self):
        genai.configure(api_key=GEMINI_API_KEY)

    async def stream(
        self,
        message: str,
        history: list[HistoryItem],
        context_entries: list[ManualEntry] | None = None,
    ) -> AsyncGenerator[str, None]:
        system = GEMINI_SYSTEM_PROMPT
        if context_entries:
            system = system + "\n\n" + _build_context_block(context_entries)

        model = genai.GenerativeModel(
            model_name=GEMINI_MODEL,
            system_instruction=system,
        )

        gemini_history = _convert_history(history)
        chat = model.start_chat(history=gemini_history)

        response = await chat.send_message_async(message, stream=True)
        async for chunk in response:
            if chunk.text:
                yield chunk.text


gemini_service = GeminiService()
