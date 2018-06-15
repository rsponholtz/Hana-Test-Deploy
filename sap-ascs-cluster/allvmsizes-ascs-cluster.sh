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
URI=${8}
HANASID=${9}
REPOURI=${10}
ISCSIIP=${11}
IQN=${12}
IQNCLIENT=${13}
LBIP=${14}
SUBEMAIL=${15}
SUBID=${16}
SUBURL=${17}
NFSILBIP=${18}


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
echo "NFSILBIP:" $NFSILBIP >> /tmp/variables.txt

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

waitfor() {
P_USER=$1
P_HOST=$2
P_FILESPEC=$3

RESULT=1
while [ $RESULT = 1 ]
do
    sleep 1
    ssh -q -n -o BatchMode=yes -o StrictHostKeyChecking=no "$P_USER@$P_HOST" "test -e $P_FILESPEC"
    RESULT=$?
    if [ "$RESULT" = "255" ]; then
        (>&2 echo "waitfor failed in ssh")
        return 255
    fi
done
return 0
}

declare -fxr waitfor

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

write_corosync_config ()
{
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


create_temp_swapfile() {
  P_SWAPNAME=$1
  P_SWAPSIZE=$2
  
  dd if=/dev/zero of=$P_SWAPNAME bs=1024 count=$P_SWAPSIZE
  chown root:root $P_SWAPNAME
  chmod 0600 $P_SWAPNAME
  mkswap $P_SWAPNAME
  swapon $P_SWAPNAME
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
    ha-cluster-init -y -q -s $P_SBDID sbd 
    ha-cluster-init -y -q cluster name=$P_CLUSTERNAME interface=eth0
    touch /tmp/corosyncconfig1.txt	
    waitfor root $P_OTHERVMNAME /tmp/corosyncconfig2.txt	
    systemctl stop corosync
    systemctl stop pacemaker
    write_corosync_config 10.0.5.0 $P_VMNAME $P_OTHERVMNAME
    systemctl start corosync
    systemctl start pacemaker
    touch /tmp/corosyncconfig3.txt	

    sleep 10
  else
    waitfor root $P_OTHERVMNAME /tmp/corosyncconfig1.txt	
    ha-cluster-join -y -q -c $P_OTHERVMNAME csync2 
    ha-cluster-join -y -q ssh_merge
    ha-cluster-join -y -q cluster
    systemctl stop corosync
    systemctl stop pacemaker
    touch /tmp/corosyncconfig2.txt	
    waitfor root $P_OTHERVMNAME /tmp/corosyncconfig3.txt	
    write_corosync_config 10.0.5.0 $P_OTHERVMNAME $VMNAME 
    systemctl restart corosync
    systemctl start pacemaker
  fi
}

declare -fxr setup_cluster


download_sapbits() {
    URI=$1

  cd  /srv/nfs/NWS/SapBits

  retry 5 "wget  --quiet $URI/SapBits/51050423_3.ZIP"
  retry 5 "wget  --quiet $URI/SapBits/51050829_JAVA_part1.exe"   
  retry 5 "wget  --quiet $URI/SapBits/51050829_JAVA_part2.rar" 
  retry 5 "wget  --quiet $URI/SapBits/51052190_part1.exe"
  retry 5 "wget  --quiet $URI/SapBits/51052190_part2.rar"
  retry 5 "wget  --quiet $URI/SapBits/51052190_part3.rar"
  retry 5 "wget  --quiet $URI/SapBits/51052190_part4.rar"
  retry 5 "wget  --quiet $URI/SapBits/51052190_part5.rar"
  retry 5 "wget  --quiet $URI/SapBits/51052318_part1.exe"
  retry 5 "wget  --quiet $URI/SapBits/51052318_part2.rar"
  retry 5 "wget  --quiet $URI/SapBits/SAPCAR_1014-80000935.EXE"
  retry 5 "wget  --quiet $URI/SapBits/SWPM10SP23_1-20009701.SAR"
  retry 5 "wget  --quiet $URI/SapBits/SAPHOSTAGENT36_36-20009394.SAR"
  retry 5 "wget  --quiet $URI/SapBits/SAPEXE_200-80002573.SAR"
  retry 5 "wget  --quiet $URI/SapBits/SAPEXEDB_200-80002572.SAR"
  #unpack some of this
  retry 5 "zypper install -y unrar"

chmod u+x SAPCAR_1014-80000935.EXE
ln -s ./SAPCAR_1014-80000935.EXE sapcar

mkdir SWPM10SP23_1
cd SWPM10SP23_1
../sapcar -xf ../SWPM10SP23_1-20009701.SAR
cd ..


}

write_ascs_ini_file() {
  cd /root
  mkdir silent_install
  cd silent_install
cat > /root/silent_install/ascs.params <<EOF
##############################################################################################################################################################################################################################
#                                                                                                                                                                                                                            #
# Installation service 'SAP S/4HANA 1709 > SAP S/4HANA Server > SAP HANA Database > Installation > Application Server ABAP > High-Availability System > ASCS Instance', product id 'NW_ABAP_ASCS:S4HANA1709.CORE.HDB.ABAPHA' #
#                                                                                                                                                                                                                            #
##############################################################################################################################################################################################################################

# Password for the Diagnostics Agent specific <dasid>adm user. Provided value may be encoded.
# DiagnosticsAgent.dasidAdmPassword =

# Windows domain in which the Diagnostics Agent users must be created. This is an optional property (Windows only).
# DiagnosticsAgent.domain =

# Windows only: Password for the Diagnostics Agent specific 'SAPService<DASID>' user.
# DiagnosticsAgent.sapServiceDASIDPassword =

# Specify whether the all operating system users are to be removed from group 'sapinst' after the execution of Software Provisioning Manager has completed.
# NW_Delete_Sapinst_Users.removeUsers = false

# Master password
NW_GetMasterPassword.masterPwd = des24(151|174|40|210|8|12|209|157|98|106|194|247|230|117|97|90|154|104|186|)

# Human readable form of the default login language to be preselected in SAPGUI. This Parameter is potentialy prompted in addition in the screen that also asks for the <SAPSID>. It is only prompted in systems that have an ABAP stack. It is prompted for installation but not for system copy. It is asked in those installations, that perform the ABAP load. That could be the database load installation in case of a distributed system szenario, or in case of a standard system installation with all instances on one host. This Parameter is saved in the 'DEFAULT' profile. It is has no influence on language settings in a Java stack. Valid names are stored in a table of subcomponent 'NW_languagesInLoadChecks'. The available languages must be declaired in the 'LANGUAGES_IN_LOAD' parameter of the 'product.xml' file . In this file, the one-character representation of the languages is used. Check the same table in subcomponent 'NW_languagesInLoadChecks'.
# NW_GetSidNoProfiles.SAP_GUI_DEFAULT_LANGUAGE =

# Windows only: The drive to use
# NW_GetSidNoProfiles.sapdrive =

# Unix only: The SAP mount directory path. Default value is '/sapmnt'.
# NW_GetSidNoProfiles.sapmnt = /sapmnt

# The SAP system ID <SAPSID> of the system to be installed
NW_GetSidNoProfiles.sid = S40

# Only use this parameter if recommended by SAP.
# NW_GetSidNoProfiles.strictSidCheck = true

# Specify whether this system is to be a Unicode system.
# NW_GetSidNoProfiles.unicode = true

# DEPRECATED, DO NOT USE!
NW_SAPCrypto.SAPCryptoFile = /sapbits/SAPEXE_200-80002573.SAR

# Add gateway process in the (A)SCS instance
# NW_SCS_Instance.ascsInstallGateway = false

# Add Web Dispatcher process in the (A)SCS instance
# NW_SCS_Instance.ascsInstallWebDispatcher = false

# Dual stack only: Specify the ASCS instance number. Leave empty for default.
# NW_SCS_Instance.ascsInstanceNumber =

# Specify whether a 'prxyinfo(.DAT)' file is to be created in the 'global' directory if this file does not yet exist and that the 'gw/prxy_info' in the 'DEFAULT' profile is to be set accordingly. Default is false.
# NW_SCS_Instance.createGlobalProxyInfoFile = false

# Specify whether a 'reginfo(.DAT)' file is to be created in the 'global' directory. Default is 'false'.
# NW_SCS_Instance.createGlobalRegInfoFile = false

# The instance number of the (A)SCS instance.  Leave this value empty if you want to use the default instance number or if you want to specify two different numbers for ASCS and SCS instance.
NW_SCS_Instance.instanceNumber = 00

# Dual stack only: The SCS instance number. Leave empty for default.
# NW_SCS_Instance.scsInstanceNumber =

# The (A)SCS message server port. Leave empty for default.
# NW_SCS_Instance.scsMSPort =

# You can specify a virtual host name for the ASCS instance. Leave empty for default.
NW_SCS_Instance.scsVirtualHostname = ascs1

# SAP INTERNAL USE ONLY
# NW_System.installSAPHostAgent = true

# DEPRECATED, DO NOT USE!
# NW_Unpack.dbaToolsSar =

# DEPRECATED, DO NOT USE!
# NW_Unpack.igsExeSar =

# DEPRECATED, DO NOT USE!
# NW_Unpack.igsHelperSar =

# DEPRECATED, DO NOT USE!
# NW_Unpack.sapExeDbSar =

# DEPRECATED, DO NOT USE!
NW_Unpack.sapExeSar = /sapbits/SAPEXE_200-80002573.SAR

# DEPRECATED, DO NOT USE!
# NW_Unpack.sapJvmSar =

# DEPRECATED, DO NOT USE!
# NW_Unpack.xs2Sar =

# SAP INTERNAL USE ONLY
# NW_adaptProfile.templateFiles =

# The FQDN of the system
# NW_getFQDN.FQDN =

# Specify whether you want to set FQDN for the system.
NW_getFQDN.setFQDN = false

# The ASP device name where the SAP system will be in installed. The property is IBM i only.
# Values from 1 to 256 can be specified. The default is 1, the System ASP.
# OS4.DestinationASP =

# The folder containing all archives that have been downloaded from http://support.sap.com/swdc and are supposed to be used in this procedure
# archives.downloadBasket =

# Windows only: The domain of the SAP Host Agent user
# hostAgent.domain =

# Password for the 'sapadm' user of the SAP Host Agent
hostAgent.sapAdmPassword = des24(151|174|40|210|8|12|209|157|98|106|194|247|230|117|97|90|154|104|186|)

# Windows only: The domain of all users of this SAP system. Leave empty for default.
# nwUsers.sapDomain =

# Windows only: The password of the 'SAPServiceSID' user
# nwUsers.sapServiceSIDPassword =

# UNIX only: The user ID of the 'sapadm' user, leave empty for default. The ID is ignored if the user already exists.
nwUsers.sapadmUID = 1050

# UNIX only: The group id of the 'sapsys' group, leave empty for default. The ID is ignored if the group already exists.
nwUsers.sapsysGID = 1001

# UNIX only: The user id of the <sapsid>adm user, leave empty for default. The ID is ignored if the user already exists.
nwUsers.sidAdmUID = 1040

# The password of the '<sapsid>adm' user
nwUsers.sidadmPassword = des24(151|174|40|210|8|12|209|157|98|106|194|247|230|117|97|90|154|104|186|)

EOF  
}

install_ascs() {
  P_ISPRIMARY=$1
  P_VMNAME=$3
  P_OTHERVMNAME=$4 

  echo "setup cluster"
  echo "P_ISPRIMARY:" $P_ISPRIMARY >> /tmp/variables.txt
  echo "P_VMNAME:" $P_VMNAME>> /tmp/variables.txt
  echo "P_OTHERVMNAME:" $P_OTHERVMNAME>> /tmp/variables.txt


  if [ "$P_ISPRIMARY" = "yes" ]; then
  echo "setup ascs"
 
  #/sapbits/SWPM10SP23_1/sapinst
  else
  echo "setup ers"
  #/sapbits/SWPM10SP23_1/sapinst
  #profile directory /sapmnt/SID/profile
  fi
}


##end of bash function definitions


register_subscription "$SUBEMAIL"  "$SUBID" "$SUBURL"

#get the VM size via the instance api
VMSIZE=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2017-08-01&format=text"`

#install hana prereqs
echo "installing packages"
retry 5 "zypper update -y"
retry 5 "zypper install -y -l sle-ha-release fence-agents" 
retry 5 "zypper install -y unrar"

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
$NFSILBIP nfsnfslb
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
    #wget $REPOURI/waitfor.sh
    #chmod u+x waitfor.sh

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

#!/bin/bash
echo "logicalvol start" >> /tmp/parameter.txt
  nfslun="$(lsscsi 5 0 0 0 | grep -o '.\{9\}$')"
  pvcreate $nfslun
  vgcreate vg_ASCS $nfslun 
  lvcreate -l 100%FREE -n lv_ASCS vg_ASCS 
echo "logicalvol end" >> /tmp/parameter.txt

mkdir /sapbits
mkfs -t xfs  /dev/vg_ASCS/lv_ASCS 
 mount -t xfs /dev/vg_ASCS/lv_ASCS /sapbits
echo "/dev/vg_ASCS/lv_ASCS /sapbits xfs defaults 0 0" >> /etc/fstab

mkdir /sapmnt
#we should be mounting /usr/sap instead
mount -t nfs4 nfsnfslb:/NWS/sapmntH10 /sapmnt

echo "nfsnfslb:/NWS/sapmntH10 /sapmnt nfs4 defaults 0 0" >> /etc/fstab

mkdir -p /usr/sap/$HANASID/{ASCS00,D02,DVEBMGS01,ERS10,SYS} 
mount -t nfs nfsnfslb:/NWS/ASCS /usr/sap/$HANASID/SYS
echo "nfsnfslb:/NWS/ASCS /usr/sap/$HANASID/SYS nfs4 defaults 0 0" >> /etc/fstab

cd /sapbits
download_sapbits $URI
create_temp_swapfile "/sapbits/tempswap" 2000000
write_ascs_ini_file 
install_ascs "$ISPRIMARY" "$VMNAME" "$OTHERVMNAME"