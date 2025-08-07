from fastapi import APIRouter, Response
from app.core.monitoring import SystemMonitor


router = APIRouter(prefix="/metrics", tags=["metrics"])


@router.get("")
async def get_metrics():
    """Prometheus-compatible metrics endpoint"""
    system_metrics = SystemMonitor.get_system_metrics()
    network_stats = SystemMonitor.get_network_stats()
    
    metrics = []
    
    # CPU metrics
    metrics.append(f'# HELP cpu_usage_percent CPU usage percentage')
    metrics.append(f'# TYPE cpu_usage_percent gauge')
    metrics.append(f'cpu_usage_percent {system_metrics["cpu_percent"]}')
    
    # Memory metrics
    metrics.append(f'# HELP memory_usage_percent Memory usage percentage')
    metrics.append(f'# TYPE memory_usage_percent gauge')
    metrics.append(f'memory_usage_percent {system_metrics["memory_percent"]}')
    
    # Disk metrics
    metrics.append(f'# HELP disk_usage_percent Disk usage percentage')
    metrics.append(f'# TYPE disk_usage_percent gauge')
    metrics.append(f'disk_usage_percent {system_metrics["disk_percent"]}')
    
    # Network metrics
    metrics.append(f'# HELP network_bytes_sent Total bytes sent')
    metrics.append(f'# TYPE network_bytes_sent counter')
    metrics.append(f'network_bytes_sent {network_stats["bytes_sent"]}')
    
    metrics.append(f'# HELP network_bytes_recv Total bytes received')
    metrics.append(f'# TYPE network_bytes_recv counter')
    metrics.append(f'network_bytes_recv {network_stats["bytes_recv"]}')
    
    return Response(content='\n'.join(metrics), media_type='text/plain')

