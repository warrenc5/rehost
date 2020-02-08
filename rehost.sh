#!/bin/bash -x
HOSTS=/etc/hosts
HOST_ETHERS=/etc/hosts-ethers
arpd -l |grep -v '#'  | grep -v FAILED | sort -k 3 > /tmp/arp.txt

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
    sed -i "/$NAME/ s/^.* /$IP /" $HOSTS
done < /tmp/hosts
