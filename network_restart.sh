#!/bin/bash

# Configuration
INTERFACE="wwan0"
LOG_DIR="/var/log/wwan0_network"
LOG_FILE="$LOG_DIR/network_check.log"
DHCPCD_LOG="/var/log/syslog"  # Or /var/log/dhcpcd.log on some systems
MAX_LOG_FILES=2               # Number of old logs to keep
LOG_SIZE_KB=1024              # Rotate when log reaches 1MB
MAX_RETRIES=3
RETRY_DELAY=5

# Create log dir if needed
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Initialize logging system
init_logging() {
    mkdir -p "$LOG_DIR"
    
    # Rotate logs if needed
    if [ -f "$LOG_FILE" ]; then
        current_size=$(du -k "$LOG_FILE" | cut -f1)
        if [ "$current_size" -ge "$LOG_SIZE_KB" ]; then
            # Rotate logs (keep N most recent)
            for ((i=$MAX_LOG_FILES-1; i>=1; i--)); do
                [ -f "$LOG_FILE.$i" ] && mv "$LOG_FILE.$i" "$LOG_FILE.$((i+1))"
            done
            mv "$LOG_FILE" "$LOG_FILE.1"
        fi
    fi
    
    touch "$LOG_FILE"
}

# Logger function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check DHCP lease status
check_lease_status() {
    local interface=$1
    local operation=$2  # "release" or "bound"
    local log_pattern

    if [ "$operation" = "release" ]; then
        log_pattern="dhcpcd\[[0-9]+\]: $interface: released"
    else
        log_pattern="dhcpcd\[[0-9]+\]: $interface: leased .* for"
    fi

    # Check last 20 lines of log to avoid parsing entire file
    if tail -n 20 "$DHCPCD_LOG" | grep -qE "$log_pattern"; then
        return 0
    else
        return 1
    fi
}

# Main function
restart_dhcp() {
    local retry_count=0
    local release_ok=false
    local renew_ok=false

    # Release DHCP lease
    while [ $retry_count -lt $MAX_RETRIES ] && [ "$release_ok" = false ]; do
        log "Attempting to release DHCP lease (attempt $((retry_count+1))/$MAX_RETRIES)"
        dhcpcd -k "$INTERFACE" >> "$LOG_FILE" 2>&1
        
        if check_lease_status "$INTERFACE" "release"; then
            release_ok=true
            log "Successfully released DHCP lease"
        else
            log "Release not confirmed in logs, retrying..."
            retry_count=$((retry_count+1))
            sleep $RETRY_DELAY
        fi
    done

    # Only proceed if release was successful
    if [ "$release_ok" = false ]; then
        log "ERROR: Failed to confirm DHCP release after $MAX_RETRIES attempts"
        return 1
    fi

    # Reset for renew attempt
    retry_count=0
    sleep $RETRY_DELAY

    # Renew DHCP lease
    while [ $retry_count -lt $MAX_RETRIES ] && [ "$renew_ok" = false ]; do
        log "Attempting to renew DHCP lease (attempt $((retry_count+1))/$MAX_RETRIES)"
        dhcpcd -n "$INTERFACE" >> "$LOG_FILE" 2>&1
        
        if check_lease_status "$INTERFACE" "bound"; then
            renew_ok=true
            log "Successfully renewed DHCP lease"
        else
            log "Renewal not confirmed in logs, retrying..."
            retry_count=$((retry_count+1))
            sleep $RETRY_DELAY
        fi
    done

    if [ "$renew_ok" = false ]; then
        log "ERROR: Failed to confirm DHCP renewal after $MAX_RETRIES attempts"
        return 2
    fi

    return 0
}

# Initialize logging
init_logging

# Main execution
log "==== Starting network check for $INTERFACE ===="

# Get current route count
route_count=$(route -n | awk -v intf="$INTERFACE" '$8 == intf' | wc -l)
log "Current route count: $route_count"

# Check if we need to restart DHCP
if [ "$route_count" -ne 2 ]; then
    log "Abnormal route count detected - initiating DHCP restart"
    
    if restart_dhcp; then
        new_count=$(route -n | awk -v intf="$INTERFACE" '$8 == intf' | wc -l)
        log "DHCP restart successful. New route count: $new_count"
    else
        log "DHCP restart failed"
        exit 1
    fi
else
    log "Route count normal - no action needed"
fi

log "==== Network check completed ===="
