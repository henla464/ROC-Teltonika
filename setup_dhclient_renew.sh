#!/bin/bash

# Script to install and activate dhclient-renew service/timer from GitHub
# Author: Henrik Larsson
# Usage: sudo ./setup_dhclient_renew.sh

# --- Variables ---
GITHUB_REPO="https://raw.githubusercontent.com/henla464/ROC-Teltonika/main"
SERVICE_FILE="dhclient-renew.service"
TIMER_FILE="dhclient-renew.timer"
SYSTEMD_DIR="/etc/systemd/system"

# --- Check if running as root ---
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)." >&2
    exit 1
fi

# --- Download files from GitHub ---
echo "Downloading files from GitHub..."
wget -q "${GITHUB_REPO}/${SERVICE_FILE}" -O "${SYSTEMD_DIR}/${SERVICE_FILE}"
wget -q "${GITHUB_REPO}/${TIMER_FILE}" -O "${SYSTEMD_DIR}/${TIMER_FILE}"

# --- Set correct permissions ---
chmod 644 "${SYSTEMD_DIR}/${SERVICE_FILE}" "${SYSTEMD_DIR}/${TIMER_FILE}"

# --- Reload systemd to recognize new units ---
echo "Reloading systemd..."
systemctl daemon-reload

# --- Enable and start the timer ---
echo "Enabling and starting timer..."
systemctl enable --now dhclient-renew.timer

# --- Verify status ---
echo "Checking timer status..."
systemctl status dhclient-renew.timer

echo "Setup complete! The DHCP lease will renew automatically."
