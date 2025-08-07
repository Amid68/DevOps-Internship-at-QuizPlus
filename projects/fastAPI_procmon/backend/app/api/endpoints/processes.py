from fastapi import APIRouter, Query
from datetime import datetime
from app.models.schemas import ProcessResponse
from app.core.monitoring import SystemMonitor


router = APIRouter(prefix="/processes", tags=["processes"])


@router.get("", response_model=ProcessResponse)
async def get_processes(limit: int = Query(50, ge=1, le=200)):
    """Get running processes sorted by memory usage"""
    processes = SystemMonitor.get_processes_by_memory(limit)
    
    return ProcessResponse(
        timestamp=datetime.utcnow(),
        count=len(processes),
        processes=processes
    )
