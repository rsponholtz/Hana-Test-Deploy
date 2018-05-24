#!/bin/bash
set -x
# store arguments in a special array
args=("$@")
# get number of elements
ELEMENTS=${#args[@]}

# echo each element in array
# for loop
for (( i=0;i<$ELEMENTS;i++)); do
    echo ${args[${i}]}
done

USRNAME=${1}
NFSPWD=${2}
VMNAME=${3}
OTHERVMNAME=${4}
VMIPADDR=${5}
OTHERIPADDR=${6}
ISPRIMARY=${7}
REPOURI=${8}
ISCSIIP=${9}
IQN=${10}
IQNCLIENT=${11}
LBIP=${12}
SUBEMAIL=${13}
SUBID=${14}
SUBURL=${15}


echo "small.sh receiving:"
echo "USRNAME:" $USRNAME >> /tmp/variables.txt
echo "NFSPWD:" $NFSPWD >> /tmp/variables.txt
echo "VMNAME:" $VMNAME >> /tmp/variables.txt
echo "OTHERVMNAME:" $OTHERVMNAME >> /tmp/variables.txt
echo "VMIPADDR:" $VMIPADDR >> /tmp/variables.txt
echo "OTHERIPADDR:" $OTHERIPADDR >> /tmp/variables.txt
echo "ISPRIMARY:" $ISPRIMARY >> /tmp/variables.txt
echo "REPOURI:" $REPOURI >> /tmp/variables.txt
echo "ISCSIIP:" $ISCSIIP >> /tmp/variables.txt
echo "IQN:" $IQN >> /tmp/variables.txt
echo "IQNCLIENT:" $IQNCLIENT >> /tmp/variables.txt
echo "LBIP:" $LBIP >> /tmp/variables.txt
echo "SUBEMAIL:" $SUBEMAIL >> /tmp/variables.txt
echo "SUBID:" $SUBID >> /tmp/variables.txt
echo "SUBURL:" $SUBURL >> /tmp/variables.txt


retry() {
    local -r -i max_attempts="$1"; shift
    local -r cmd="$@"
    local -i attempt_num=1

    until $cmd
    do
        if (( attempt_num == max_attempts ))
        then
            echo "Attempt $attempt_num failed and there are no more attempts left!"
            return 1
        else
            echo "Attempt $attempt_num failed! Trying again in $attempt_num seconds..."
            sleep $(( attempt_num++ ))
        fi
    done
}

declare -fxr retry


register_subscription() {
  SUBEMAIL=$1
  SUBID=$2
  SUBURL=$3

#if needed, register the machine
if [ "$SUBEMAIL" != "" ]; then
  if [ "$SUBURL" = "NONE" ]; then 
    SUSEConnect -e $SUBEMAIL -r $SUBID
  else 
    if [ "$SUBURL" != "" ]; then 
      SUSEConnect -e $SUBEMAIL -r $SUBID --url $SUBURL
    else 
      SUSEConnect -e $SUBEMAIL -r $SUBID
    fi
  fi
  SUSEConnect -p sle-module-public-cloud/12/x86_64 
fi
}

write_corosync_config (){
  BINDIP=$1
  HOST1IP=$2
  HOST2IP=$3
  mv /etc/corosync/corosync.conf /etc/corosync/corosync.conf.orig 
cat > /etc/corosync/corosync.conf.new <<EOF
totem {
        version:        2
        secauth:        on
        crypto_hash:    sha1
        crypto_cipher:  aes256
        cluster_name:   hacluster
        clear_node_high_bit: yes
        token:          5000
        token_retransmits_before_loss_const: 10
        join:           60
        consensus:      6000
        max_messages:   20
        interface {
                ringnumber:     0
                bindnetaddr:    $BINDIP
                mcastport:      5405
                ttl:            1
        }
 transport:      udpu
}
nodelist {
  node {
   ring0_addr:$HOST1IP
   nodeid:1
  }
  node {
   ring0_addr:$HOST2IP
   nodeid:2
  }
}

logging {
        fileline:       off
        to_stderr:      no
        to_logfile:     no
        logfile:        /var/log/cluster/corosync.log
        to_syslog:      yes
        debug:          off
        timestamp:      on
        logger_subsys {
                subsys: QUORUM
                debug:  off
        }
}
quorum {
        # Enable and configure quorum subsystem (default: off)
        # see also corosync.conf.5 and votequorum.5
        provider: corosync_votequorum
        expected_votes: 1
        two_node: 0
}
EOF

cp /etc/corosync/corosync.conf.new /etc/corosync/corosync.conf
}



setup_cluster() {
  ISPRIMARY=$1
  SBDID=$2
  VMNAME=$3
  OTHERVMNAME=$4 
  CLUSTERNAME=$5 
  #node1
  if [ "$ISPRIMARY" = "yes" ]; then
    ha-cluster-init -y -q csync2
    ha-cluster-init -y -q -u corosync
    ha-cluster-init -y -q sbd -d $SBDID
    ha-cluster-init -y -q cluster name=$CLUSTERNAME interface=eth0
    touch /tmp/corosyncconfig1.txt	
    /root/waitfor.sh root $OTHERVMNAME /tmp/corosyncconfig2.txt	
    systemctl stop corosync
    systemctl stop pacemaker
    write_corosync_config 10.0.5.0 $VMNAME $OTHERVMNAME
    systemctl start corosync
    systemctl start pacemaker
    touch /tmp/corosyncconfig3.txt	

    sleep 10
  else
    /root/waitfor.sh root $OTHERVMNAME /tmp/corosyncconfig1.txt	
    ha-cluster-join -y -q -c $OTHERVMNAME csync2 
    ha-cluster-join -y -q ssh_merge
    ha-cluster-join -y -q cluster
    systemctl stop corosync
    systemctl stop pacemaker
    touch /tmp/corosyncconfig2.txt	
    /root/waitfor.sh root $OTHERVMNAME /tmp/corosyncconfig3.txt	
    write_corosync_config 10.0.5.0 $OTHERVMNAME $VMNAME 
    systemctl restart corosync
    systemctl start pacemaker
  fi
}



register_subscription  "$SUBEMAIL"  "$SUBID" "$SUBURL"

#!/bin/bash
echo "logicalvol start" >> /tmp/parameter.txt
  nfslun="$(lsscsi 5 0 0 0 | grep -o '.\{9\}$')"
  pvcreate $nfslun
  vgcreate vg_NFS $nfslun 
  lvcreate -l 100%FREE -n lv_NFS vg_NFS 
echo "logicalvol end" >> /tmp/parameter.txt

#get the VM size via the instance api
VMSIZE=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2017-08-01&format=text"`

#install hana prereqs
echo "installing packages"
zypper update -y
retry 5 "zypper install -y -l sle-ha-release fence-agents drbd drbd-kmp-default drbd-utils"


# step2
echo $URI >> /tmp/url.txt

cp -f /etc/waagent.conf /etc/waagent.conf.orig
sedcmd="s/ResourceDisk.EnableSwap=n/ResourceDisk.EnableSwap=y/g"
sedcmd2="s/ResourceDisk.SwapSizeMB=0/ResourceDisk.SwapSizeMB=163840/g"
cat /etc/waagent.conf | sed $sedcmd | sed $sedcmd2 > /etc/waagent.conf.new
cp -f /etc/waagent.conf.new /etc/waagent.conf
# we may be able to restart the waagent and get the swap configured immediately

cat >>/etc/hosts <<EOF
$VMIPADDR $VMNAME
$OTHERIPADDR $OTHERVMNAME
EOF


##external dependency on sshpt
    retry 5 "zypper install -y python-pip"
    retry 5 "pip install sshpt"
    #set up passwordless ssh on both sides
    cd ~/
    #rm -r -f .ssh
    cat /dev/zero |ssh-keygen -q -N "" > /dev/null

    sshpt --hosts $OTHERVMNAME -u $USRNAME -p $NFSPWD --sudo "mkdir -p /root/.ssh"
    sshpt --hosts $OTHERVMNAME -u $USRNAME -p $NFSPWD --sudo -c ~/.ssh/id_rsa.pub -d /root/
    sshpt --hosts $OTHERVMNAME -u $USRNAME -p $NFSPWD --sudo "cp /root/id_rsa.pub /root/.ssh/authorized_keys"
    sshpt --hosts $OTHERVMNAME -u $USRNAME -p $NFSPWD --sudo "chmod 700 /root/.ssh"
    sshpt --hosts $OTHERVMNAME -u $USRNAME -p $NFSPWD --sudo "chown root:root /root/.ssh/authorized_keys"
    sshpt --hosts $OTHERVMNAME -u $USRNAME -p $NFSPWD --sudo "chmod 700 /root/.ssh/authorized_keys"

    cd /root 
    wget $REPOURI/waitfor.sh
    chmod u+x waitfor.sh

#Clustering setup
#start services [A]
systemctl enable iscsid
systemctl enable iscsi
systemctl enable sbd

#set up iscsi initiator [A]
myhost=`hostname`
cp -f /etc/iscsi/initiatorname.iscsi /etc/iscsi/initiatorname.iscsi.orig
#change the IQN to the iscsi server
sed -i "/InitiatorName=/d" "/etc/iscsi/initiatorname.iscsi"
echo "InitiatorName=$IQNCLIENT" >> /etc/iscsi/initiatorname.iscsi
systemctl restart iscsid
systemctl restart iscsi
iscsiadm -m discovery --type=st --portal=$ISCSIIP


iscsiadm -m node -T "$IQN" --login --portal=$ISCSIIP:3260
iscsiadm -m node -p "$ISCSIIP":3260 --op=update --name=node.startup --value=automatic

sleep 10 
echo "hana iscsi end" >> /tmp/parameter.txt

device="$(lsscsi 6 0 0 0| cut -c59-)"
diskid="$(ls -l /dev/disk/by-id/scsi-* | grep $device)"
sbdid="$(echo $diskid | grep -o -P '/dev/disk/by-id/scsi-3.{32}')"

#node1
if [ "$ISPRIMARY" = "yes" ]; then
  sbd -d $sbdid -1 90 -4 180 create
fi

#!/bin/bash [A]
cd /etc/sysconfig
cp -f /etc/sysconfig/sbd /etc/sysconfig/sbd.new

sbdcmd="s#SBD_DEVICE=\"\"#SBD_DEVICE=\"$sbdid\"#g"
sbdcmd2='s/SBD_PACEMAKER=/SBD_PACEMAKER="yes"/g'
sbdcmd3='s/SBD_STARTMODE=/SBD_STARTMODE="always"/g'
cat sbd.new | sed $sbdcmd | sed $sbdcmd2 | sed $sbdcmd3 > sbd.modified
cp -f /etc/sysconfig/sbd.modified /etc/sysconfig/sbd
echo "hana sbd end" >> /tmp/parameter.txt

echo softdog > /etc/modules-load.d/softdog.conf
modprobe -v softdog
echo "hana watchdog end" >> /tmp/parameter.txt

cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys


setup_cluster $ISPRIMARY $sbdid $VMNAME $OTHERVMNAME "nfscluster"

#get the VM size via the instance api
VMSIZE=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2017-08-01&format=text"`
mv /etc/drbd.d/global_common.conf /etc/drbd.d/global_common.conf-orig 
cat >/etc/drbd.d/global_common.conf <<EOF
global {
        usage-count no;
}
common {
        handlers {
                fence-peer "/usr/lib/drbd/crm-fence-peer.sh";
                after-resync-target /usr/lib/drbd/crm-unfence-peer.sh;
                split-brain "/usr/lib/drbd/notify-split-brain.sh root";
                pri-lost-after-sb "/usr/lib/drbd/notify-pri-lost-after-sb.sh; /usr/lib/drbd/notify-emergency-reboot.sh; echo b > /proc/sysrq-trigger ; reboot -f";
        }
        startup {
                wfc-timeout 0;
        }
        options {
        }

        disk {
                resync-rate 50M;
        }
        net {
                after-sb-0pri discard-younger-primary;
                after-sb-1pri discard-secondary;
                after-sb-2pri call-pri-lost-after-sb;
        }
}
EOF

#node1
if [ "$ISPRIMARY" = "yes" ]; then

cat >/etc/drbd.d/NWS-nfs.res <<EOF
resource NWS-nfs {
   protocol     C;
   disk {
      on-io-error       pass_on;
   }
   on $VMNAME {
      address   $VMIPADDR:7790;
      device    /dev/drbd0;
      disk      /dev/vg_NFS/lv_NFS;
      meta-disk internal;
   }
   on $OTHERVMNAME {
      address   $OTHERIPADDR:7790;
      device    /dev/drbd0;
      disk      /dev/vg_NFS/lv_NFS;
      meta-disk internal;
   }
}
EOF

echo "Create NFS server and root share"
echo "/srv/nfs/ *(rw,no_root_squash,fsid=0)">/etc/exports
systemctl enable nfsserver
service nfsserver restart
mkdir /srv/nfs/

drbdadm create-md NWS-nfs
drbdadm up NWS-nfs
#drbdadm status

  drbdsetup wait-connect-resource NWS-nfs
#  drbdadm status

  drbdadm new-current-uuid --clear-bitmap NWS-nfs
#  drbdadm status

  drbdadm -- --overwrite-data-of-peer --force primary NWS-nfs
  #drbdadm primary --force NWS_nfs
#  drbdadm status

  echo "waiting for drbd sync"
  drbdsetup wait-sync-resource NWS-nfs
  sleep 1m
  mkfs.xfs /dev/drbd0
  echo "waiting for drbd sync"
  drbdsetup wait-sync-resource NWS-nfs

 
  mask=$(echo $LBIP | cut -d'/' -f 2)
  
  echo "Creating NFS directories"
  mkdir /srv/nfs/NWS
  chattr +i /srv/nfs/NWS
  mount /dev/drbd0 /srv/nfs/NWS
  mkdir /srv/nfs/NWS/sidsys
  mkdir /srv/nfs/NWS/sapmntsid
  mkdir /srv/nfs/NWS/trans
  mkdir /srv/nfs/NWS/ASCS
  mkdir /srv/nfs/NWS/ASCSERS
  mkdir /srv/nfs/NWS/SCS
  mkdir /srv/nfs/NWS/SCSERS
  umount /srv/nfs/NWS

  echo "waiting for drbd sync"
  drbdsetup wait-sync-resource NWS-nfs

fi
#node2
if [ "$ISPRIMARY" = "no" ]; then

cat >/etc/drbd.d/NWS-nfs.res <<EOL
resource NWS-nfs {
   protocol     C;
   disk {
      on-io-error       pass_on;
   }
   on $OTHERVMNAME {
      address   $OTHERIPADDR:7790;
      device    /dev/drbd0;
      disk      /dev/vg_NFS/lv_NFS;
      meta-disk internal;
   }
   on $VMNAME {
      address   $VMIPADDR:7790;
      device    /dev/drbd0;
      disk      /dev/vg_NFS/lv_NFS;
      meta-disk internal;
   }
}
EOL

echo "Create NFS server and root share"
echo "/srv/nfs/ *(rw,no_root_squash,fsid=0)">/etc/exports
systemctl enable nfsserver
service nfsserver restart
mkdir /srv/nfs/

drbdadm create-md NWS-nfs
drbdadm up NWS-nfs
#drbdadm status

echo "waiting for connection"

fi


#node1
if [ "$ISPRIMARY" = "yes" ]; then

  echo "Creating NFS resources"

  crm configure property maintenance-mode=true
  crm configure property stonith-timeout=600
  
#  crm node standby $OTHERVMNAME
#  crm node standby $VMNAME

#  crm configure rsc_defaults resource-stickiness="1"
#
  crm configure primitive drbd_NWS_nfs ocf:linbit:drbd params drbd_resource="NWS-nfs" op monitor interval="15" role="Master" op monitor interval="30" role="Slave"
  crm configure ms ms-drbd_NWS_nfs drbd_NWS_nfs meta master-max="1" master-node-max="1" clone-max="2" clone-node-max="1" notify="true" interleave="true"
  crm configure primitive fs_NWS_sapmnt ocf:heartbeat:Filesystem params device=/dev/drbd0 directory=/srv/nfs/NWS fstype=xfs options="sync,dirsync" op monitor interval="10s"

  crm configure primitive exportfs_NWS ocf:heartbeat:exportfs params directory="/srv/nfs/NWS" options="rw,no_root_squash" clientspec="*" fsid=1 wait_for_leasetime_on_stop=true op monitor interval="30s"
  crm configure primitive exportfs_NWS_sidsys ocf:heartbeat:exportfs params directory="/srv/nfs/NWS/sidsys" options="rw,no_root_squash" clientspec="*" fsid=2 wait_for_leasetime_on_stop=true op monitor interval="30s"
  crm configure primitive exportfs_NWS_sapmntsid ocf:heartbeat:exportfs params directory="/srv/nfs/NWS/sapmntsid" options="rw,no_root_squash" clientspec="*" fsid=3 wait_for_leasetime_on_stop=true op monitor interval="30s"
  crm configure primitive exportfs_NWS_trans ocf:heartbeat:exportfs params directory="/srv/nfs/NWS/trans" options="rw,no_root_squash" clientspec="*" fsid=4 wait_for_leasetime_on_stop=true op monitor interval="30s"
  crm configure primitive exportfs_NWS_ASCS ocf:heartbeat:exportfs params directory="/srv/nfs/NWS/ASCS" options="rw,no_root_squash" clientspec="*" fsid=5 wait_for_leasetime_on_stop=true op monitor interval="30s"
  crm configure primitive exportfs_NWS_ASCSERS ocf:heartbeat:exportfs params directory="/srv/nfs/NWS/ASCSERS" options="rw,no_root_squash" clientspec="*" fsid=6 wait_for_leasetime_on_stop=true op monitor interval="30s"
  crm configure primitive exportfs_NWS_SCS ocf:heartbeat:exportfs params directory="/srv/nfs/NWS/SCS" options="rw,no_root_squash" clientspec="*" fsid=7 wait_for_leasetime_on_stop=true op monitor interval="30s"
  crm configure primitive exportfs_NWS_SCSERS ocf:heartbeat:exportfs params directory="/srv/nfs/NWS/SCSERS" options="rw,no_root_squash" clientspec="*" fsid=8 wait_for_leasetime_on_stop=true op monitor interval="30s"
  
  lbprobe="61000"
  mask="24"

  crm configure primitive vip_NWS_nfs IPaddr2 params ip=$LBIP cidr_netmask=$mask op monitor interval=10 timeout=20
  crm configure primitive nc_NWS_nfs anything params binfile="/usr/bin/nc" cmdline_options="-l -k $lbprobe" op monitor timeout=20s interval=10 depth=0

  crm configure group g-NWS_nfs fs_NWS_sapmnt exportfs_NWS exportfs_NWS_sidsys exportfs_NWS_sapmntsid exportfs_NWS_trans exportfs_NWS_ASCS exportfs_NWS_ASCSERS exportfs_NWS_SCS exportfs_NWS_SCSERS nc_NWS_nfs vip_NWS_nfs
  crm configure order o-NWS_drbd_before_nfs inf: ms-drbd_NWS_nfs:promote g-NWS_nfs:start
  crm configure colocation col-NWS_nfs_on_drbd inf: g-NWS_nfs ms-drbd_NWS_nfs:Master

#  crm node online $VMNAME
#  crm node online $OTHERVMNAME
  crm configure property maintenance-mode=false

  touch /tmp/crmconfigcomplete.txt

fi
#node2
if [ "$ISPRIMARY" = "no" ]; then

echo "waiting for connection"

fi

