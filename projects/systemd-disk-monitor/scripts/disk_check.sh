#!/bin/bash
#
# @brief Disk usage monitoring script for systemd service
# @author Ameed Othman
# @date July 10, 2025
# @description Continuously monitors disk usage and logs alerts when thresholds are exceeded

# Configuration
THRESHOLD=80
LOG_FILE="/var/log/disk-monitor.log"
CHECK_INTERVAL=30

# Function to log messages with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to handle script termination
cleanup() {
    log_message "INFO: Disk monitor service stopping"
    exit 0
}

# Set up signal handlers for graceful shutdown
trap cleanup SIGTERM SIGINT

# Log service startup
log_message "INFO: Disk monitor service started (PID: $$)"
log_message "INFO: Monitoring root filesystem with ${THRESHOLD}% threshold"
log_message "INFO: Check interval: ${CHECK_INTERVAL} seconds"

# Main monitoring loop
while true; do
    # Check disk usage for root filesystem
    USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    # Validate that we got a numeric value
    if [[ "$USAGE" =~ ^[0-9]+$ ]]; then
        if [ "$USAGE" -gt "$THRESHOLD" ]; then
            log_message "WARNING: Root filesystem usage is ${USAGE}% (threshold: ${THRESHOLD}%)"
        else
            log_message "INFO: Root filesystem usage is ${USAGE}% - OK"
        fi
    else
        log_message "ERROR: Failed to get disk usage information"
    fi
    
    sleep "$CHECK_INTERVAL"
done
