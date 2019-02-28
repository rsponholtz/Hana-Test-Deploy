#!/bin/bash
set -x

IQN1=$1
IQN1CLT1=$2
IQN1CLT2=$3
IQN2=$4
IQN2CLT1=$5
IQN2CLT2=$6
IQN3=$7
IQN3CLT1=$8
IQN3CLT2=$9


setupTarget() {
    p_diskName=$1
    p_iqn_connect=$2
    p_iqn_client1=$3
    p_iqn_client2=$4

    echo "setupTarget $p_diskName $p_iqn_connect $p_iqn_client1 $p_iqn_client2"

    #create the first iscsi target
    #dd if=/dev/zero of=/iscsi_disks/"$p_diskName".img count=0 bs=1 seek=1G

    targetcli backstores/fileio create "$p_diskName" /iscsi_disks/"$p_diskName" 1G write_back=false
    targetcli iscsi/ create "$p_iqn_connect"
    targetcli iscsi/"$p_iqn_connect"/tpg1/luns/ create /backstores/fileio/"$p_diskName"
    targetcli iscsi/"$p_iqn_connect"/tpg1/acls/ create "$p_iqn_client1"
    targetcli iscsi/"$p_iqn_connect"/tpg1/acls/ create "$p_iqn_client2"

#    targetcli iscsi/"$p_iqn_connect"/"$p_diskName"/ set attribute authentication=0
#    targetcli iscsi/"$p_iqn_connect"/"$p_diskName"/portals create

}


#step 2
#zypper update -y
#step 3 (with SP3 updates)
zypper remove -y lio-utils 
zypper remove -y python-rtslib 
zypper remove -y python-configshell 
zypper remove -y targetcli
zypper install -y targetcli-fb
zypper install -y dbus-1-python


#step 4
systemctl enable targetcli
systemctl start targetcli

mkdir /iscsi_disks
setupTarget disk01 $IQN1 $IQN1CLT1 $IQN1CLT2
setupTarget disk02 $IQN2 $IQN2CLT1 $IQN2CLT2
setupTarget disk03 $IQN3 $IQN3CLT1 $IQN3CLT2

targetcli saveconfig
#systemctl restart targetcli

