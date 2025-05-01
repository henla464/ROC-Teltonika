wget https://raw.githubusercontent.com/henla464/ROC-Teltonika/main/setup_dhcpcd_renew.sh -O setup_dhcpcd_renew.sh
sudo chmod ugo+x setup_dhcpcd_renew.sh
sudo ./setup_dhcpcd_renew.sh


#To check when it will be called next time:
systemctl list-timers | grep dhcpcd-renew

#To check status of the service and timer
sudo systemctl status dhcpcd-renew.timer
sudo systemctl status dhcpcd-renew

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


