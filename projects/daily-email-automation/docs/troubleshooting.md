# Troubleshooting Guide

## Common Issues and Solutions

### 1. Email Not Sending

#### Symptoms
- Test email fails to send
- No emails received at scheduled time
- Error messages in logs

#### Possible Causes and Solutions

**A. Gmail App Password Issues**
```bash
# Check msmtp configuration
sudo cat /root/.msmtprc

# Verify app password format (should be 16 characters)
# Common issues:
# - Using account password instead of app password
# - Extra spaces in app password
# - App password expired or revoked
```

**Solution:**
1. Generate new Gmail App Password
2. Update `/root/.msmtprc` with new password
3. Test configuration: `sudo ./scripts/test_email.sh`

**B. Network Connectivity**
```bash
# Test internet connectivity
ping -c 4 smtp.gmail.com

# Test SMTP port
telnet smtp.gmail.com 587

# Check firewall rules
sudo ufw status
```

**C. msmtp Configuration Errors**
```bash
# Test msmtp configuration
echo "test" | msmtp --serverinfo

# Check msmtp logs
tail -f /root/.msmtp.log

# Verify file permissions
ls -la /root/.msmtprc  # Should be -rw------- (600)
```

### 2. systemd Service Issues

#### Symptoms
- Timer shows as failed
- Service doesn't start
- Emails not sent at scheduled time

#### Diagnosis Commands
```bash
# Check timer status
sudo systemctl status daily-email.timer

# Check service status
sudo systemctl status daily-email.service

# View service logs
sudo journalctl -u daily-email.service -f

# List all timers
sudo systemctl list-timers

# Check timer details
sudo systemctl list-timers daily-email.timer --all
```

#### Common Solutions

**A. Service File Permissions**
```bash
# Fix service file permissions
sudo chmod 644 /etc/systemd/system/daily-email.service
sudo chmod 644 /etc/systemd/system/daily-email.timer

# Reload systemd
sudo systemctl daemon-reload
```

**B. Script Path Issues**
```bash
# Verify script exists and is executable
ls -la /opt/daily_email/send_daily_email.sh

# Fix permissions if needed
sudo chmod +x /opt/daily_email/send_daily_email.sh
```

**C. Timer Not Running**
```bash
# Enable and start timer
sudo systemctl enable daily-email.timer
sudo systemctl start daily-email.timer

# Check if timer is active
sudo systemctl is-active daily-email.timer
```

### 3. Permission Issues

#### Symptoms
- "Permission denied" errors
- Configuration files not readable
- Log files not writable

#### Solutions
```bash
# Fix msmtp configuration permissions
sudo chmod 600 /root/.msmtprc
sudo chown root:root /root/.msmtprc

# Fix script permissions
sudo chmod +x /opt/daily_email/send_daily_email.sh
sudo chown root:root /opt/daily_email/send_daily_email.sh

# Fix log file permissions
sudo touch /var/log/daily-email.log
sudo chmod 644 /var/log/daily-email.log
```

### 4. Gmail Authentication Issues

#### Symptoms
- "Authentication failed" errors
- "App password incorrect" messages
- SMTP connection refused

#### Solutions

**A. Verify 2-Factor Authentication**
1. Go to Google Account settings
2. Ensure 2-Step Verification is enabled
3. Generate new App Password if needed

**B. Check Account Security**
```bash
# Common Gmail security issues:
# - Less secure app access disabled
# - Account temporarily locked
# - Suspicious activity detected
```

**C. Test SMTP Connection**
```bash
# Test manual SMTP connection
telnet smtp.gmail.com 587

# Expected response:
# 220 smtp.gmail.com ESMTP
```

### 5. Log File Issues

#### Symptoms
- No logs appearing
- Permission denied writing to log
- Log file missing

#### Solutions
```bash
# Create log file with proper permissions
sudo touch /var/log/daily-email.log
sudo chmod 644 /var/log/daily-email.log

# Check log directory permissions
ls -la /var/log/ | grep daily-email

# Manually test logging
echo "Test log entry" | sudo tee -a /var/log/daily-email.log
```

### 6. Time Zone Issues

#### Symptoms
- Emails sent at wrong time
- Timer shows different time than expected

#### Solutions
```bash
# Check system timezone
timedatectl

# Set correct timezone (example: US/Pacific)
sudo timedatectl set-timezone America/Los_Angeles

# Verify timer schedule
sudo systemctl list-timers daily-email.timer

# Check if system time is correct
date
```

## Debugging Steps

### 1. Basic System Check
```bash
#!/bin/bash
echo "=== Daily Email System Check ==="

# Check if packages are installed
echo "1. Package Check:"
dpkg -l | grep msmtp || echo "   ❌ msmtp not installed"
dpkg -l | grep mailutils || echo "   ❌ mailutils not installed"

# Check files exist
echo "2. File Check:"
[ -f /opt/daily_email/send_daily_email.sh ] && echo "   ✅ Script exists" || echo "   ❌ Script missing"
[ -f /root/.msmtprc ] && echo "   ✅ Config exists" || echo "   ❌ Config missing"
[ -f /etc/systemd/system/daily-email.service ] && echo "   ✅ Service exists" || echo "   ❌ Service missing"
[ -f /etc/systemd/system/daily-email.timer ] && echo "   ✅ Timer exists" || echo "   ❌ Timer missing"

# Check permissions
echo "3. Permission Check:"
stat -c "%a %n" /root/.msmtprc 2>/dev/null || echo "   ❌ Config file missing"
stat -c "%a %n" /opt/daily_email/send_daily_email.sh 2>/dev/null || echo "   ❌ Script missing"

# Check systemd status
echo "4. Service Status:"
systemctl is-active daily-email.timer && echo "   ✅ Timer active" || echo "   ❌ Timer inactive"
systemctl is-enabled daily-email.timer && echo "   ✅ Timer enabled" || echo "   ❌ Timer disabled"
```

### 2. Test Email Manually
```bash
# Test msmtp configuration
echo "Test message" | msmtp hamza@quizplus.com

# Test with verbose output
echo "Test message" | msmtp -v hamza@quizplus.com

# Check msmtp version and configuration
msmtp --version
msmtp --configure
```

### 3. Monitor System Logs
```bash
# Watch systemd logs in real-time
sudo journalctl -u daily-email.service -f

# Watch custom log file
tail -f /var/log/daily-email.log

# Check system log for email-related entries
sudo journalctl | grep -i mail
```

## Emergency Recovery

### Reset Configuration
```bash
#!/bin/bash
# Emergency reset script

echo "Resetting daily email configuration..."

# Stop and disable services
sudo systemctl stop daily-email.timer
sudo systemctl disable daily-email.timer

# Remove systemd files
sudo rm -f /etc/systemd/system/daily-email.service
sudo rm -f /etc/systemd/system/daily-email.timer

# Reload systemd
sudo systemctl daemon-reload

# Remove project files
sudo rm -rf /opt/daily_email/

# Remove configuration
sudo rm -f /root/.msmtprc

echo "Configuration reset complete. Run setup.sh to reinstall."
```

### Backup Important Files
```bash
#!/bin/bash
# Backup script

BACKUP_DIR="/tmp/daily-email-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup configuration
cp /root/.msmtprc "$BACKUP_DIR/" 2>/dev/null || echo "No config to backup"

# Backup logs
cp /var/log/daily-email.log "$BACKUP_DIR/" 2>/dev/null || echo "No logs to backup"

# Backup scripts
cp -r /opt/daily_email/ "$BACKUP_DIR/" 2>/dev/null || echo "No scripts to backup"

echo "Backup created at $BACKUP_DIR"
```

## Getting Help

### Log Collection for Support
```bash
#!/bin/bash
# Collect logs for troubleshooting

echo "=== Daily Email System Logs ==="
echo "Generated: $(date)"
echo ""

echo "=== System Information ==="
hostname
uname -a
timedatectl
echo ""

echo "=== Package Information ==="
dpkg -l | grep msmtp
echo ""

echo "=== File Status ==="
ls -la /opt/daily_email/ 2>/dev/null || echo "Project directory missing"
ls -la /root/.msmtprc 2>/dev/null || echo "Config file missing"
ls -la /etc/systemd/system/daily-email.* 2>/dev/null || echo "Systemd files missing"
echo ""

echo "=== Service Status ==="
systemctl status daily-email.timer
systemctl status daily-email.service
echo ""

echo "=== Recent Logs ==="
journalctl -u daily-email.service --since "24 hours ago"
echo ""

echo "=== Custom Logs ==="
tail -n 20 /var/log/daily-email.log 2>/dev/null || echo "No custom logs"
```

### Contact Information
- Repository Issues: Create an issue in the GitHub repository
- Email: Include system logs and error messages
- Documentation: Check project README and setup guide

## Prevention

### Regular Maintenance
1. **Monthly**: Test email sending functionality
2. **Weekly**: Check system logs for errors
3. **Daily**: Monitor timer status
4. **As needed**: Update Gmail app passwords when they expire

### Monitoring Setup
```bash
# Add to crontab for weekly health checks
0 9 * * 1 /opt/daily_email/scripts/health_check.sh
```

### Best Practices
1. Keep Gmail app passwords secure and up-to-date
2. Monitor system logs regularly
3. Test configuration after system updates
4. Backup configuration files before making changes
5. Use version control for configuration management
