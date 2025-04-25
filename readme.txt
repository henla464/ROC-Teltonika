
wget https://raw.githubusercontent.com/henla464/ROC-Teltonika/main/setup_dhclient_renew.sh -O setup_dhclient_renew.sh
sudo chmod ugo+x setup_dhclient_renew.sh
sudo ./setup_dhclient_renew.sh


wget https://raw.githubusercontent.com/henla464/ROC-Teltonika/main/setup_dhcpcd_renew.sh -O setup_dhcpcd_renew.sh
sudo chmod ugo+x setup_dhcpcd_renew.sh
sudo ./setup_dhcpcd_renew.sh


To check when it will be called next time:
systemctl list-timers | grep dhclient-renew

To check status of the service and timer
sudo systemctl status dhclient-renew.timer
sudo systemctl status dhclient-renew
