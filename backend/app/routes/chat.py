import json
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sse_starlette.sse import EventSourceResponse

from app.db.base import AsyncSessionLocal, get_db
from app.models.database import Session, Message
from app.schemas.schemas import ChatRequest
from app.services import chat_pipeline

router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("")
async def chat(body: ChatRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Session).where(Session.id == body.session_id))
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    # Persist user message
    user_msg = Message(session_id=body.session_id, role="user", content=body.message)
    db.add(user_msg)
    session.updated_at = datetime.utcnow()

    # Auto-title on first message
    if session.title == "New Chat" and body.message.strip():
        session.title = body.message.strip()[:60]

    await db.commit()

    session_id = body.session_id
    message = body.message
    history = body.history

    async def event_generator():
        accumulated: list[str] = []
        final_source = "gemini"

        try:
            async for chunk, source, done in chat_pipeline.process(message, history):
                final_source = source
                if not done:
                    accumulated.append(chunk)
                data = json.dumps({"text": chunk, "source": source, "done": done})
                yield {"data": data}
        except Exception as exc:
            error_data = json.dumps({"error": str(exc), "done": True})
            yield {"data": error_data}
            return

        # Persist assistant reply in a fresh session (avoids post-commit issues)
        full_text = "".join(accumulated)
        if full_text:
            async with AsyncSessionLocal() as save_db:
                ai_msg = Message(
                    session_id=session_id,
                    role="assistant",
                    content=full_text,
                    source=final_source,
                )
                save_db.add(ai_msg)
                await save_db.commit()

    return EventSourceResponse(event_generator())
