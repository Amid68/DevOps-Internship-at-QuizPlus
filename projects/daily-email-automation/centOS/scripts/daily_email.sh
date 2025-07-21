#!/bin/bash
#
# @brief Daily Email Automation Script for CentOS Server
# This script gathers system information and sends a daily email
#
# @author Ameed Othman
# @date 19.07.2025

# Set strict error handling - script will exit if any command fails
set -euo pipefail

# Define email addresses as variables
FROM_EMAIL="othman.ameed@gmail.com"
TO_EMAIL="hamza@quizplus.com"
LOG_FILE="/var/log/daily_email.log"

# Function to log messages with timestamps
log_message() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE"
}

# Function to validate time window (13:00-13:05)
validate_time_window() {
	current_hour=$(date '+%H')
	current_minute=$(date '+%M')

	if [[ "$current_hour" -eq 13 && "$current_minute" -le 5 ]]; then
		return 0	# valid time window
	else
		log_message "Script executed outside valid time window (13:00-13:05). Current time: $(date '+%H:%M')"
		log_message "Script exitting without sending email"
		exit 1
	fi
}

# Function to gather system information
gather_system_info() {
	local hostname=$(hostname)
	local uptime_info=$(uptime | sed 's/.*up //' | sed 's/, load.*//')
	local disk_usage=$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5" used)"}')
	local memory_usage=$(free -h | awk 'NR==2{printf "%s used of %s", $3, $2}')
	local current_date=$(date '+%A, %B %d, %Y at %H:%M:%S %Z')

	# Create email content with proper formatting
	cat << EOF
Subject: Daily System Report from $hostname - $(date '+%Y-%m-%d')

Hello,

This is your automated daily system report from $hostname.

Current Date & Time: $current_date

System Information:
- Hostname: $hostname
- Uptime: $uptime_info
- Disk Usage (root): $disk_usage
- Memory Usage: $memory_usage

Best regards,
Ameed's CentOS Server
EOF
}

# Main execution function
main() {
	log_message "Daily email script started"

	# Validate that script is running in the correct time window
	validate_time_window

	# Gather system information and send email
	if gather_system_info | msmtp "$TO_EMAIL"; then
		log_message "Daily email sent successfully to $TO_EMAIL"
	else
		log_message "ERROR: Failed to send daily email"
		exit 1
	fi

	log_message "Daily email script completed successfully"
}

# Execute main function
main "$@"
