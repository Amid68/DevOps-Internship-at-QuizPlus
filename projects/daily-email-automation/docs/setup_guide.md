# Complete Setup Guide

## Overview
This guide provides step-by-step instructions for setting up the daily email automation system on Ubuntu Server. The system will send automated daily emails via Gmail SMTP at a scheduled time.

## Prerequisites

### System Requirements
- Ubuntu Server 18.04+ (tested on 20.04 LTS and 22.04 LTS)
- Internet connectivity
- Root/sudo access
- Minimum 100MB free disk space

### Gmail Account Requirements
- Gmail account with 2-Factor Authentication enabled
- App Password generated for SMTP access

## Pre-Installation Setup

### 1. Gmail Configuration

#### Enable 2-Factor Authentication
1. Go to [Google Account Security](https://myaccount.google.com/security)
2. Enable **2-Step Verification** if not already enabled
3. Follow the setup wizard to complete 2FA setup

#### Generate App Password
1. In Google Account Security, go to **2-Step Verification**
2. Scroll down to **App passwords**
3. Click **Select app** → Choose **Mail**
4. Click **Select device** → Choose **Other (custom name)**
5. Enter name: "Ubuntu Server Email Automation"
6. Click **Generate**
7. **Copy the 16-character password** (save it securely)

### 2. Server Preparation

#### Update System
```bash
sudo apt update && sudo apt upgrade -y
```

#### Check System Time
```bash
# Verify correct timezone
timedatectl

# Set timezone if needed (example for US Pacific)
sudo timedatectl set-timezone America/Los_Angeles

# Enable NTP for accurate time
sudo timedatectl set-ntp true
```

## Installation Methods

### Method 1: Automated Installation (Recommended)

#### Download Project Files
```bash
# Clone the repository (adjust URL to your actual repository)
git clone https://github.com/your-username/DevOps-Internship-at-QuizPlus.git
cd DevOps-Internship-at-QuizPlus/projects/daily-email-automation

# Make scripts executable
chmod +x scripts/*.sh
```

#### Run Automated Setup
```bash
sudo ./scripts/setup.sh
```

The setup script will:
- Install required packages (msmtp, mailutils)
- Create project directory structure
- Copy configuration templates
- Install systemd service and timer files
- Set proper file permissions

#### Configure Gmail Credentials
```bash
# Copy the configuration template
sudo cp /root/.msmtprc.template /root/.msmtprc

# Edit the configuration
sudo nano /root/.msmtprc
```

**Update these values in the file:**
```bash
# Replace YOUR_EMAIL@gmail.com with your Gmail address
from           your-email@gmail.com
user           your-email@gmail.com

# Replace YOUR_16_CHARACTER_APP_PASSWORD with your Gmail App Password
password       your-app-password-here
```

**Save and set permissions:**
```bash
sudo chmod 600 /root/.msmtprc
```

#### Test Configuration
```bash
sudo ./scripts/test_email.sh
```

If successful, you should see:
```
[SUCCESS] Test email sent successfully to hamza@quizplus.com
🎉 All Tests Passed!
```

#### Enable Daily Emails
```bash
sudo systemctl enable daily-email.timer
sudo systemctl start daily-email.timer
```

### Method 2: Manual Installation

#### Install Packages
```bash
sudo apt update
sudo apt install -y msmtp msmtp-mta mailutils
```

#### Create Directory Structure
```bash
sudo mkdir -p /opt/daily_email
```

#### Create msmtp Configuration
```bash
sudo nano /root/.msmtprc
```

**Add this content:**
```bash
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           your-email@gmail.com
user           your-email@gmail.com
password       your-16-character-app-password

account default : gmail
```

**Set permissions:**
```bash
sudo chmod 600 /root/.msmtprc
```

#### Create Email Script
```bash
sudo nano /opt/daily_email/send_daily_email.sh
```

**Copy the complete script content from `scripts/send_daily_email.sh`**

**Make executable:**
```bash
sudo chmod +x /opt/daily_email/send_daily_email.sh
```

#### Create systemd Service
```bash
sudo nano /etc/systemd/system/daily-email.service
```

**Copy content from `config/daily-email.service`**

#### Create systemd Timer
```bash
sudo nano /etc/systemd/system/daily-email.timer
```

**Copy content from `config/daily-email.timer`**

#### Enable Services
```bash
sudo systemctl daemon-reload
sudo systemctl enable daily-email.timer
sudo systemctl start daily-email.timer
```

## Post-Installation Configuration

### 1. Customize Email Settings

#### Modify Recipients
```bash
sudo nano /opt/daily_email/send_daily_email.sh

# Change this line:
TO_EMAIL="${TO_EMAIL:-hamza@quizplus.com}"
# To your desired recipient
```

#### Modify Schedule
```bash
sudo nano /etc/systemd/system/daily-email.timer

# Change this line for different time:
OnCalendar=*-*-* 13:00:00
# Examples:
# 09:00:00 for 9 AM
# 17:30:00 for 5:30 PM
```

**After changes, reload systemd:**
```bash
sudo systemctl daemon-reload
sudo systemctl restart daily-email.timer
```

#### Customize Email Content
Edit the email template in `/opt/daily_email/send_daily_email.sh`:
```bash
sudo nano /opt/daily_email/send_daily_email.sh

# Find the EMAIL_BODY section and customize the message
```

### 2. Verification and Testing

#### Check Timer Status
```bash
sudo systemctl status daily-email.timer
```

Expected output:
```
● daily-email.timer - Daily Email Timer for 1:00 PM
   Loaded: loaded (/etc/systemd/system/daily-email.timer; enabled)
   Active: active (waiting) since [date]
   Trigger: [next scheduled time]
```

#### List All Timers
```bash
sudo systemctl list-timers daily-email.timer
```

#### Manual Test
```bash
sudo systemctl start daily-email.service
```

#### Check Logs
```bash
# systemd logs
sudo journalctl -u daily-email.service

# Custom log file
tail -f /var/log/daily-email.log
```

## Monitoring and Maintenance

### Daily Monitoring

#### Check Service Health
```bash
# Quick status check
sudo systemctl is-active daily-email.timer

# Detailed status
sudo systemctl status daily-email.timer
```

#### Monitor Logs
```bash
# Real-time log monitoring
sudo journalctl -u daily-email.service -f

# Check recent activity
sudo journalctl -u daily-email.service --since "24 hours ago"
```

### Weekly Maintenance

#### Check Email Delivery
```bash
# Send test email
sudo ./scripts/test_email.sh

# Check last successful delivery
tail -5 /var/log/daily-email.log
```

#### Verify Configuration
```bash
# Check file permissions
ls -la /root/.msmtprc
ls -la /opt/daily_email/send_daily_email.sh

# Test msmtp configuration
echo "test" | sudo msmtp --serverinfo
```

### Monthly Maintenance

#### Update Gmail App Password
1. Generate new app password in Gmail
2. Update `/root/.msmtprc` with new password
3. Test configuration: `sudo ./scripts/test_email.sh`
4. Revoke old app password in Gmail

#### System Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade

# Check if email system still works after updates
sudo ./scripts/test_email.sh
```

## Troubleshooting

### Common Issues

#### Email Not Sending
1. **Check Gmail credentials:**
   ```bash
   sudo cat /root/.msmtprc
   # Verify email and app password are correct
   ```

2. **Test SMTP connection:**
   ```bash
   telnet smtp.gmail.com 587
   # Should connect successfully
   ```

3. **Check logs:**
   ```bash
   tail -f /var/log/daily-email.log
   sudo journalctl -u daily-email.service
   ```

#### Timer Not Working
1. **Check timer status:**
   ```bash
   sudo systemctl status daily-email.timer
   sudo systemctl list-timers daily-email.timer
   ```

2. **Reload configuration:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart daily-email.timer
   ```

#### Permission Issues
```bash
# Fix common permission problems
sudo chmod 600 /root/.msmtprc
sudo chmod +x /opt/daily_email/send_daily_email.sh
sudo chown root:root /root/.msmtprc
sudo chown root:root /opt/daily_email/send_daily_email.sh
```

For detailed troubleshooting, see `docs/troubleshooting.md`.

## Security Considerations

### File Security
- Configuration files have restrictive permissions (600)
- Scripts run as root with systemd security hardening
- App passwords used instead of account passwords
- TLS encryption for all SMTP communications

### Network Security
- All communications encrypted with TLS
- Only outbound SMTP connections (port 587)
- No listening services exposed
- Certificate verification enabled

For complete security information, see `docs/security-notes.md`.

## Backup and Recovery

### Backup Important Files
```bash
#!/bin/bash
# Create backup
BACKUP_DIR="/tmp/email-backup-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup configuration and scripts
sudo cp /root/.msmtprc "$BACKUP_DIR/"
sudo cp -r /opt/daily_email/ "$BACKUP_DIR/"
sudo cp /etc/systemd/system/daily-email.* "$BACKUP_DIR/"
sudo cp /var/log/daily-email.log "$BACKUP_DIR/"

# Create archive
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR/"
sudo chmod 600 "$BACKUP_DIR.tar.gz"

echo "Backup created: $BACKUP_DIR.tar.gz"
```

### Recovery Process
```bash
# Stop services
sudo systemctl stop daily-email.timer
sudo systemctl disable daily-email.timer

# Restore from backup
tar -xzf email-backup-[date].tar.gz
sudo cp backup/[files] [original-locations]

# Set permissions
sudo chmod 600 /root/.msmtprc
sudo chmod +x /opt/daily_email/send_daily_email.sh

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl enable daily-email.timer
sudo systemctl start daily-email.timer
```

## Uninstallation

### Complete Removal
```bash
#!/bin/bash
# Stop and disable services
sudo systemctl stop daily-email.timer
sudo systemctl disable daily-email.timer

# Remove systemd files
sudo rm /etc/systemd/system/daily-email.service
sudo rm /etc/systemd/system/daily-email.timer
sudo systemctl daemon-reload

# Remove project files
sudo rm -rf /opt/daily_email/

# Remove configuration
sudo rm /root/.msmtprc

# Remove logs
sudo rm /var/log/daily-email.log

# Optional: Remove packages if not needed elsewhere
sudo apt remove msmtp msmtp-mta

echo "Daily email automation system removed completely"
```

## Support and Documentation

### Additional Resources
- **Project README**: `README.md`
- **Troubleshooting Guide**: `docs/troubleshooting.md`
- **Security Notes**: `docs/security-notes.md`
- **Example Configurations**: `examples/`

### Getting Help
1. Check the troubleshooting guide for common issues
2. Review system logs for error messages
3. Test individual components manually
4. Create an issue in the project repository

### Contributing
This project is part of a DevOps learning journey. Suggestions for improvements are welcome through:
- GitHub issues
- Pull requests
- Documentation updates

## Conclusion

The daily email automation system provides:
- ✅ Reliable automated email delivery
- ✅ Comprehensive system monitoring
- ✅ Security best practices
- ✅ Easy maintenance and troubleshooting
- ✅ Professional systemd integration

After following this guide, you should have a fully functional daily email automation system that sends emails reliably and securely.

For ongoing maintenance, follow the monitoring procedures and refer to the troubleshooting guide as needed.
