import os
from typing import Optional
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings"""
    
    # App metadata
    app_name: str = "Process Monitor API"
    app_version: str = "2.1.0"
    app_description: str = "Enhanced Process Monitoring with Modern UI"
    
    # Environment
    environment: str = "production"
    container_color: str = "unknown"
    
    # CORS settings
    cors_origins: list = ["*"]  # In production, specify exact origins
    
    # Server settings
    host: str = "0.0.0.0"
    port: int = 8000
    
    # Monitoring settings
    process_limit: int = 50
    health_check_interval: float = 0.1
    
    class Config:
        env_prefix = ""
        case_sensitive = False


settings = Settings()
