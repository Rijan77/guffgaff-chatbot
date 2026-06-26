import os
from dotenv import load_dotenv

load_dotenv()

GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./guffgaff.db")
MANUAL_DATA_PATH: str = os.getenv("MANUAL_DATA_PATH", "manual_data.json")

GEMINI_MODEL: str = "gemini-1.5-flash"
GEMINI_SYSTEM_PROMPT: str = (
    "You are GuffGaff AI, a helpful, smart, and friendly conversational assistant. "
    "Answer clearly and concisely. Format with markdown when it adds clarity (code blocks, lists, bold). "
    "If you don't know something, say so honestly."
)

EXACT_MATCH_THRESHOLD: float = 0.72
CONTEXT_MATCH_THRESHOLD: float = 0.28
MAX_CONTEXT_ENTRIES: int = 3
