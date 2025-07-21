# CentOS Daily Email Automation System

A professional-grade email automation system for CentOS servers that sends daily system reports via Gmail SMTP. This project demonstrates advanced Linux system administration concepts including systemd service management, SELinux configuration, secure email authentication, and enterprise automation practices.

## Project Overview

This automation system sends a daily email report containing server status information including:
- Hostname and current date/time
- System uptime
- Disk usage for root filesystem
- Memory usage statistics
- Custom formatted system report

## Architecture Components

### 1. Main Script (`scripts/daily_email.sh`)
- **Location on system**: `/usr/local/sbin/daily_email.sh`
- **Purpose**: Core automation script that gathers system information and sends email
- **Features**:
  - Time window validation (only executes 13:00-13:05)
  - Comprehensive error handling and logging
  - System information gathering using standard Linux commands
  - Integration with msmtp for secure email delivery

### 2. Systemd Service (`systemd/daily_email.service`)
- **Location on system**: `/etc/systemd/system/daily_email.service`
- **Purpose**: Defines how systemd should execute the email script
- **Security features**:
  - Runs with minimal privileges
  - Filesystem protection with `ProtectSystem=strict`
  - Private temporary directory isolation
  - Restricted write access to `/var/log` only

### 3. Systemd Timer (`systemd/daily_email.timer`)
- **Location on system**: `/etc/systemd/system/daily_email.timer`
- **Purpose**: Schedules daily execution at 1:00 PM with intelligent features
- **Advanced scheduling**:
  - Persistent execution (catches up after system downtime)
  - Randomized delay (0-5 minutes) for load distribution
  - Accuracy tolerance for power efficiency

### 4. Email Configuration (`config/`)
- **System-wide config**: `/etc/msmtprc` (for system services)
- **User config**: `~/.msmtprc` (for manual testing)
- **Purpose**: Secure Gmail SMTP authentication using App Passwords
- **Security**: Proper file permissions (600) and root ownership

## Prerequisites

### System Requirements
- CentOS Stream 10 (or compatible RHEL-based distribution)
- Internet connectivity for email delivery
- sudo/root access for system configuration

### Required Packages
```bash
# Enable EPEL repository
sudo dnf install epel-release -y

# Install required packages
sudo dnf install msmtp mailx -y
```

### Gmail Configuration
1. Enable 2-Factor Authentication on your Gmail account
2. Generate an App Password for mail applications
3. Use the App Password (not your regular Gmail password) in configuration

## Installation Instructions

### 1. Copy Files to System Locations
```bash
# Copy and set permissions for main script
sudo cp scripts/daily_email.sh /usr/local/sbin/
sudo chown root:root /usr/local/sbin/daily_email.sh
sudo chmod 755 /usr/local/sbin/daily_email.sh

# Install systemd units
sudo cp systemd/daily_email.service /etc/systemd/system/
sudo cp systemd/daily_email.timer /etc/systemd/system/
sudo chown root:root /etc/systemd/system/daily_email.*
sudo chmod 644 /etc/systemd/system/daily_email.*
```

### 2. Configure Email Authentication
```bash
# Create system-wide msmtp configuration
sudo cp config/msmtprc.template /etc/msmtprc
sudo chown root:root /etc/msmtprc
sudo chmod 600 /etc/msmtprc

# Edit the configuration and add your Gmail App Password
sudo nano /etc/msmtprc
# Replace YOUR_GMAIL_APP_PASSWORD_HERE with your actual App Password
# Update email addresses as needed
```

### 3. Configure SELinux (if enabled)
```bash
# Set correct SELinux context for the script
sudo restorecon -v /usr/local/sbin/daily_email.sh

# Verify context is correct
ls -Z /usr/local/sbin/daily_email.sh
# Should show: unconfined_u:object_r:bin_t:s0
```

### 4. Enable and Start the Automation
```bash
# Reload systemd to recognize new units
sudo systemctl daemon-reload

# Enable the timer for automatic startup
sudo systemctl enable daily_email.timer

# Start the timer
sudo systemctl start daily_email.timer

# Verify the timer is properly scheduled
systemctl list-timers daily_email.timer
```

## Testing and Verification

### Test Email Configuration
```bash
# Test msmtp configuration
echo "Test message" | msmtp -v your-email@domain.com
```

### Test Script Logic
```bash
# Test outside time window (should fail gracefully)
sudo /usr/local/sbin/daily_email.sh
echo "Exit code: $?"

# Check logs
sudo tail /var/log/daily_email.log
```

### Monitor Service Status
```bash
# Check timer status
systemctl status daily_email.timer

# Check service execution history
sudo journalctl -u daily_email.service

# View scheduled executions
systemctl list-timers
```

## File Locations Summary

| Component | Development Location | System Location | Purpose |
|-----------|---------------------|-----------------|---------|
| Main Script | `scripts/daily_email.sh` | `/usr/local/sbin/daily_email.sh` | Core automation logic |
| Service Unit | `systemd/daily_email.service` | `/etc/systemd/system/daily_email.service` | Systemd service definition |
| Timer Unit | `systemd/daily_email.timer` | `/etc/systemd/system/daily_email.timer` | Scheduling configuration |
| System Config | `config/msmtprc.template` | `/etc/msmtprc` | System-wide email config |
| User Config | `config/msmtprc-user.template` | `~/.msmtprc` | User-specific email config |
| Log File | N/A | `/var/log/daily_email.log` | Custom application logs |

## Security Considerations

- **Email Authentication**: Uses Gmail App Passwords instead of regular passwords
- **File Permissions**: Sensitive configuration files have restrictive permissions (600)
- **SELinux Integration**: Proper security contexts for system executables
- **Systemd Security**: Service runs with minimal privileges and filesystem protection
- **Time Validation**: Script only executes during designated time window (13:00-13:05)

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**: Check SELinux contexts with `ls -Z`
2. **Email Authentication Failures**: Verify App Password is correct and 2FA is enabled
3. **Timer Not Triggering**: Check timer status with `systemctl list-timers`
4. **Script Logic Errors**: Review logs in `/var/log/daily_email.log`

### Useful Commands
```bash
# Check overall system status
systemctl status daily_email.timer daily_email.service

# View detailed logs
sudo journalctl -u daily_email.service --since today

# Manual script execution for testing
sudo /usr/local/sbin/daily_email.sh

# Reset timer if needed
sudo systemctl restart daily_email.timer
```

## Technical Learning Outcomes

This project demonstrates proficiency in:
- **Systemd Management**: Service and timer unit creation and management
- **Security Configuration**: SELinux, file permissions, and privilege restriction
- **Email Integration**: SMTP authentication and secure email delivery
- **Bash Scripting**: Error handling, logging, and system information gathering
- **Linux Administration**: Package management, system integration, and automation
- **Professional Practices**: Documentation, version control, and change management

## Author

**Ameed Othman** - System Administration Learning Project - July 2025

## License

This project is provided for educational purposes. Adapt and modify as needed for your environment.
