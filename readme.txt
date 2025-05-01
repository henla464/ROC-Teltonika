# dhcpcd check for abnormal routes and do release and renew
curl -o setup_dhcpcd_renew.sh https://raw.githubusercontent.com/henla464/ROC-Teltonika/main/setup_dhcpcd_renew.sh
sudo chmod ugo+x setup_dhcpcd_renew.sh
sudo ./setup_dhcpcd_renew.sh


# stop and start qmi_reconnect service if it get stuck
curl -o setup_check_qmi_reconnect_and_restart.sh https://raw.githubusercontent.com/henla464/ROC-Teltonika/main/setup_check_qmi_reconnect_and_restart.sh
sudo chmod ugo+x setup_check_qmi_reconnect_and_restart.sh
sudo ./setup_check_qmi_reconnect_and_restart.sh



#To check when it will be called next time:
systemctl list-timers | grep dhcpcd-renew

#To check status of the service and timer
sudo systemctl status dhcpcd-renew.timer
sudo systemctl status dhcpcd-renew


#To check when it will be called next time:
systemctl list-timers | grep check_qmi_reconnect_and_restart

#To check status of the service and timer
sudo systemctl status check_qmi_reconnect_and_restart.timer
sudo systemctl status check_qmi_reconnect_and_restart



=================
https://www.raspberrypi.com/documentation/computers/config_txt.html#common-options

enable_uart
enable_uart=1 (in conjunction with console=serial0,115200 in cmdline.txt) requests that the kernel creates a serial console, accessible using GPIOs 14 and 15 (pins 8 and 10 on the 40-pin header). Editing cmdline.txt to remove the line quiet enables boot messages from the kernel to also appear there. See also uart_2ndstage

===============
route -n
===============
journalctl -u dhcpcd
===============
sudo dhcpcd --dumplease wwan0
===============
sudo dhcpcd -k wwan0      # Release the current lease  
sudo dhcpcd -n wwan0      # Force a new DHCP discovery  
===============
sudo dhcpcd -n wwan0   # if it is already leased it will only rebind

===============
can change to this in service file:
ExecStartPre=dhcpcd -k wwan0
ExecStart=dhcpcd -n wwan0


