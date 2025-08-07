import os
import psutil
import socket
from fastapi import APIRouter
from datetime import datetime
from app.models.schemas import ApplicationInfo
from app.core.config import settings


router = APIRouter(prefix="/info", tags=["info"])

# Store start time when module is loaded
START_TIME = datetime.utcnow()


@router.get("", response_model=ApplicationInfo)
async def get_info():
    """Detailed application and system information"""
    uptime_seconds = (datetime.utcnow() - START_TIME).total_seconds()
    
    return ApplicationInfo(
        application={
            "name": settings.app_name,
            "version": settings.app_version,
            "environment": settings.environment,
            "container": settings.container_color,
            "start_time": START_TIME,
            "uptime_seconds": uptime_seconds
        },
        system={
            "hostname": socket.gethostname(),
            "platform": os.name,
            "cpu_count": psutil.cpu_count(),
            "memory_total_gb": round(psutil.virtual_memory().total / (1024**3), 2),
            "python_version": os.sys.version
        }
    )
