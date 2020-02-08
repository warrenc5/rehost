# rehost

update hosts file - rewrite ip addresses for known ether mac address on the lan from the arpd cache

just add a file in /etc/hosts-ethers with the following format

Leet    80:aa:5b:8a:65:5b       
iPoo    2c:25:2f:cc:c6:62       

run rehost from cron

crontab -e 

@hourly ~/rehost.sh


it will update your /etc/hosts file with eth entries from arp cache.

Run 

edit /etc/init.d/arpd

arpd -k -b /var/lib/arpd/arpd.db -a 3 enp4s0f1

systemctl enable arpd.service
systemctl start arpd.service
