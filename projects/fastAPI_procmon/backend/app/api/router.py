from fastapi import APIRouter
from app.api.endpoints import processes, health, metrics, info

api_router = APIRouter()

api_router.include_router(processes.router)
api_router.include_router(health.router)
api_router.include_router(metrics.router)
api_router.include_router(info.router)
