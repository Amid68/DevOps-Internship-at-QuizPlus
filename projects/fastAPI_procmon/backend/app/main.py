from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from datetime import datetime
import os

from app.core.config import settings
from app.api.router import api_router
from app.models.schemas import RootResponse, DeploymentInfo


# Deployment metadata
DEPLOYMENT_INFO = DeploymentInfo(
    container_color=os.environ.get("CONTAINER_COLOR", "unknown"),
    environment=os.environ.get("ENVIRONMENT", "production"),
    start_time=datetime.utcnow(),
    hostname=socket.gethostname() if 'socket' in dir() else "unknown",
    version=os.environ.get("APP_VERSION", settings.app_version)
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    # Startup
    print(f"🚀 Starting {settings.app_name}")
    print(f"📦 Container: {DEPLOYMENT_INFO.container_color}")
    print(f"🌍 Environment: {DEPLOYMENT_INFO.environment}")
    print(f"🏷️ Version: {DEPLOYMENT_INFO.version}")
    print(f"⏰ Started at: {DEPLOYMENT_INFO.start_time}")
    
    yield
    
    # Shutdown
    print(f"🛑 Shutting down {settings.app_name}")
    print(f"📦 Container: {DEPLOYMENT_INFO.container_color}")
    uptime = (datetime.utcnow() - DEPLOYMENT_INFO.start_time).total_seconds()
    print(f"⏱️ Uptime: {uptime} seconds")


# Create FastAPI app
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description=settings.app_description,
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
app.include_router(api_router)


@app.get("/", response_model=RootResponse)
async def root():
    """Root endpoint with deployment information"""
    return RootResponse(
        message=settings.app_name,
        deployment=DEPLOYMENT_INFO,
        endpoints={
            "processes": "/processes",
            "health": "/healthz",
            "metrics": "/metrics",
            "info": "/info",
            "docs": "/docs",
            "redoc": "/redoc"
        }
    )
