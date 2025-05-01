#!/bin/bash

# Configuration
LOG_FILE="/var/log/network_restart.log"
INTERFACE="wwan0"

# Logger function with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check routes for wwan0 interface
route_count=$(route -n | awk -v intf="$INTERFACE" '$8 == intf' | wc -l)
log "Found $route_count routes for $INTERFACE"

# Main logic
if [ "$route_count" -eq 2 ]; then
    log "Triggering DHCP restart for $INTERFACE"
    
    # Release current lease
    if dhcpcd -k "$INTERFACE" >> "$LOG_FILE" 2>&1; then
        log "Successfully released DHCP lease"
    else
        log "ERROR: Failed to release DHCP lease"
        exit 1
    fi

    # Request new lease
    if dhcpcd -n "$INTERFACE" >> "$LOG_FILE" 2>&1; then
        log "Successfully requested new DHCP lease"
    else
        log "ERROR: Failed to request new DHCP lease"
        exit 2
    fi

else
    log "No action needed - route count not equal to 2"
fi
