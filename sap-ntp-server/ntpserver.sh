#!/bin/bash

zypper -n install ntp 
# line 38: change servers for synchronization (replace to your timezone's one)
server ntp1.jst.mfeed.ad.jp iburst
server ntp2.jst.mfeed.ad.jp iburst
server ntp3.jst.mfeed.ad.jp iburst 
# line 67: add the network range you allow to receive requests
restrict 10.0.0.0 mask 255.255.255.0 notrust 
systemctl start ntpd 
systemctl enable ntpd 