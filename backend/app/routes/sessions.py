from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.db.base import get_db
from app.models.database import Session, Message
from app.schemas.schemas import SessionOut, SessionWithMessages, SessionCreate, SessionRename

router = APIRouter(prefix="/sessions", tags=["sessions"])


@router.get("", response_model=list[SessionOut])
async def list_sessions(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Session).order_by(Session.updated_at.desc()))
    return result.scalars().all()


@router.get("/{session_id}", response_model=SessionWithMessages)
async def get_session(session_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Session)
        .options(selectinload(Session.messages))
        .where(Session.id == session_id)
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return session


@router.post("", response_model=SessionOut, status_code=201)
async def create_session(body: SessionCreate, db: AsyncSession = Depends(get_db)):
    session = Session(title=body.title)
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session


@router.put("/{session_id}", response_model=SessionOut)
async def rename_session(session_id: str, body: SessionRename, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Session).where(Session.id == session_id))
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    session.title = body.title
    await db.commit()
    await db.refresh(session)
    return session


@router.delete("/{session_id}", status_code=204)
async def delete_session(session_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Session).where(Session.id == session_id))
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    await db.delete(session)
    await db.commit()
