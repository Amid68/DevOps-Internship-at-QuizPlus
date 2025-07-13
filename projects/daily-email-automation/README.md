# Daily Email Automation

## Overview
An automated daily email system for Ubuntu Server that sends scheduled emails via Gmail SMTP. This project demonstrates system administration skills, email automation, and systemd service management.

## Features
- **Automated Daily Emails**: Sends emails at a specified time (1:00 PM by default)
- **System Information Reporting**: Includes server status, uptime, and resource usage
- **Gmail SMTP Integration**: Secure email sending via Gmail with app passwords
- **systemd Integration**: Native Linux service and timer management
- **Comprehensive Logging**: Tracks email sending success/failure
- **Security Best Practices**: Uses app passwords and secure file permissions

## Quick Start

### Prerequisites
- Ubuntu Server with internet connectivity
- Gmail account with 2-Factor Authentication enabled
- Gmail App Password generated

### Installation
```bash
# 1. Clone repository and navigate to project
cd projects/daily-email-automation

# 2. Run automated setup
sudo ./scripts/setup.sh

# 3. Configure Gmail credentials
sudo nano /root/.msmtprc
# Add your Gmail app password

# 4. Test the setup
sudo ./scripts/test_email.sh

# 5. Enable the daily timer
sudo systemctl enable daily-email.timer
sudo systemctl start daily-email.timer
```

## Project Components

### Configuration Files
- **`.msmtprc.template`**: Template for SMTP configuration
- **`daily-email.service`**: systemd service definition
- **`daily-email.timer`**: systemd timer for daily scheduling

### Scripts
- **`send_daily_email.sh`**: Main email sending script with system info
- **`setup.sh`**: Automated installation and configuration
- **`test_email.sh`**: Manual email testing utility

### Documentation
- **`setup-guide.md`**: Detailed setup instructions
- **`troubleshooting.md`**: Common issues and solutions
- **`security-notes.md`**: Security considerations and best practices

## Email Content
Each daily email includes:
- Personal greeting message
- Current date and time
- Server hostname and uptime
- Disk and memory usage statistics
- System load averages

## Management Commands

### Check Service Status
```bash
sudo systemctl status daily-email.timer
sudo systemctl list-timers daily-email.timer
```

### View Logs
```bash
sudo journalctl -u daily-email.service
tail -f /var/log/daily-email.log
```

### Manual Testing
```bash
sudo systemctl start daily-email.service
```

## Configuration

### Email Settings
- **From**: othman.ameed@gmail.com
- **To**: hamza@quizplus.com (configurable)
- **Schedule**: Daily at 1:00 PM (configurable)
- **SMTP**: Gmail with TLS encryption

### Customization
- Modify email content in `scripts/send_daily_email.sh`
- Change schedule in `config/daily-email.timer`
- Update recipients and sender in configuration files

## Security Features
- Gmail App Password authentication (no account password exposure)
- Restricted file permissions (600) on configuration files
- TLS encryption for SMTP communication
- Separate configuration for root user

## Learning Outcomes
This project demonstrates:
- **System Administration**: Ubuntu server management and configuration
- **Email Automation**: SMTP configuration and email scripting
- **systemd Services**: Creating and managing system services and timers
- **Shell Scripting**: Bash scripting for automation tasks
- **Security Practices**: Secure credential management and file permissions
- **Logging and Monitoring**: Service logging and status monitoring

## Future Enhancements
- [ ] Multiple recipient support
- [ ] Email template system
- [ ] Configuration file validation
- [ ] Error notification system
- [ ] Metrics and monitoring integration
- [ ] Web dashboard for email history

## Troubleshooting
See `docs/troubleshooting.md` for common issues and solutions.

## Contributing
This project is part of a DevOps learning journey. Feel free to suggest improvements or additional features that would enhance the learning experience.

## License
This project is for educational purposes as part of a DevOps internship at QuizPlus.
