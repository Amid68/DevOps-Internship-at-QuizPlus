#!/bin/bash
#
# Daily Email Automation Setup Script
# Automates the installation and configuration of the daily email system
#
# Author: Othman (DevOps Intern at QuizPlus)
# Usage: sudo ./setup.sh
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/opt/daily_email"
LOG_FILE="/var/log/daily-email.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Print colored output
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
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Install required packages
install_packages() {
    print_status "Installing required packages..."
    
    apt update
    apt install -y msmtp msmtp-mta mailutils
    
    print_success "Packages installed successfully"
}

# Create project directory and copy files
setup_project_files() {
    print_status "Setting up project files..."
    
    # Create project directory
    mkdir -p "$PROJECT_DIR"
    
    # Copy main script
    if [[ -f "$SCRIPT_DIR/send_daily_email.sh" ]]; then
        cp "$SCRIPT_DIR/send_daily_email.sh" "$PROJECT_DIR/"
        chmod +x "$PROJECT_DIR/send_daily_email.sh"
        print_success "Email script copied and made executable"
    else
        print_error "send_daily_email.sh not found in $SCRIPT_DIR"
        exit 1
    fi
    
    # Create log file
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    
    print_success "Project files set up successfully"
}

# Install systemd service and timer
install_systemd_files() {
    print_status "Installing systemd service and timer..."
    
    # Copy service file
    if [[ -f "$SCRIPT_DIR/../config/daily-email.service" ]]; then
        cp "$SCRIPT_DIR/../config/daily-email.service" /etc/systemd/system/
        print_success "Service file installed"
    else
        print_error "daily-email.service not found"
        exit 1
    fi
    
    # Copy timer file
    if [[ -f "$SCRIPT_DIR/../config/daily-email.timer" ]]; then
        cp "$SCRIPT_DIR/../config/daily-email.timer" /etc/systemd/system/
        print_success "Timer file installed"
    else
        print_error "daily-email.timer not found"
        exit 1
    fi
    
    # Reload systemd
    systemctl daemon-reload
    print_success "systemd configuration reloaded"
}

# Setup msmtp configuration template
setup_msmtp_config() {
    print_status "Setting up msmtp configuration..."
    
    # Copy template for user
    if [[ -f "$SCRIPT_DIR/../config/.msmtprc.template" ]]; then
        cp "$SCRIPT_DIR/../config/.msmtprc.template" /root/.msmtprc.template
        chmod 600 /root/.msmtprc.template
        
        print_warning "msmtp configuration template created at /root/.msmtprc.template"
        print_warning "You must manually edit /root/.msmtprc with your Gmail credentials:"
        echo ""
        echo "1. Copy template: cp /root/.msmtprc.template /root/.msmtprc"
        echo "2. Edit configuration: nano /root/.msmtprc"
        echo "3. Replace YOUR_EMAIL@gmail.com with your Gmail address"
        echo "4. Replace YOUR_16_CHARACTER_APP_PASSWORD with your Gmail App Password"
        echo ""
    else
        print_error "msmtp configuration template not found"
        exit 1
    fi
}

# Test configuration
test_configuration() {
    print_status "Testing system configuration..."
    
    # Check if msmtp is installed
    if command -v msmtp &> /dev/null; then
        print_success "msmtp is installed and available"
    else
        print_error "msmtp is not installed or not in PATH"
        return 1
    fi
    
    # Check if systemd files are in place
    if [[ -f "/etc/systemd/system/daily-email.service" ]]; then
        print_success "systemd service file is installed"
    else
        print_error "systemd service file is missing"
        return 1
    fi
    
    if [[ -f "/etc/systemd/system/daily-email.timer" ]]; then
        print_success "systemd timer file is installed"
    else
        print_error "systemd timer file is missing"
        return 1
    fi
    
    # Check if main script exists and is executable
    if [[ -x "$PROJECT_DIR/send_daily_email.sh" ]]; then
        print_success "Email sending script is installed and executable"
    else
        print_error "Email sending script is not installed or not executable"
        return 1
    fi
}

# Main setup function
main() {
    echo "============================================"
    echo "Daily Email Automation Setup"
    echo "============================================"
    echo ""
    
    check_root
    install_packages
    setup_project_files
    install_systemd_files
    setup_msmtp_config
    
    echo ""
    echo "============================================"
    echo "Setup Complete!"
    echo "============================================"
    echo ""
    
    print_success "Installation completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Configure Gmail credentials in /root/.msmtprc"
    echo "2. Test the configuration: sudo $SCRIPT_DIR/test_email.sh"
    echo "3. Enable the timer: sudo systemctl enable daily-email.timer"
    echo "4. Start the timer: sudo systemctl start daily-email.timer"
    echo ""
    echo "Management commands:"
    echo "- Check status: sudo systemctl status daily-email.timer"
    echo "- View logs: sudo journalctl -u daily-email.service"
    echo "- Manual test: sudo systemctl start daily-email.service"
    echo ""
    
    if test_configuration; then
        print_success "All components installed successfully!"
    else
        print_error "Some components may not be installed correctly"
        exit 1
    fi
}

# Run main function
main "$@"
