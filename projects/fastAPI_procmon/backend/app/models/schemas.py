from pydantic import BaseModel, Field
from datetime import datetime
from typing import List, Dict, Any, Optional


class ProcessInfo(BaseModel):
    """Schema for process information"""
    pid: int = Field(..., description="Process ID")
    name: str = Field(..., description="Process name")
    memory_percent: float = Field(..., description="Memory usage percentage")
    cpu_percent: float = Field(..., description="CPU usage percentage")


class ProcessResponse(BaseModel):
    """Response schema for process list"""
    timestamp: datetime = Field(..., description="Response timestamp")
    count: int = Field(..., description="Number of processes returned")
    processes: List[ProcessInfo] = Field(..., description="List of processes")


class HealthCheck(BaseModel):
    """Health check schema"""
    status: str = Field(..., description="Health status")
    timestamp: datetime = Field(..., description="Check timestamp")
    container: str = Field(..., description="Container identifier")
    checks: Dict[str, bool] = Field(..., description="Individual health checks")
    metrics: Dict[str, float] = Field(..., description="System metrics")


class DeploymentInfo(BaseModel):
    """Deployment information schema"""
    container_color: str
    environment: str
    start_time: datetime
    hostname: str
    version: str


class ApplicationInfo(BaseModel):
    """Application information schema"""
    application: Dict[str, Any]
    system: Dict[str, Any]


class RootResponse(BaseModel):
    """Root endpoint response"""
    message: str
    deployment: DeploymentInfo
    endpoints: Dict[str, str]
