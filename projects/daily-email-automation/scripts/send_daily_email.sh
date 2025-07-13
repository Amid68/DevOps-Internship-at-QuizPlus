#!/bin/bash
#
# Daily Email Automation Script
# Sends automated daily emails with system information
#
# Author: Othman (DevOps Intern at QuizPlus)
# Usage: Called by systemd timer daily at 1:00 PM
#

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
TO_EMAIL="${TO_EMAIL:-hamza@quizplus.com}"
FROM_EMAIL="${FROM_EMAIL:-othman.ameed@gmail.com}"
LOG_FILE="${LOG_FILE:-/var/log/daily-email.log}"

# Email subject with current date
SUBJECT="Daily Update from Othman - $(date '+%B %d, %Y')"

# Get current date and time in readable format
CURRENT_DATE=$(date '+%A, %B %d, %Y at %I:%M %p')

# Collect system information
HOSTNAME=$(hostname)
UPTIME=$(uptime -p)
KERNEL_VERSION=$(uname -r)

# Disk usage for root partition
DISK_USAGE=$(df -h / | awk 'NR==2{printf "%s used of %s (%s)", $3, $2, $5}')

# Memory usage
MEMORY_USAGE=$(free -h | awk 'NR==2{printf "%s used of %s", $3, $2}')

# Load average
LOAD_AVERAGE=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//')

# CPU information
CPU_INFO=$(lscpu | grep "Model name" | cut -d':' -f2 | sed 's/^[ \t]*//')

# Number of active connections
ACTIVE_CONNECTIONS=$(ss -tuln | wc -l)

# Create the email body
EMAIL_BODY="Hi Hamza,

This is my daily automated email from the Ubuntu server. Hope you're having a great day!

🕐 Date & Time: $CURRENT_DATE

📊 === System Information ===
🖥️  Server: $HOSTNAME
⏰ Uptime: $UPTIME
🔧 Kernel: $KERNEL_VERSION
💾 Disk Usage: $DISK_USAGE
🧠 Memory Usage: $MEMORY_USAGE
⚡ Load Average:$LOAD_AVERAGE
🔲 CPU: $CPU_INFO
🌐 Active Connections: $ACTIVE_CONNECTIONS

📈 === Quick Status ===
✅ Email automation: Working perfectly
✅ systemd timer: Active and running
✅ SMTP connection: Secure via Gmail

This email was automatically generated and sent via:
- Ubuntu Server with systemd timer
- Gmail SMTP with TLS encryption
- msmtp for email delivery

Best regards,
Othman's Automated Ubuntu Server 🐧

---
DevOps Internship Project at QuizPlus
Repository: https://github.com/your-username/DevOps-Internship-at-QuizPlus"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
}

# Function to send email
send_email() {
    if echo "$EMAIL_BODY" | msmtp "$TO_EMAIL"; then
        log_message "SUCCESS: Daily email sent successfully to $TO_EMAIL"
        echo "Email sent successfully to $TO_EMAIL"
        return 0
    else
        log_message "ERROR: Failed to send daily email to $TO_EMAIL"
        echo "Failed to send email to $TO_EMAIL" >&2
        return 1
    fi
}

# Main execution
main() {
    log_message "INFO: Starting daily email automation script"
    
    # Check if msmtp is available
    if ! command -v msmtp &> /dev/null; then
        log_message "ERROR: msmtp command not found. Please install msmtp package."
        exit 1
    fi
    
    # Check if msmtp configuration exists
    if [ ! -f "$HOME/.msmtprc" ]; then
        log_message "ERROR: msmtp configuration file not found at $HOME/.msmtprc"
        exit 1
    fi
    
    # Verify configuration file permissions
    PERMS=$(stat -c "%a" "$HOME/.msmtprc")
    if [ "$PERMS" != "600" ]; then
        log_message "WARNING: msmtp configuration file permissions are $PERMS, should be 600"
    fi
    
    # Send the email
    if send_email; then
        log_message "INFO: Daily email automation completed successfully"
        exit 0
    else
        log_message "ERROR: Daily email automation failed"
        exit 1
    fi
}

# Run main function
main "$@"
