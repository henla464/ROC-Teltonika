#!/bin/bash

# Script to install and activate dhclient-renew service/timer from GitHub
# Author: Henrik Larsson
# Usage: sudo ./setup_dhcpcd_renew.sh

# --- Variables ---
GITHUB_REPO="https://raw.githubusercontent.com/henla464/ROC-Teltonika/main"
SERVICE_FILE="dhcpcd-renew.service"
TIMER_FILE="dhcpcd-renew.timer"
SCRIPT_FILE="network_restart.sh"
SYSTEMD_DIR="/etc/systemd/system"

# --- Check if running as root ---
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)." >&2
    exit 1
fi

# modify the dhcpcd.conf
# Define the file
file="/etc/dhcpcd.conf"

# Use sed to insert the lines 5 lines from the end
# First, calculate total lines and determine insertion point
total_lines=$(wc -l < "$file")
insert_line=$((total_lines - 7))  # 8 lines from end = total_lines - 7

# Use sed to insert at the calculated line
sed -i "${insert_line}i\\
noarp\\
noipv6" "$file"


# --- Download files from GitHub ---
echo "Downloading files from GitHub..."
wget -q "${GITHUB_REPO}/${SERVICE_FILE}" -O "${SYSTEMD_DIR}/${SERVICE_FILE}"
wget -q "${GITHUB_REPO}/${TIMER_FILE}" -O "${SYSTEMD_DIR}/${TIMER_FILE}"
wget -q "${GITHUB_REPO}/${SCRIPT_FILE}" -O "/home/pi/${SCRIPT_FILE}"

chmod +x "/home/pi/${SCRIPT_FILE}"

# --- Set correct permissions ---
chmod 644 "${SYSTEMD_DIR}/${SERVICE_FILE}" "${SYSTEMD_DIR}/${TIMER_FILE}"

# --- Reload systemd to recognize new units ---
echo "Reloading systemd..."
systemctl daemon-reload

# --- Enable and start the timer ---
echo "Enabling and starting timer..."
systemctl enable --now dhcpcd-renew.timer

# --- Verify status ---
echo "Checking timer status..."
systemctl status dhcpcd-renew.timer

echo "Setup complete! The DHCP lease will renew automatically."
