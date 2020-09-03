#!/bin/bash -x
HOSTS=/etc/hosts
HOST_ETHERS=/etc/hosts-ethers
ARP_DB=/var/tmp/arpd.db
IFACE=`ifconfig -s | cut -f 1 -d ' ' | grep "\(enp\|eth\|wlan\|wlp\)"`
SUDO=`which sudo`
TIME=10
$SUDO rm /tmp/arp.txt /tmp/ethers /tmp/hosts
$SUDO pkill arpd
echo $IFACE

if [ ! -f ${HOST_ETHERS} ] ; then
	echo "create $HOST_ETHERS"
	echo "[hostname] [mac]"

	exit 1
else
  cat /etc/hosts-ethers  | cut -d ' ' -f 2 > /tmp/ethers
  $SUDO chmod o+r /tmp/ethers
  wakeonlan -f /tmp/ethers
fi


$SUDO arpd -b $ARP_DB -a 3 -k $IFACE
$SUDO chmod o+r $ARP_DB

ARP_PID=$(pgrep arpd)

if [ $? -ne 0 ] ; then 
exit 1
fi

echo "Waiting for arps"

sleep $TIME
$SUDO kill $ARP_PID

arpd -l -b $ARP_DB | grep -v '#'  | grep -v FAILED | sort -k 3 > /tmp/arp.txt
$SUDO chmod o+r /tmp/arp.txt

if [ ! -s /tmp/arp.txt ] ; then 
	echo '/tmp/arp.txt is empty - no arps?' 
	exit 1
else 
  echo 'found arps' 
  wc -l /tmp/arp.txt
fi

#ifconfig -s | cut -f 1 -d ' ' | grep -v Iface

sort -k 2 $HOST_ETHERS > /tmp/hosts-ethers
join -1 3 -2 2 /tmp/arp.txt /tmp/hosts-ethers | cut -d ' ' -f 3-4  | sort -k 1 > /tmp/hosts

ip='(.*)'
name='(.*)'
pat="$ip\s$name"

while IFS= read -r line; do
    [[ $line =~ $pat ]] 
    IP="${BASH_REMATCH[1]}"
    NAME="${BASH_REMATCH[2]}"
    echo "-${IP}-${NAME}-"
    grep $NAME $HOSTS
    if [ $? == 0 ] ; then
	    sed -i "/$NAME/ s/^.*\([[:space:]]\)/$IP\1/" $HOSTS
    else 
	    echo "$IP	$NAME" >> $HOSTS
    fi

done < /tmp/hosts
