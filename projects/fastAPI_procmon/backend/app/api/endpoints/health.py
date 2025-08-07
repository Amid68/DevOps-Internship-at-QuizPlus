from fastapi import APIRouter, Response
from datetime import datetime
from app.models.schemas import HealthCheck
from app.core.config import settings
from app.core.monitoring import SystemMonitor


router = APIRouter(prefix="/healthz", tags=["health"])


@router.get("", response_model=HealthCheck)
async def health_check(response: Response):
    """Health check endpoint for container orchestration"""
    try:
        health_data = SystemMonitor.check_system_health()
        
        health_status = HealthCheck(
            status=health_data["status"],
            timestamp=datetime.utcnow(),
            container=settings.container_color,
            checks=health_data["checks"],
            metrics=health_data["metrics"]
        )
        
        # Set appropriate status code
        if health_data["status"] == "healthy":
            response.status_code = 200
        else:
            response.status_code = 503
        
        return health_status
        
    except Exception as e:
        response.status_code = 503
        return HealthCheck(
            status="unhealthy",
            timestamp=datetime.utcnow(),
            container=settings.container_color,
            checks={
                "cpu_ok": False,
                "memory_ok": False,
                "disk_ok": False
            },
            metrics={
                "cpu_percent": 0,
                "memory_percent": 0,
                "disk_percent": 0
            }
        )
