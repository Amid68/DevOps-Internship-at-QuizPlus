######################################################
#
# @file main.py
# @brief simple FastAPI app that returns 
# running processes with their memory  consumption
#
# @author Ameed Othman
#
######################################################

from fastapi import FastAPI
import psutil # this library enables us to get info on running processes

app = FastAPI()

def get_processes_by_memory(limit=50):
    """Get top processes by memory consumption"""
    processes = []

    for proc in psutil.process_iter(['name', 'memory_percent']):
        try:
            processes.append({
                'name': proc.info['name'],
                'memory_percent': proc.info['memory_percent']
            })
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            # Skip processes that can't be accessed
            pass

    # Sort by memory percentage (descending) and get top N
    top_processes = sorted(processes, key=lambda x: x['memory_percent'], reverse=True)[:limit]

    return top_processes

@app.get("/processes")
def get_procs():
    return get_processes_by_memory()

@app.get("/healthz")
def health_check():
    return {"status": "healthy"}
