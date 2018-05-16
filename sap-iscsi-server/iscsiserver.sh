#!/bin/bash

IQN1=$1
IQN1CLT1=$2
IQN1CLT2=$3
IQN2=$4
IQN2CLT1=$5
IQN2CLT2=$6
IQN3=$7
IQN3CLT1=$8
IQN3CLT2=$9


#step 2
zypper update -y
#step 3 (with SP3 updates)
zypper remove -y  lio-utils-4.1-15.14.2.x86_64
zypper remove -y  python-rtslib-2.2-30.2.noarch
zypper remove -y  python-configshell-1.5-1.44.noarch
zypper remove -y  targetcli-2.1-17.1.x86_64
zypper install -y targetcli-fb dbus-1-python
zypper install -y yast2-iscsi-lio-server

#step 4
systemctl enable target
systemctl enable targetcli
systemctl start target
systemctl start targetcli

#create the first iscsi target
dd if=/dev/zero of=/iscsi_disks/disk01.img count=0 bs=1 seek=1G 
targetcli backstores/fileio create cl1 /iscsi_disks/disk01.img 1G
targetcli iscsi/ create "$IQN1"
targetcli iscsi/"$IQN1"/tpg1/luns/ create /backstores/fileio/cl1
targetcli iscsi/"$IQN1"/tpg1/acls/ create "$IQN1CLT1"
targetcli iscsi/"$IQN1"/tpg1/acls/ create "$IQN1CLT2"
targetcli saveconfig
systemctl restart target

#create the third iscsi target
dd if=/dev/zero of=/iscsi_disks/disk02.img count=0 bs=1 seek=1G 
targetcli backstores/fileio create cl2 /iscsi_disks/disk02.img 1G
targetcli iscsi/ create "$IQN2"
targetcli iscsi/"$IQN2"/tpg2/luns/ create /backstores/fileio/cl2
targetcli iscsi/"$IQN2"/tpg2/acls/ create "$IQN2CLT1"
targetcli iscsi/"$IQN2"/tpg2/acls/ create "$IQN2CLT2"
targetcli saveconfig
systemctl restart target

#create the third iscsi target
dd if=/dev/zero of=/iscsi_disks/disk03.img count=0 bs=1 seek=1G 
targetcli backstores/fileio create cl3 /iscsi_disks/disk03.img 1G
targetcli iscsi/ "$IQN3"
targetcli iscsi/"$IQN3"/tpg3/luns/ create /backstores/fileio/cl3
targetcli iscsi/"$IQN3"/tpg3/acls/ create "$IQN3CLT1"
targetcli iscsi/"$IQN3"/tpg3/acls/ create "$IQN3CLT2"
targetcli saveconfig
systemctl restart target
