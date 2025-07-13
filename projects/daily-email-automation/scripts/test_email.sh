#!/bin/bash
#
# Daily Email Test Script
# Manually test the email configuration and sending functionality
#
# Author: Othman (DevOps Intern at QuizPlus)
# Usage: sudo ./test_email.sh [recipient_email]
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DEFAULT_TO_EMAIL="hamza@quizplus.com"
TO_EMAIL="${1:-$DEFAULT_TO_EMAIL}"
FROM_EMAIL="othman.ameed@gmail.com"
TEST_SUBJECT="🧪 Email Test from Othman - $(date '+%B %d, %Y at %I:%M %p')"

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script should be run as root (use sudo)"
        exit 1
    fi
}

# Test msmtp configuration
test_msmtp_config() {
    print_status "Testing msmtp configuration..."
    
    # Check if msmtp is installed
    if ! command -v msmtp &> /dev/null; then
        print_error "msmtp is not installed. Run setup.sh first."
        return 1
    fi
    
    # Check if configuration file exists
    if [ ! -f "/root/.msmtprc" ]; then
        print_error "msmtp configuration not found at /root/.msmtprc"
        print_warning "Copy template: cp /root/.msmtprc.template /root/.msmtprc"
        print_warning "Then edit with your Gmail credentials"
        return 1
    fi
    
    # Check file permissions
    local perms=$(stat -c "%a" "/root/.msmtprc")
    if [ "$perms" != "600" ]; then
        print_warning "Configuration file permissions are $perms, should be 600"
        chmod 600 /root/.msmtprc
        print_status "Fixed permissions to 600"
    fi
    
    # Test msmtp configuration
    if echo "test" | msmtp --serverinfo 2>/dev/null; then
        print_success "msmtp configuration appears valid"
        return 0
    else
        print_error "msmtp configuration test failed"
        return 1
    fi
}

# Create test email content
create_test_email() {
    local current_date=$(date '+%A, %B %d, %Y at %I:%M %p')
    local hostname=$(hostname)
    
    cat << EOF
Hi Hamza,

🧪 This is a TEST email from the daily email automation system.

📧 Test Details:
- Date & Time: $current_date
- Server: $hostname
- Script: Email Test Script
- Status: Configuration Testing

🔧 System Check:
- ✅ msmtp installed and configured
- ✅ Gmail SMTP connection active
- ✅ Email formatting working
- ✅ systemd integration ready

If you receive this email, the automation system is working correctly!

📋 Next Steps:
1. ✅ Email delivery confirmed
2. Enable daily timer: sudo systemctl enable daily-email.timer
3. Start daily timer: sudo systemctl start daily-email.timer
4. Monitor logs: sudo journalctl -u daily-email.service

Best regards,
Othman's Test Email System 🧪

---
DevOps Internship Project at QuizPlus
This was sent using the email automation test script.
EOF
}

# Send test email
send_test_email() {
    print_status "Sending test email to $TO_EMAIL..."
    
    local email_content=$(create_test_email)
    
    if echo "$email_content" | msmtp "$TO_EMAIL"; then
        print_success "Test email sent successfully to $TO_EMAIL"
        echo ""
        echo "📧 Email Details:"
        echo "   From: $FROM_EMAIL"
        echo "   To: $TO_EMAIL"
        echo "   Subject: $TEST_SUBJECT"
        echo "   Time: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        print_success "Check your inbox for the test email!"
        return 0
    else
        print_error "Failed to send test email"
        echo ""
        echo "🔍 Troubleshooting steps:"
        echo "1. Verify Gmail app password in /root/.msmtprc"
        echo "2. Check internet connectivity"
        echo "3. Verify Gmail account has 2FA enabled"
        echo "4. Check msmtp logs: tail /root/.msmtp.log"
        return 1
    fi
}

# Test systemd integration
test_systemd_integration() {
    print_status "Testing systemd integration..."
    
    # Check if service file exists
    if [ ! -f "/etc/systemd/system/daily-email.service" ]; then
        print_error "systemd service file not found"
        return 1
    fi
    
    # Check if timer file exists
    if [ ! -f "/etc/systemd/system/daily-email.timer" ]; then
        print_error "systemd timer file not found"
        return 1
    fi
    
    # Test service syntax
    if systemctl cat daily-email.service &>/dev/null; then
        print_success "systemd service file is valid"
    else
        print_error "systemd service file has syntax errors"
        return 1
    fi
    
    # Test timer syntax
    if systemctl cat daily-email.timer &>/dev/null; then
        print_success "systemd timer file is valid"
    else
        print_error "systemd timer file has syntax errors"
        return 1
    fi
    
    return 0
}

# Main function
main() {
    echo "============================================"
    echo "Daily Email Automation Test"
    echo "============================================"
    echo ""
    
    check_root
    
    print_status "Testing email automation configuration..."
    echo ""
    
    # Test configuration
    if ! test_msmtp_config; then
        print_error "msmtp configuration test failed"
        exit 1
    fi
    
    echo ""
    
    # Test systemd integration
    if ! test_systemd_integration; then
        print_error "systemd integration test failed"
        exit 1
    fi
    
    echo ""
    
    # Send test email
    if send_test_email; then
        echo ""
        echo "============================================"
        echo "🎉 All Tests Passed!"
        echo "============================================"
        echo ""
        print_success "Email automation system is ready!"
        echo ""
        echo "🚀 Ready to enable daily emails:"
        echo "   sudo systemctl enable daily-email.timer"
        echo "   sudo systemctl start daily-email.timer"
        echo ""
        echo "📊 Monitor the system:"
        echo "   sudo systemctl status daily-email.timer"
        echo "   sudo journalctl -u daily-email.service"
        echo ""
    else
        echo ""
        echo "============================================"
        echo "❌ Test Failed"
        echo "============================================"
        echo ""
        print_error "Email test failed. Please check configuration."
        exit 1
    fi
}

# Show usage if help requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Usage: $0 [recipient_email]"
    echo ""
    echo "Test the daily email automation system."
    echo ""
    echo "Parameters:"
    echo "  recipient_email    Email address to send test to (default: $DEFAULT_TO_EMAIL)"
    echo ""
    echo "Examples:"
    echo "  $0                           # Send test to default recipient"
    echo "  $0 test@example.com         # Send test to specific email"
    echo ""
    exit 0
fi

# Run main function
main "$@"
