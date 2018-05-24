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
ASCSPWD=${2}
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
echo "ASCSPWD:" $ASCSPWD >> /tmp/variables.txt
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
  P_ISPRIMARY=$1
  P_SBDID=$2
  P_VMNAME=$3
  P_OTHERVMNAME=$4 
  P_CLUSTERNAME=$5 

  echo "setup cluster"
  echo "P_ISPRIMARY:" $P_ISPRIMARY >> /tmp/variables.txt
  echo "P_SBDID:" $P_SBDID >> /tmp/variables.txt
  echo "P_VMNAME:" $P_VMNAME>> /tmp/variables.txt
  echo "P_OTHERVMNAME:" $P_OTHERVMNAME>> /tmp/variables.txt
  echo "P_CLUSTERNAME:" $P_CLUSTERNAME>> /tmp/variables.txt

  #node1
  if [ "$P_ISPRIMARY" = "yes" ]; then
    ha-cluster-init -y -q csync2
    ha-cluster-init -y -q -u corosync
    ha-cluster-init -y -q sbd -d $P_SBDID
    ha-cluster-init -y -q cluster name=$P_CLUSTERNAME interface=eth0
    touch /tmp/corosyncconfig1.txt	
    /root/waitfor.sh root $P_OTHERVMNAME /tmp/corosyncconfig2.txt	
    systemctl stop corosync
    systemctl stop pacemaker
    write_corosync_config 10.0.5.0 $P_VMNAME $P_OTHERVMNAME
    systemctl start corosync
    systemctl start pacemaker
    touch /tmp/corosyncconfig3.txt	

    sleep 10
  else
    /root/waitfor.sh root $P_OTHERVMNAME /tmp/corosyncconfig1.txt	
    ha-cluster-join -y -q -c $P_OTHERVMNAME csync2 
    ha-cluster-join -y -q ssh_merge
    ha-cluster-join -y -q cluster
    systemctl stop corosync
    systemctl stop pacemaker
    touch /tmp/corosyncconfig2.txt	
    /root/waitfor.sh root $P_OTHERVMNAME /tmp/corosyncconfig3.txt	
    write_corosync_config 10.0.5.0 $P_OTHERVMNAME $VMNAME 
    systemctl restart corosync
    systemctl start pacemaker
  fi
}

declare -fxr setup_cluster

##end of bash function definitions


register_subscription "$SUBEMAIL"  "$SUBID" "$SUBURL"

#get the VM size via the instance api
VMSIZE=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2017-08-01&format=text"`

#install hana prereqs
echo "installing packages"
retry 5 "zypper update -y"
retry 5 "zypper install -y -l sle-ha-release fence-agents" 


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

    sshpt --hosts $OTHERVMNAME -u $USRNAME -p $ASCSPWD --sudo "mkdir -p /root/.ssh"
    sshpt --hosts $OTHERVMNAME -u $USRNAME -p $ASCSPWD --sudo -c ~/.ssh/id_rsa.pub -d /root/
    sshpt --hosts $OTHERVMNAME -u $USRNAME -p $ASCSPWD --sudo "cp /root/id_rsa.pub /root/.ssh/authorized_keys"
    sshpt --hosts $OTHERVMNAME -u $USRNAME -p $ASCSPWD --sudo "chmod 700 /root/.ssh"
    sshpt --hosts $OTHERVMNAME -u $USRNAME -p $ASCSPWD --sudo "chown root:root /root/.ssh/authorized_keys"
    sshpt --hosts $OTHERVMNAME -u $USRNAME -p $ASCSPWD --sudo "chmod 700 /root/.ssh/authorized_keys"

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

#initialize sbd on node1
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

setup_cluster "$ISPRIMARY" "$sbdid" "$VMNAME" "$OTHERVMNAME" "ascscluster"

