import psutil
import socket
from datetime import datetime
from typing import List, Dict, Any


class SystemMonitor:
    """System monitoring utilities"""
    
    @staticmethod
    def get_processes_by_memory(limit: int = 50) -> List[Dict[str, Any]]:
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
        return sorted(processes, key=lambda x: x['memory_percent'], reverse=True)[:limit]
    
    @staticmethod
    def get_system_metrics() -> Dict[str, float]:
        """Get system metrics"""
        cpu_percent = psutil.cpu_percent(interval=0.1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        return {
            "cpu_percent": round(cpu_percent, 2),
            "memory_percent": round(memory.percent, 2),
            "disk_percent": round(disk.percent, 2)
        }
    
    @staticmethod
    def check_system_health() -> Dict[str, Any]:
        """Check system health status"""
        metrics = SystemMonitor.get_system_metrics()
        
        checks = {
            "cpu_ok": metrics["cpu_percent"] < 90,
            "memory_ok": metrics["memory_percent"] < 90,
            "disk_ok": metrics["disk_percent"] < 90
        }
        
        status = "healthy" if all(checks.values()) else "degraded"
        
        return {
            "status": status,
            "checks": checks,
            "metrics": metrics
        }
    
    @staticmethod
    def get_network_stats() -> Dict[str, int]:
        """Get network statistics"""
        net = psutil.net_io_counters()
        return {
            "bytes_sent": net.bytes_sent,
            "bytes_recv": net.bytes_recv,
            "packets_sent": net.packets_sent,
            "packets_recv": net.packets_recv
        }
