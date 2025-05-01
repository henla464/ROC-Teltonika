#!/bin/bash

# 1) Check the number of routes for wwan0
route_count=$(ip route show dev wwan0 | wc -l)
if [ "$route_count" -eq 2 ]; then
    echo "Two routes found for wwan0. Exiting."
    exit 0
fi

echo "Abnormal number of routes found for wwan0."



# 2) Check the last sudo session in qmi_reconnect logs
last_session_log=$(journalctl -u qmi_reconnect -n 1 --no-pager | grep "pam_unix(sudo:session): session opened for user root by (uid=0)")
if [ -z "$last_session_log" ]; then
    echo "No sudo session found in logs. Exiting."
    exit 0
fi

# Extract the timestamp of the last sudo session
log_time=$(journalctl -u qmi_reconnect -n 1 --no-pager --output=short-iso | awk '{print $1}')
log_timestamp=$(date -d "$log_time" +%s)
current_timestamp=$(date +%s)
time_diff=$((current_timestamp - log_timestamp))

# Check if the last sudo session was more than 6 minutes ago
if [ "$time_diff" -lt 360 ]; then
    echo "Last sudo session was less than 6 minutes ago (wait abit longer for it to come up). Exiting."
    exit 0
fi

# If all conditions are met, restart qmi_reconnect
echo "Conditions met. Restarting qmi_reconnect..."
systemctl stop qmi_reconnect
sleep 10
systemctl start qmi_reconnect
