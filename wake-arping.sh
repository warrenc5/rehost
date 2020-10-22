#!/bin/bash

sudo wakeonlan $1
let count=0
sudo arping -c 1 $2
until test $? -eq 0 || test $count -gt 2 ; do
  let count++ 
  sudo wakeonlan $1
  sudo arping -W 5 -w 5 -c 1 $2
done 
