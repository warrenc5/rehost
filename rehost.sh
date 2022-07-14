#!/bin/bash -x
HOSTS=/etc/hosts
ETHERS=/etc/ethers
ARP_DB=/var/tmp/arpd.db
IFACES=`ip link | grep UP | cut -d ':' -f 2 | grep  "\(enp\|eth\|wlan\|wlp\)" | grep -v "veth"`
SUDO=`which sudo`
TIME=10
$SUDO rm /tmp/arp.txt /tmp/ethers /tmp/hosts $ARP_DB
$SUDO pkill arpd
echo $IFACES

if [ ! -f ${ETHERS} ] ; then
	echo "create $ETHERS"
	echo "[mac] [hostname]"

	exit 1
else
  $SUDO cat $ETHERS  | $SUDO cut -f 1,2 > /tmp/ethers
  $SUDO chmod o+r /tmp/ethers
  $SUDO cat $ETHERS  | $SUDO cut -f 1 > /tmp/ethers-wol
  $SUDO wakeonlan -f /tmp/ethers-wol
fi


for IFACE in $IFACES ; do
$SUDO arpd -b $ARP_DB -a 3 -k $IFACE

$SUDO chmod o+r $ARP_DB


ARP_PID=$(pgrep arpd)

if [ $? -ne 0 ] ; then 
continue 
fi

echo "Waiting for arps"

sudo nmap -n -v -sn 10.0.0.0/24 2>&1 | grep -v down
#sleep $TIME
$SUDO kill $ARP_PID
done

$SUDO arpd -l -b $ARP_DB | grep -v '#'  | grep -v FAILED | sort -k 3 > /tmp/arp.txt
$SUDO chmod o+r /tmp/arp.txt

if [ ! -s /tmp/arp.txt ] ; then 
	echo '/tmp/arp.txt is empty - no arps?' 
	exit 1
else 
  echo 'found arps' 
  wc -l /tmp/arp.txt
fi

#ifconfig -s | cut -f 1 -d ' ' | grep -v Iface


sort -k 1 $ETHERS | grep -v -E '[0-9]{1,3}?\.[0-9]{1,3}?\.' > /tmp/ethers
join -1 3 -2 1 /tmp/arp.txt /tmp/ethers | cut -d ' ' -f 3-4  | sort -k 1 > /tmp/hosts

ip='(.*)'
name='(.*)'
pat="$ip\s$name"

while IFS= read -r line; do
    [[ $line =~ $pat ]] 
    IP="${BASH_REMATCH[1]}"
    NAME="${BASH_REMATCH[2]}"
    echo "-${IP}-${NAME}-"
    grep "\<$NAME\>" $HOSTS
    if [ $? == 0 ] ; then
	    $SUDO sed -i "/\<$NAME\>/ s/^.*\([[:space:]]\)/$IP\1/" $HOSTS
    else 
	    echo "$IP	$NAME" | sudo tee -a $HOSTS
    fi

done < /tmp/hosts
