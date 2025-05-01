#!/bin/bash

# Configuration
LOG_DIR="/var/log/qmi_reconnect"
LOG_FILE="$LOG_DIR/check_qmi_reconnect.log"
MAX_LOG_FILES=2
MAX_LOG_SIZE="1M"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log messages with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to rotate logs
rotate_logs() {
    # Check if log file exists and needs rotation
    if [ -f "$LOG_FILE" ] && [ "$(stat -c %s "$LOG_FILE")" -gt $(( $(echo "$MAX_LOG_SIZE" | numfmt --from=iec) )) ]; then
        for ((i=MAX_LOG_FILES-1; i>=1; i--)); do
            [ -f "${LOG_FILE}.${i}" ] && mv "${LOG_FILE}.${i}" "${LOG_FILE}.$((i+1))"
        done
        mv "$LOG_FILE" "${LOG_FILE}.1"
    fi
}

# Rotate logs if needed
rotate_logs

log "Starting qmi_reconnect check..."

# 1) Check the number of routes for wwan0
route_count=$(ip route show dev wwan0 | wc -l)
if [ "$route_count" -eq 2 ]; then
    log "Two routes found for wwan0. Exiting."
    exit 0
fi

log "Abnormal number of routes found for wwan0."

# 2) Check the last sudo session in qmi_reconnect logs
last_session_log=$(journalctl -u qmi_reconnect -n 1 --no-pager | grep "pam_unix(sudo:session): session opened for user root by (uid=0)")
if [ -z "$last_session_log" ]; then
    log "No sudo session found in logs. Exiting."
    exit 0
fi

# Extract the timestamp of the last sudo session
log_time=$(journalctl -u qmi_reconnect -n 1 --no-pager --output=short-iso | awk '{print $1}')
log_timestamp=$(date -d "$log_time" +%s)
current_timestamp=$(date +%s)
time_diff=$((current_timestamp - log_timestamp))

# Check if the last sudo session was more than 6 minutes ago
if [ "$time_diff" -lt 360 ]; then
    log "Last sudo session was less than 6 minutes ago (wait a bit longer for it to come up). Exiting."
    exit 0
fi

# If all conditions are met, restart qmi_reconnect
log "Conditions met. Restarting qmi_reconnect..."
systemctl stop qmi_reconnect
sleep 10
systemctl start qmi_reconnect
log "qmi_reconnect restart completed."
