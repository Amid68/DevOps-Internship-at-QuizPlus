######################################################
#
# @file main.py
# @brief Enhanced FastAPI app with deployment info
# @author Ameed Othman
#
######################################################

from fastapi import FastAPI, Response
from datetime import datetime
import psutil
import os
import socket

app = FastAPI(
    title="Process Monitor API",
    version="2.0.0",
    description="Enhanced API with zero-downtime deployment support"
)

# Deployment metadata
DEPLOYMENT_INFO = {
    "container_color": os.environ.get("CONTAINER_COLOR", "unknown"),
    "environment": os.environ.get("ENVIRONMENT", "production"),
    "start_time": datetime.utcnow().isoformat(),
    "hostname": socket.gethostname(),
    "version": os.environ.get("APP_VERSION", "2.0.0")
}

def get_processes_by_memory(limit=50):
    """Get top processes by memory consumption"""
    processes = []

    for proc in psutil.process_iter(['name', 'memory_percent', 'pid', 'cpu_percent']):
        try:
            processes.append({
                'pid': proc.info['pid'],
                'name': proc.info['name'],
                'memory_percent': round(proc.info['memory_percent'], 2),
                'cpu_percent': round(proc.info.get('cpu_percent', 0), 2)
            })
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass

    # Sort by memory percentage (descending) and get top N
    top_processes = sorted(processes, key=lambda x: x['memory_percent'], reverse=True)[:limit]
    return top_processes

@app.get("/")
def root():
    """Root endpoint with deployment information"""
    return {
        "message": "Process Monitor API",
        "deployment": DEPLOYMENT_INFO,
        "endpoints": {
            "processes": "/processes",
            "health": "/healthz",
            "metrics": "/metrics",
            "info": "/info"
        }
    }

@app.get("/processes")
def get_procs(limit: int = 50):
    """Get running processes sorted by memory usage"""
    return {
        "timestamp": datetime.utcnow().isoformat(),
        "count": limit,
        "processes": get_processes_by_memory(limit)
    }

@app.get("/healthz")
def health_check(response: Response):
    """Health check endpoint for container orchestration"""
    try:
        # Perform actual health checks
        cpu_percent = psutil.cpu_percent(interval=0.1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        health_status = {
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat(),
            "container": DEPLOYMENT_INFO["container_color"],
            "checks": {
                "cpu_ok": cpu_percent < 90,
                "memory_ok": memory.percent < 90,
                "disk_ok": disk.percent < 90
            },
            "metrics": {
                "cpu_percent": round(cpu_percent, 2),
                "memory_percent": round(memory.percent, 2),
                "disk_percent": round(disk.percent, 2)
            }
        }
        
        # Set appropriate status code
        if all(health_status["checks"].values()):
            response.status_code = 200
        else:
            response.status_code = 503
            health_status["status"] = "degraded"
            
        return health_status
        
    except Exception as e:
        response.status_code = 503
        return {
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }

@app.get("/metrics")
def get_metrics():
    """Prometheus-compatible metrics endpoint"""
    cpu = psutil.cpu_percent(interval=0.1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    net = psutil.net_io_counters()
    
    metrics = []
    metrics.append(f'# HELP cpu_usage_percent CPU usage percentage')
    metrics.append(f'# TYPE cpu_usage_percent gauge')
    metrics.append(f'cpu_usage_percent {cpu}')
    
    metrics.append(f'# HELP memory_usage_percent Memory usage percentage')
    metrics.append(f'# TYPE memory_usage_percent gauge')
    metrics.append(f'memory_usage_percent {memory.percent}')
    
    metrics.append(f'# HELP disk_usage_percent Disk usage percentage')
    metrics.append(f'# TYPE disk_usage_percent gauge')
    metrics.append(f'disk_usage_percent {disk.percent}')
    
    metrics.append(f'# HELP network_bytes_sent Total bytes sent')
    metrics.append(f'# TYPE network_bytes_sent counter')
    metrics.append(f'network_bytes_sent {net.bytes_sent}')
    
    metrics.append(f'# HELP network_bytes_recv Total bytes received')
    metrics.append(f'# TYPE network_bytes_recv counter')
    metrics.append(f'network_bytes_recv {net.bytes_recv}')
    
    return Response(content='\n'.join(metrics), media_type='text/plain')

@app.get("/info")
def get_info():
    """Detailed application and system information"""
    return {
        "application": {
            "name": "Process Monitor API",
            "version": DEPLOYMENT_INFO["version"],
            "environment": DEPLOYMENT_INFO["environment"],
            "container": DEPLOYMENT_INFO["container_color"],
            "start_time": DEPLOYMENT_INFO["start_time"],
            "uptime_seconds": (datetime.utcnow() - datetime.fromisoformat(DEPLOYMENT_INFO["start_time"])).total_seconds()
        },
        "system": {
            "hostname": socket.gethostname(),
            "platform": os.name,
            "cpu_count": psutil.cpu_count(),
            "memory_total_gb": round(psutil.virtual_memory().total / (1024**3), 2),
            "python_version": os.sys.version
        }
    }

@app.on_event("startup")
async def startup_event():
    """Log startup information"""
    print(f"🚀 Starting FastAPI application")
    print(f"📦 Container: {DEPLOYMENT_INFO['container_color']}")
    print(f"🌍 Environment: {DEPLOYMENT_INFO['environment']}")
    print(f"🏷️ Version: {DEPLOYMENT_INFO['version']}")
    print(f"⏰ Started at: {DEPLOYMENT_INFO['start_time']}")

@app.on_event("shutdown")
async def shutdown_event():
    """Log shutdown information"""
    print(f"🛑 Shutting down FastAPI application")
    print(f"📦 Container: {DEPLOYMENT_INFO['container_color']}")
    print(f"⏱️ Uptime: {(datetime.utcnow() - datetime.fromisoformat(DEPLOYMENT_INFO['start_time'])).total_seconds()} seconds")
