# Systemd Disk Monitor Service

A custom systemd service that monitors disk usage and logs alerts when usage exceeds configurable thresholds.

## Overview

This project demonstrates creating a custom systemd service for system monitoring. The service continuously monitors the root filesystem usage and logs warnings when disk usage exceeds a specified threshold.

## Features

- **Continuous Monitoring**: Checks disk usage every 30 seconds
- **Configurable Threshold**: Default warning at 80% usage
- **Structured Logging**: Timestamped logs with severity levels
- **Automatic Restart**: Service automatically restarts on failure
- **Systemd Integration**: Full integration with systemd service management

## Project Structure

```
systemd-disk-monitor/
├── README.md                    # This file
├── scripts/
│   └── disk-check.sh           # Main monitoring script
├── systemd/
│   └── disk-monitor.service    # Systemd service unit file
└── docs/
    └── implementation-guide.md  # Detailed implementation tutorial
```

## Quick Start

### 1. Copy Files to System

```bash
# Copy script to system location
sudo cp scripts/disk-check.sh /opt/disk-monitor/
sudo chmod +x /opt/disk-monitor/disk-check.sh
sudo chown root:root /opt/disk-monitor/disk-check.sh

# Copy systemd service file
sudo cp systemd/disk-monitor.service /etc/systemd/system/
```

### 2. Enable and Start Service

```bash
# Reload systemd configuration
sudo systemctl daemon-reload

# Enable service for boot startup
sudo systemctl enable disk-monitor.service

# Start the service
sudo systemctl start disk-monitor.service
```

### 3. Monitor Service

```bash
# Check service status
sudo systemctl status disk-monitor.service

# View real-time logs
sudo journalctl -u disk-monitor.service -f

# View custom log file
sudo tail -f /var/log/disk-monitor.log
```

## Configuration

### Modifying Thresholds

Edit `/opt/disk-monitor/disk-check.sh` and modify these variables:

```bash
THRESHOLD=80          # Warning threshold percentage
CHECK_INTERVAL=30     # Check interval in seconds
LOG_FILE="/var/log/disk-monitor.log"  # Log file location
```

After modifying the script:

```bash
sudo systemctl restart disk-monitor.service
```

### Service Configuration

The systemd service is configured in `/etc/systemd/system/disk-monitor.service`. Key settings:

- **Automatic Restart**: Service restarts automatically on failure
- **Boot Startup**: Starts automatically after multi-user target
- **Logging**: Outputs to both systemd journal and custom log file

## Management Commands

```bash
# Service Lifecycle
sudo systemctl start disk-monitor.service      # Start service
sudo systemctl stop disk-monitor.service       # Stop service
sudo systemctl restart disk-monitor.service    # Restart service
sudo systemctl reload disk-monitor.service     # Reload (if supported)

# Boot Configuration
sudo systemctl enable disk-monitor.service     # Enable auto-start
sudo systemctl disable disk-monitor.service    # Disable auto-start

# Status and Logs
sudo systemctl status disk-monitor.service     # Service status
sudo journalctl -u disk-monitor.service        # View logs
sudo journalctl -u disk-monitor.service -f     # Follow logs
```

## Log Output Examples

### Normal Operation
```
2025-07-10 14:06:44 - INFO: Disk monitor service started
2025-07-10 14:06:44 - INFO: Root filesystem usage is 29% - OK
2025-07-10 14:07:14 - INFO: Root filesystem usage is 29% - OK
```

### Warning Condition
```
2025-07-10 14:15:30 - WARNING: Root filesystem usage is 85% (threshold: 80%)
2025-07-10 14:16:00 - WARNING: Root filesystem usage is 87% (threshold: 80%)
```

## Troubleshooting

### Service Won't Start
1. Check file permissions: `ls -la /opt/disk-monitor/disk-check.sh`
2. Verify script syntax: `bash -n /opt/disk-monitor/disk-check.sh`
3. Check systemd status: `sudo systemctl status disk-monitor.service`

### Service Keeps Restarting
1. Check logs: `sudo journalctl -u disk-monitor.service`
2. Verify script has infinite loop (not exiting)
3. Check for dependency issues

### No Log Output
1. Verify log file permissions: `ls -la /var/log/disk-monitor.log`
2. Check if service is actually running: `sudo systemctl is-active disk-monitor.service`
3. Monitor systemd journal: `sudo journalctl -u disk-monitor.service -f`

## Security Considerations

- Service runs as root (required for system monitoring)
- Script and service files owned by root
- Log file readable by system administrators
- No external network connections or user input

## Extending the Service

### Additional Monitoring
- Monitor multiple filesystems
- Check memory usage
- Monitor system load
- Network interface monitoring

### Alerting Integration
- Send email notifications
- Slack/Discord webhooks
- SNMP traps
- Integration with monitoring systems (Prometheus, Nagios)

### Configuration Management
- External configuration files
- Environment variable support
- Dynamic threshold adjustment
- Multiple log levels

## Learning Outcomes

This project demonstrates:
- Systemd service creation and management
- Bash scripting for system monitoring
- Linux system administration
- Service lifecycle management
- Logging and monitoring best practices

## Author

**Ameed Othman**  
DevOps Engineering Intern  
July 2025

## License

Educational use - Part of QuizPlus DevOps Internship Program
