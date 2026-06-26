from datetime import datetime
from typing import Optional
from pydantic import BaseModel


# ── Message ──────────────────────────────────────────────────────────────────

class MessageOut(BaseModel):
    id: str
    role: str
    content: str
    source: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


# ── Session ───────────────────────────────────────────────────────────────────

class SessionOut(BaseModel):
    id: str
    title: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class SessionWithMessages(SessionOut):
    messages: list[MessageOut] = []


class SessionCreate(BaseModel):
    title: str = "New Chat"


class SessionRename(BaseModel):
    title: str


# ── Chat ─────────────────────────────────────────────────────────────────────

class HistoryItem(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    session_id: str
    message: str
    history: list[HistoryItem] = []


# ── Manual Data ───────────────────────────────────────────────────────────────

class ManualEntry(BaseModel):
    id: str
    question: str
    keywords: list[str]
    answer: str
    category: str


class ManualEntryCreate(BaseModel):
    question: str
    keywords: list[str]
    answer: str
    category: str = "general"


class ManualEntryUpdate(BaseModel):
    question: Optional[str] = None
    keywords: Optional[list[str]] = None
    answer: Optional[str] = None
    category: Optional[str] = None
