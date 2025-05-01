#!/bin/bash

# Script to install and activate check_qmi_reconnect_and_restart service/timer from GitHub
# Author: Henrik Larsson
# Usage: sudo ./setup_check_qmi_reconnect_and_restart.sh

# --- Variables ---
GITHUB_REPO="https://raw.githubusercontent.com/henla464/ROC-Teltonika/main"
SERVICE_FILE="check_qmi_reconnect_and_restart.service"
TIMER_FILE="check_qmi_reconnect_and_restart.timer"
SCRIPT_FILE="check_qmi_reconnect_and_restart.sh"
SYSTEMD_DIR="/etc/systemd/system"

# --- Check if running as root ---
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)." >&2
    exit 1
fi



# --- Download files from GitHub ---
echo "Downloading files from GitHub..."
curl -o "${SYSTEMD_DIR}/${SERVICE_FILE}" "${GITHUB_REPO}/${SERVICE_FILE}"
curl -o "${SYSTEMD_DIR}/${TIMER_FILE}" "${GITHUB_REPO}/${TIMER_FILE}"
curl -o "/home/pi/${SCRIPT_FILE}" "${GITHUB_REPO}/${SCRIPT_FILE}"

chmod +x "/home/pi/${SCRIPT_FILE}"

# --- Set correct permissions ---
chmod 644 "${SYSTEMD_DIR}/${SERVICE_FILE}" "${SYSTEMD_DIR}/${TIMER_FILE}"

# --- Reload systemd to recognize new units ---
echo "Reloading systemd..."
systemctl daemon-reload

# --- Enable and start the timer ---
echo "Enabling and starting timer..."
systemctl enable --now "${SERVICE_FILE}"

# --- Verify status ---
echo "Checking timer status..."
systemctl status "${TIMER_FILE}"

echo "Setup complete! The qmi_reconnect service will be stopped and started automatically if it seem to have gotten stuck."
