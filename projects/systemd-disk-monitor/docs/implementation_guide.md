# Systemd Service Implementation Guide

**Author:** Ameed Othman  
**Date:** July 10, 2025  
**Environment:** Ubuntu Server on UTM (MacBook Pro M1)

## Overview

This guide provides a step-by-step walkthrough for creating a custom systemd service that monitors disk usage and logs alerts. It covers the complete systemd service lifecycle from creation to management, including troubleshooting common issues.

## Learning Objectives

- Create custom systemd service files
- Understand service unit file structure and configuration options
- Manage service states and lifecycle operations
- Debug common systemd service issues
- Use systemd logging and monitoring tools effectively
- Implement proper error handling and signal management

## Prerequisites

- Linux system with systemd (Ubuntu 18.04+, CentOS 7+, etc.)
- Root or sudo access
- Basic understanding of shell scripting
- Familiarity with command-line text editors (nano, vim, etc.)

---

## Step-by-Step Implementation

### Step 1: Create the Script Directory

**Command:**
```bash
sudo mkdir -p /opt/disk-monitor
```

**Explanation:**
- Create dedicated directory `/opt/disk-monitor` for custom service files
- `/opt` is the standard Linux directory for optional/third-party software
- `-p` flag creates parent directories if they don't exist and won't error if directory already exists
- Requires `sudo` because `/opt` is owned by root and needs elevated privileges

**Verification:**
```bash
ls -ld /opt/disk-monitor
# Expected output: drwxr-xr-x 2 root root 4096 Jul 10 14:00 /opt/disk-monitor
```

### Step 2: Create the Monitoring Script

**Command:**
```bash
sudo nano /opt/disk-monitor/disk-check.sh
```

**Script Content:**
```bash
#!/bin/bash
#
# @brief Disk usage monitoring script for systemd service
# @author Ameed Othman
# @date July 10, 2025

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

# Main monitoring loop
while true; do
    # Check disk usage for root filesystem
    USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
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
```

**Key Components Explained:**
- **Shebang (`#!/bin/bash`)**: Specifies the interpreter for the script
- **Configuration variables**: Easy-to-modify settings at the top of the script
- **log_message() function**: Standardized logging with timestamps
- **cleanup() function**: Handles graceful service shutdown
- **Signal handlers**: Responds to SIGTERM and SIGINT for proper shutdown
- **Disk usage check**: Uses `df`, `awk`, and `sed` to extract usage percentage
- **Input validation**: Checks if extracted value is numeric before processing
- **Infinite loop**: `while true` keeps the service running continuously
- **Sleep interval**: Prevents excessive CPU usage with 30-second delays

### Step 3: Set File Permissions and Ownership

**Commands:**
```bash
sudo chmod +x /opt/disk-monitor/disk-check.sh
sudo chown root:root /opt/disk-monitor/disk-check.sh
```

**Explanation:**
- `chmod +x` adds execute permissions for all users
- `chown root:root` sets proper ownership for security
- Root ownership prevents unauthorized modifications to the script
- These permissions are required for systemd to execute the script

**Verification:**
```bash
ls -la /opt/disk-monitor/disk-check.sh
# Expected output: -rwxr-xr-x 1 root root 1234 Jul 10 14:00 /opt/disk-monitor/disk-check.sh
```

### Step 4: Create Systemd Service Unit File

**Command:**
```bash
sudo nano /etc/systemd/system/disk-monitor.service
```

**Service Unit Content:**
```ini
[Unit]
Description=Disk Usage Monitor Service
Documentation=file:///opt/disk-monitor/README.md
After=multi-user.target
Wants=local-fs.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/opt/disk-monitor/disk-check.sh
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security settings
PrivateTmp=yes
NoNewPrivileges=yes
ProtectSystem=strict
ReadWritePaths=/var/log

# Resource limits
MemoryMax=50M
CPUQuota=10%

[Install]
WantedBy=multi-user.target
```

**Configuration Breakdown:**

**[Unit] Section:**
- `Description`: Human-readable service description displayed in status output
- `Documentation`: Points to additional documentation
- `After=multi-user.target`: Ensures service starts after system reaches multi-user mode
- `Wants=local-fs.target`: Soft dependency on local filesystem availability

**[Service] Section:**
- `Type=simple`: Process runs in foreground and doesn't daemonize itself
- `User=root`: Service runs with root privileges (needed for system monitoring)
- `ExecStart`: Absolute path to the executable script
- `ExecReload`: Command to reload the service (sends HUP signal)
- `Restart=always`: Automatically restart if service stops for any reason
- `RestartSec=10`: Wait 10 seconds before attempting restart
- `StandardOutput/Error=journal`: Send all output to systemd journal

**Security Settings:**
- `PrivateTmp=yes`: Creates private `/tmp` directory for the service
- `NoNewPrivileges=yes`: Prevents the service from gaining new privileges
- `ProtectSystem=strict`: Makes most of the filesystem read-only
- `ReadWritePaths=/var/log`: Allows writing only to the log directory

**Resource Limits:**
- `MemoryMax=50M`: Limits maximum memory usage to 50MB
- `CPUQuota=10%`: Limits CPU usage to 10% of one core

**[Install] Section:**
- `WantedBy=multi-user.target`: Creates dependency for auto-start when system reaches multi-user target

### Step 5: Load and Enable Service

**Commands:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable disk-monitor.service
```

**Explanation:**
- `daemon-reload`: Updates systemd's internal configuration cache to recognize new/modified unit files
- `enable`: Creates symbolic links for automatic startup at boot time
- Service gets linked to `/etc/systemd/system/multi-user.target.wants/disk-monitor.service`

**Verification:**
```bash
sudo systemctl is-enabled disk-monitor.service
# Expected output: enabled
```

### Step 6: Start and Verify Service

**Commands:**
```bash
sudo systemctl start disk-monitor.service
sudo systemctl status disk-monitor.service
```

**Expected Status Output:**
```
● disk-monitor.service - Disk Usage Monitor Service
     Loaded: loaded (/etc/systemd/system/disk-monitor.service; enabled; preset: enabled)
     Active: active (running) since Thu 2025-07-10 14:06:44 UTC; 5s ago
   Main PID: 1451 (disk-check.sh)
      Tasks: 2 (limit: 4549)
     Memory: 532.0K (peak: 1.7M)
        CPU: 17ms
     CGroup: /system.slice/disk-monitor.service
             ├─1451 /bin/bash /opt/disk-monitor/disk-check.sh
             └─1458 sleep 30

Jul 10 14:06:44 hostname systemd[1]: Started Disk Usage Monitor Service.
```

**Status Fields Explained:**
- **Loaded**: Shows service is loaded and enabled for boot
- **Active**: Current runtime state (active/inactive)
- **Main PID**: Process ID of the main service process
- **Tasks**: Number of processes/threads in the service
- **Memory**: Current and peak memory usage
- **CPU**: Total CPU time consumed
- **CGroup**: Control group hierarchy showing all processes

### Step 7: Monitor Service Logs

**Commands:**
```bash
# View systemd journal logs
sudo journalctl -u disk-monitor.service -f

# View custom log file
sudo tail -f /var/log/disk-monitor.log
```

**Sample Log Output:**
```
2025-07-10 14:06:44 - INFO: Disk monitor service started (PID: 1451)
2025-07-10 14:06:44 - INFO: Root filesystem usage is 29% - OK
2025-07-10 14:07:14 - INFO: Root filesystem usage is 29% - OK
2025-07-10 14:07:44 - INFO: Root filesystem usage is 29% - OK
```

### Step 8: Test Service Lifecycle Management

**Service Control Commands:**
```bash
# Stop the service
sudo systemctl stop disk-monitor.service

# Check status (should show inactive)
sudo systemctl status disk-monitor.service

# Restart the service
sudo systemctl restart disk-monitor.service

# Reload service configuration (if supported)
sudo systemctl reload disk-monitor.service

# Check if enabled for boot
sudo systemctl is-enabled disk-monitor.service
```

**Testing Automatic Restart:**
```bash
# Find the service PID
PID=$(systemctl show --property MainPID --value disk-monitor.service)

# Kill the process to test restart behavior
sudo kill $PID

# Check status - should show it restarted
sudo systemctl status disk-monitor.service
```

---

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: Service Keeps Restarting
**Symptoms:**
- High restart count in service status
- Service shows "activating" state repeatedly
- Restart counter incrementing

**Diagnosis:**
```bash
sudo journalctl -u disk-monitor.service --since "1 hour ago"
```

**Common Causes:**
1. **Script exits immediately**: Missing infinite loop or script completes execution
2. **Permission errors**: Script not executable or wrong ownership
3. **Missing dependencies**: Required files or directories don't exist
4. **Syntax errors**: Bash syntax errors in the script

**Solutions:**
```bash
# Test script manually
sudo /opt/disk-monitor/disk-check.sh

# Check syntax
bash -n /opt/disk-monitor/disk-check.sh

# Verify permissions
ls -la /opt/disk-monitor/disk-check.sh
```

#### Issue 2: Permission Denied Errors
**Symptoms:**
- Service fails to start with exit code 126
- "Permission denied" in logs
- Service state shows "failed"

**Diagnosis:**
```bash
sudo systemctl status disk-monitor.service
sudo journalctl -u disk-monitor.service -n 50
```

**Solution:**
```bash
# Fix execute permissions
sudo chmod +x /opt/disk-monitor/disk-check.sh

# Verify ownership
sudo chown root:root /opt/disk-monitor/disk-check.sh

# Check SELinux context (if applicable)
ls -Z /opt/disk-monitor/disk-check.sh
```

#### Issue 3: Service Not Starting at Boot
**Symptoms:**
- Service works when started manually
- Service not running after system reboot
- Shows "disabled" in status

**Diagnosis:**
```bash
sudo systemctl is-enabled disk-monitor.service
sudo systemctl list-unit-files | grep disk-monitor
```

**Solution:**
```bash
# Enable the service
sudo systemctl enable disk-monitor.service

# Verify symbolic link creation
ls -la /etc/systemd/system/multi-user.target.wants/ | grep disk-monitor
```

#### Issue 4: Log File Issues
**Symptoms:**
- No entries in custom log file
- Permission denied when writing logs
- Logs only appearing in systemd journal

**Diagnosis:**
```bash
# Check log file permissions
ls -la /var/log/disk-monitor.log

# Test manual log writing
sudo -u root echo "test" >> /var/log/disk-monitor.log
```

**Solution:**
```bash
# Create log file with proper permissions
sudo touch /var/log/disk-monitor.log
sudo chmod 644 /var/log/disk-monitor.log
sudo chown root:root /var/log/disk-monitor.log
```

### Debugging Commands Reference

```bash
# Service status and basic info
sudo systemctl status disk-monitor.service

# View recent logs
sudo journalctl -u disk-monitor.service -n 50

# Follow logs in real-time
sudo journalctl -u disk-monitor.service -f

# Show all logs since last boot
sudo journalctl -u disk-monitor.service -b

# Check service configuration
systemctl cat disk-monitor.service

# Verify unit file syntax
systemd-analyze verify /etc/systemd/system/disk-monitor.service

# List service dependencies
systemctl list-dependencies disk-monitor.service

# Check failed services
systemctl --failed

# Show service properties
systemctl show disk-monitor.service
```

---

## Advanced Configuration

### Signal Handling Enhancement

Add more sophisticated signal handling to the script:

```bash
# Enhanced signal handling
cleanup() {
    log_message "INFO: Received termination signal, shutting down gracefully"
    log_message "INFO: Disk monitor service stopped"
    exit 0
}

reload_config() {
    log_message "INFO: Received reload signal, reloading configuration"
    # Add configuration reload logic here
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT
trap reload_config SIGHUP
```

### Service Dependencies

Add more specific dependencies to the unit file:

```ini
[Unit]
Description=Disk Usage Monitor Service
After=multi-user.target local-fs.target
Requires=local-fs.target
Wants=network.target

[Service]
# ... existing configuration ...
```

### Resource Monitoring Enhancement

Extend the script to monitor multiple metrics:

```bash
# Enhanced monitoring function
check_system_resources() {
    # Disk usage
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    # Memory usage
    MEMORY_USAGE=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2*100}')
    
    # Load average
    LOAD_AVERAGE=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
    
    # Log all metrics
    log_message "INFO: Disk: ${DISK_USAGE}%, Memory: ${MEMORY_USAGE}%, Load: ${LOAD_AVERAGE}"
    
    # Check thresholds
    if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
        log_message "WARNING: High disk usage: ${DISK_USAGE}%"
    fi
}
```

---

## Best Practices Demonstrated

### 1. Security
- **Principle of Least Privilege**: Service runs with minimal required permissions
- **File Ownership**: Proper root ownership prevents unauthorized modifications
- **Systemd Security Features**: Uses PrivateTmp, NoNewPrivileges, ProtectSystem
- **Input Validation**: Validates disk usage data before processing

### 2. Reliability
- **Automatic Restart**: Service restarts automatically on failure
- **Graceful Shutdown**: Proper signal handling for clean termination
- **Error Handling**: Validates input and handles edge cases
- **Resource Limits**: Prevents resource exhaustion with memory and CPU limits

### 3. Maintainability
- **Configuration Variables**: Easy-to-modify settings at script top
- **Comprehensive Logging**: Detailed logs with timestamps and severity levels
- **Clear Documentation**: Well-commented code and comprehensive documentation
- **Modular Design**: Separate functions for different responsibilities

### 4. Monitoring and Observability
- **Dual Logging**: Both systemd journal and custom log file
- **Structured Logs**: Consistent format with timestamps and severity
- **Service Metrics**: Resource usage visible in systemctl status
- **Health Indicators**: Regular status updates in logs

---

## Learning Outcomes

This project successfully demonstrates:

### Technical Skills
- **Systemd Service Creation**: Complete workflow from script to service
- **Service Configuration**: Understanding unit file structure and options
- **Process Management**: Service lifecycle, dependencies, and restart policies
- **System Administration**: File permissions, ownership, and security

### DevOps Practices
- **Infrastructure as Code**: Documented, reproducible service creation
- **Monitoring**: Automated system monitoring with alerting
- **Logging**: Structured logging for observability
- **Documentation**: Comprehensive guides for maintenance and troubleshooting

### Problem-Solving Skills
- **Debugging**: Systematic approach to troubleshooting service issues
- **Testing**: Validation of service behavior under different conditions
- **Iteration**: Improving the solution based on testing and feedback

---

## Conclusion

This exercise provides a comprehensive introduction to systemd service creation and management. The disk monitoring service serves as a practical example that can be extended for more complex monitoring scenarios.

The implementation demonstrates industry best practices for:
- Service development and deployment
- System monitoring and alerting
- Documentation and knowledge sharing
- Troubleshooting and maintenance

This foundation can be applied to more complex services and enterprise monitoring solutions.
