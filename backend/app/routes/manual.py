from fastapi import APIRouter, HTTPException

from app.schemas.schemas import ManualEntry, ManualEntryCreate, ManualEntryUpdate
from app.services.manual_service import manual_service

router = APIRouter(prefix="/manual", tags=["manual"])


@router.get("", response_model=list[ManualEntry])
async def list_entries():
    return manual_service.get_all()


@router.post("", response_model=ManualEntry, status_code=201)
async def create_entry(body: ManualEntryCreate):
    return manual_service.create(body)


@router.put("/{entry_id}", response_model=ManualEntry)
async def update_entry(entry_id: str, body: ManualEntryUpdate):
    entry = manual_service.update(entry_id, body)
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    return entry


@router.delete("/{entry_id}", status_code=204)
async def delete_entry(entry_id: str):
    if not manual_service.delete(entry_id):
        raise HTTPException(status_code=404, detail="Entry not found")
