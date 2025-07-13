# Security Considerations

## Overview
This document outlines the security measures implemented in the daily email automation system and provides guidance for maintaining security best practices.

## Authentication Security

### Gmail App Passwords
The system uses Gmail App Passwords instead of account passwords for enhanced security.

**Security Benefits:**
- ✅ Account password remains protected
- ✅ App-specific authentication tokens
- ✅ Can be revoked without changing account password
- ✅ Limited scope (only email sending)
- ✅ Independent of account 2FA status

**Best Practices:**
```bash
# Store app passwords securely
chmod 600 /root/.msmtprc
chown root:root /root/.msmtprc

# Regular rotation (recommended: every 90 days)
# 1. Generate new app password in Gmail
# 2. Update /root/.msmtprc
# 3. Test configuration
# 4. Revoke old app password
```

**Security Checklist:**
- [ ] 2-Factor Authentication enabled on Gmail account
- [ ] App password used (not account password)
- [ ] Configuration file has restrictive permissions (600)
- [ ] App password rotated regularly
- [ ] Old app passwords revoked after updates

## File System Security

### Configuration File Protection
```bash
# Secure msmtp configuration
/root/.msmtprc
# Permissions: 600 (rw-------)
# Owner: root:root
# Contains: SMTP credentials

# Check permissions
stat -c "%a %U:%G %n" /root/.msmtprc
# Expected: 600 root:root /root/.msmtprc
```

### Script Security
```bash
# Main script security
/opt/daily_email/send_daily_email.sh
# Permissions: 755 (rwxr-xr-x)
# Owner: root:root
# Function: Email sending with system info

# Security features in script:
# - set -euo pipefail (fail fast)
# - Input validation
# - Secure file handling
# - Error logging
```

### Log File Security
```bash
# Log file permissions
/var/log/daily-email.log
# Permissions: 644 (rw-r--r--)
# Owner: root:root
# Content: Email sending status (no sensitive data)
```

## Network Security

### SMTP Connection Security
```bash
# msmtp configuration security features:
# - TLS encryption (tls on)
# - Certificate verification (tls_trust_file)
# - Secure port 587 (STARTTLS)
# - No plain text authentication
```

**Connection Details:**
- **Protocol**: SMTP with STARTTLS
- **Port**: 587 (submission port with encryption)
- **Encryption**: TLS 1.2+ mandatory
- **Certificate**: Verified against system CA bundle
- **Authentication**: SASL LOGIN with app password

### Network Monitoring
```bash
# Monitor SMTP connections
sudo netstat -pan | grep :587

# Check for suspicious connections
sudo ss -tuln | grep :587

# Monitor email-related network activity
sudo tcpdump -i any port 587
```

## System Security

### systemd Service Hardening
The systemd service includes several security hardening measures:

```ini
[Service]
# Basic security
NoNewPrivileges=true
PrivateTmp=true

# File system protection
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log

# Kernel protection
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
```

**Security Features Explained:**
- **NoNewPrivileges**: Prevents privilege escalation
- **PrivateTmp**: Isolated temporary directory
- **ProtectSystem**: Read-only access to system directories
- **ProtectHome**: No access to user home directories
- **ReadWritePaths**: Only specific paths are writable

### Process Isolation
```bash
# Service runs as root (required for system info gathering)
# But with restricted capabilities through systemd hardening

# Check service security status
systemd-analyze security daily-email.service
```

## Information Security

### Data Handling
**Sensitive Information:**
- Gmail app password (encrypted in transit, secured at rest)
- System information (minimal exposure, logged locally)
- Email addresses (configuration only, not logged)

**Data Flow:**
1. **Configuration**: App password stored in protected file
2. **Processing**: System info collected locally
3. **Transmission**: Encrypted SMTP connection to Gmail
4. **Logging**: Status only (no sensitive data in logs)

### Email Content Security
```bash
# Email content includes:
# ✅ Safe: System uptime, hostname, resource usage
# ✅ Safe: Date/time information
# ❌ Excluded: User data, process details, network configuration
# ❌ Excluded: Security logs, authentication information
```

### Information Leakage Prevention
```bash
# Prevent information disclosure
# - No sensitive data in email content
# - No user information exposed
# - No internal network details
# - No security configuration details
```

## Access Control

### File Permissions Matrix
| File | Owner | Permissions | Purpose |
|------|-------|-------------|---------|
| `/root/.msmtprc` | root:root | 600 | SMTP credentials |
| `/opt/daily_email/send_daily_email.sh` | root:root | 755 | Main script |
| `/etc/systemd/system/daily-email.*` | root:root | 644 | Service definitions |
| `/var/log/daily-email.log` | root:root | 644 | Status logging |

### User Access Control
```bash
# System access requirements:
# - Root access required for:
#   - Reading system information
#   - Writing to system log files
#   - systemd service management
#   - SMTP configuration access

# Regular users cannot:
# - Read SMTP configuration
# - Modify service configuration
# - Access system service logs
# - Interfere with scheduled email sending
```

## Audit and Monitoring

### Security Logging
```bash
# Email system logs
tail -f /var/log/daily-email.log

# systemd service logs
journalctl -u daily-email.service

# Security-relevant events logged:
# - Email sending success/failure
# - Configuration file access
# - Service start/stop events
# - Authentication failures
```

### Security Monitoring
```bash
# Monitor configuration file access
sudo auditctl -w /root/.msmtprc -p rwxa -k email-config

# Monitor script execution
sudo auditctl -w /opt/daily_email/send_daily_email.sh -p x -k email-script

# Check audit logs
sudo ausearch -k email-config
sudo ausearch -k email-script
```

### Regular Security Checks
```bash
#!/bin/bash
# security-check.sh - Regular security audit script

echo "=== Security Check for Daily Email System ==="

# Check file permissions
echo "1. File Permissions:"
find /opt/daily_email -type f -exec ls -la {} \;
ls -la /root/.msmtprc
ls -la /etc/systemd/system/daily-email.*

# Check for unusual access
echo "2. Recent Access (last 24 hours):"
find /opt/daily_email /root/.msmtprc -type f -newermt "1 day ago" -exec ls -la {} \;

# Check service status
echo "3. Service Security Status:"
systemd-analyze security daily-email.service

# Check network connections
echo "4. Network Connections:"
sudo netstat -pan | grep msmtp || echo "No active connections"
```

## Incident Response

### Security Incident Procedures

**If Gmail Credentials Compromised:**
1. **Immediate Actions:**
   ```bash
   # Stop the service immediately
   sudo systemctl stop daily-email.timer
   sudo systemctl disable daily-email.timer
   
   # Remove configuration file
   sudo rm /root/.msmtprc
   ```

2. **Recovery Steps:**
   - Change Gmail account password
   - Revoke all app passwords
   - Generate new app password
   - Update configuration with new credentials
   - Re-enable service after verification

**If System Compromised:**
1. **Assessment:**
   ```bash
   # Check for unauthorized changes
   sudo find /opt/daily_email -type f -mtime -1
   sudo journalctl -u daily-email.service --since "24 hours ago"
   ```

2. **Containment:**
   ```bash
   # Disable all email services
   sudo systemctl stop daily-email.timer
   sudo systemctl mask daily-email.timer
   ```

3. **Recovery:**
   - Rebuild system from clean state
   - Restore from known-good backups
   - Regenerate all credentials
   - Implement additional monitoring

## Security Best Practices

### Configuration Management
```bash
# Use configuration templates
cp /root/.msmtprc.template /root/.msmtprc

# Validate configuration before deployment
msmtp --serverinfo

# Backup configurations securely
tar -czf email-config-backup.tar.gz /root/.msmtprc /opt/daily_email/
chmod 600 email-config-backup.tar.gz
```

### Regular Maintenance
**Weekly:**
- Review service logs for anomalies
- Check file permissions
- Verify service status

**Monthly:**
- Test email functionality
- Review security logs
- Update documentation

**Quarterly:**
- Rotate Gmail app passwords
- Security configuration review
- Incident response plan testing

### Defense in Depth
This system implements multiple security layers:

1. **Authentication**: App passwords + 2FA
2. **Encryption**: TLS for all SMTP communications
3. **Access Control**: Restrictive file permissions
4. **Process Isolation**: systemd security features
5. **Monitoring**: Comprehensive logging
6. **Regular Audits**: Automated security checks

## Compliance Considerations

### Data Protection
- No personal data collected or transmitted
- System information only (non-sensitive)
- Minimal data retention
- Secure credential storage

### Audit Requirements
- All email sending events logged
- Configuration changes tracked
- Service access monitored
- Regular security reviews documented

## Security Tools Integration

### Optional Enhanced Security
```bash
# AppArmor profile for additional restriction
sudo apt install apparmor-utils
sudo aa-genprof /opt/daily_email/send_daily_email.sh

# Fail2ban for authentication protection
sudo apt install fail2ban
# Configure for SMTP authentication failures

# Logwatch for log monitoring
sudo apt install logwatch
# Configure to monitor email system logs
```

### Security Scanning
```bash
# Regular security scans
sudo chkrootkit
sudo rkhunter --check

# Configuration validation
sudo lynis audit system

# Network security scan
sudo nmap -sS localhost
```

## Conclusion

The daily email automation system implements comprehensive security measures including:

- ✅ Secure authentication with Gmail app passwords
- ✅ Encrypted SMTP communications
- ✅ Restrictive file permissions and access controls
- ✅ systemd security hardening
- ✅ Comprehensive logging and monitoring
- ✅ Regular security maintenance procedures

These measures provide defense-in-depth protection while maintaining the functionality required for automated email delivery.

For additional security questions or concerns, refer to the troubleshooting guide or contact the system administrator.
