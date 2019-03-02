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
NWPWD=${2}
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
$ASCS1IP=$[19]
$ASCS2IP=$[20]
$ASCS1VM=$[21]
$ASCS2VM=$[22]


echo "nwserver.sh receiving:"
echo "USRNAME:" $USRNAME >> /tmp/variables.txt
echo "NWPWD:" $ASCSPWD >> /tmp/variables.txt
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
echo "ASCS1IP:" $ASCS1IP >> /tmp/variables.txt
echo "ASCS2IP:" $ASCS2IP >> /tmp/variables.txt
echo "ASCS1VM:" $ASCS1VM >> /tmp/variables.txt
echo "ASCS2VM:" $ASCS2VM >> /tmp/variables.txt

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

download_if_needed() {
  P_DESTDIR=${1}
  P_SOURCEDIR=${2}
  P_FILENAME=${3}

  DESTFILE="$P_DESTDIR/$P_FILENAME"
  SOURCEFILE="$P_SOURCEDIR/$P_FILENAME"
  test -e $DESTFILE
  RESULT=$?
  if [ "$RESULT" = "1" ]; then
    #need to download the file
    retry 5 "wget --quiet -O $DESTFILE $SOURCEFILE"
  fi
}

declare -fxr register_subscription

create_temp_swapfile() {
  P_SWAPNAME=$1
  P_SWAPSIZE=$2
  
  dd if=/dev/zero of=$P_SWAPNAME bs=1024 count=$P_SWAPSIZE
  chown root:root $P_SWAPNAME
  chmod 0600 $P_SWAPNAME
  mkswap $P_SWAPNAME
  swapon $P_SWAPNAME
}

declare -fxr create_temp_swapfile

download_sapbits() {
  URI=$1
  SBDIR=$2

  test -e $SBDIR/download_nwsapbits_complete.txt
  RESULT=$?
  echo $RESULT
  if [ "$RESULT" = "1" ]; then
    #need to download the sap bits
    cd  $SBDIR

    download_if_needed  "$SBDIR" "$URI/SapBits" "51050423_3.ZIP"
    download_if_needed  "$SBDIR" "$URI/SapBits" "51050829_JAVA_part1.exe"   
    download_if_needed  "$SBDIR" "$URI/SapBits" "51050829_JAVA_part2.rar" 
    download_if_needed  "$SBDIR" "$URI/SapBits" "51052190_part1.exe"
    download_if_needed  "$SBDIR" "$URI/SapBits" "51052190_part2.rar"
    download_if_needed  "$SBDIR" "$URI/SapBits" "51052190_part3.rar"
    download_if_needed  "$SBDIR" "$URI/SapBits" "51052190_part4.rar"
    download_if_needed  "$SBDIR" "$URI/SapBits" "51052190_part5.rar"
    download_if_needed  "$SBDIR" "$URI/SapBits" "51052318_part1.exe"
    download_if_needed  "$SBDIR" "$URI/SapBits" "51052318_part2.rar"
    download_if_needed  "$SBDIR" "$URI/SapBits" "SAPCAR_1014-80000935.EXE"
    download_if_needed  "$SBDIR" "$URI/SapBits" "SWPM10SP23_1-20009701.SAR"
    download_if_needed  "$SBDIR" "$URI/SapBits" "SAPHOSTAGENT36_36-20009394.SAR"
    download_if_needed  "$SBDIR" "$URI/SapBits" "SAPEXE_200-80002573.SAR"
    download_if_needed  "$SBDIR" "$URI/SapBits" "SAPEXEDB_200-80002572.SAR"

    download_if_needed  "$SBDIR" "$URI/SapBits" "igsexe_5-80003187.sar"
    download_if_needed  "$SBDIR" "$URI/SapBits" "igshelper_17-10010245.sar"
    #unpack some of this
    retry 5 "zypper install -y unrar"

    chmod u+x SAPCAR_1014-80000935.EXE
    ln -s ./SAPCAR_1014-80000935.EXE sapcar

    mkdir SWPM10SP23_1
    cd SWPM10SP23_1
    ../sapcar -xf ../SWPM10SP23_1-20009701.SAR
    cd $SBDIR
    touch $SBDIR/download_nwsapbits_complete.txt
  fi
}

declare -fxr download_sapbits

write_nw_ini_file() {
  P_VMNAME=$1
  P_MASTERPASSWD=${2}
  P_SAPADMUID=${3}
  P_SAPSYSGID=${4}
  P_SIDADMUID=${5}
  P_DBHOST=${6}
  P_DBSID=${7}
  P_DBINSTANCE=${8}
  P_ASCSSID=${9}
  P_ASCSHOST=${10}
  P_NWINSTANCE=${8}

  echo "setup netweaver"
  echo "P_VMNAME:" $P_VMNAME>> /tmp/variables.txt

  cd /silent_install
  cat > /silent_install/nw.params <<EOF
HDB_Schema_Check_Dialogs.schemaName = SAPABAPDB
HDB_Schema_Check_Dialogs.schemaPassword = $P_MASTERPASSWD
NW_CI_Instance.ascsVirtualHostname = $P_ASCSHOST
NW_CI_Instance.ciInstanceNumber = $P_NWINSTANCE
NW_CI_Instance.ciVirtualHostname = $P_VMNAME
NW_CI_Instance.scsVirtualHostname = nw-0
NW_CI_Instance_ABAP_Reports.executeReportsForDepooling = true
NW_GetMasterPassword.masterPwd = $P_MASTERPASSWD
NW_HDB_getDBInfo.systemDbPassword = $P_MASTERPASSWD
NW_Unpack.igsExeSar = /sapbits/igsexe_5-80003187.sar
NW_Unpack.igsHelperSar = /sapbits/igshelper_17-10010245.sar
NW_getFQDN.FQDN = $P_VMNAME.xx.internal.cloudapp.net
NW_getFQDN.setFQDN = false
NW_getLoadType.loadType = SAP
NW_liveCache.useLiveCache = false
NW_readProfileDir.profileDir = /sapmnt/$P_ASCSSID/profile
hostAgent.sapAdmPassword = $P_MASTERPASSWD
nwUsers.sapadmUID = $P_SAPADMUID
nwUsers.sapsysGID = $P_SAPSYSGID
nwUsers.sidAdmUID = $P_SIDADMUID
nwUsers.sidadmPassword = $P_MASTERPASSWD
storageBasedCopy.hdb.instanceNumber = $P_DBINSTANCE
storageBasedCopy.hdb.systemPassword = $P_MASTERPASSWD
EOF
}

declare -fxr write_nw_ini_file

install_nw() {
  P_VMNAME=$1

  echo "install netweaver"
  echo "P_VMNAME:" $P_VMNAME>> /tmp/variables.txt

  echo "setup nw"
  rm -r -f /tmp/sapinst_instdir
  rm -r -f /sapmnt/*
  rm -r -f /usr/sap/S40/SYS/*
  cd /silent_install
  /sapbits/SWPM10SP23_1/sapinst SAPINST_INPUT_PARAMETERS_URL="./nw.params" SAPINST_EXECUTE_PRODUCT_ID="NW_DI:S4HANA1709.CORE.HDB.ABAPHA" SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false
  touch /tmp/nwcomplete.txt
}

declare -fxr install_nw

write_nw_other_ini_file() {
  P_VMNAME=$1
  P_MASTERPASSWD=${2}
  P_SAPADMUID=${3}
  P_SAPSYSGID=${4}
  P_SIDADMUID=${5}
  P_DBHOST=${6}
  P_DBSID=${7}
  P_DBINSTANCE=${8}
  P_ASCSSID=${9}
  P_ASCSHOST=${10}
  P_NWINSTANCE=${11}

  echo "setup netweaver"
  echo "P_VMNAME:" $P_VMNAME>> /tmp/variables.txt

  cd /silent_install
  cat > /silent_install/nw_other.params <<EOF
HDB_Schema_Check_Dialogs.schemaName = SAPABAPDB
HDB_Schema_Check_Dialogs.schemaPassword = $P_MASTERPASSWD
NW_AS.instanceNumber = $P_NWINSTANCE
NW_DI_Instance.virtualHostname = $P_VMNAME
NW_GetMasterPassword.masterPwd = $P_MASTERPASSWD
NW_HDB_getDBInfo.systemDbPassword = $P_MASTERPASSWD
NW_getLoadType.loadType = SAP
NW_readProfileDir.profileDir = /sapmnt/$P_ASCSSID/profile
hostAgent.sapAdmPassword = $P_MASTERPASSWD
nwUsers.sapadmUID = $P_SAPADMUID
nwUsers.sapsysGID = $P_SAPSYSGID
nwUsers.sidAdmUID = $P_SIDADMUID
nwUsers.sidadmPassword = $P_MASTERPASSWD
storageBasedCopy.hdb.instanceNumber = $P_DBSID
storageBasedCopy.hdb.systemPassword = $P_MASTERPASSWD
EOF
}

declare -fxr write_nw_other_ini_file

install_nw_other() {
  P_VMNAME=$1

  echo "install netweaver"
  echo "P_VMNAME:" $P_VMNAME>> /tmp/variables.txt

  echo "setup nw"
  rm -r -f /tmp/sapinst_instdir
  rm -r -f /sapmnt/*
  rm -r -f /usr/sap/S40/SYS/*
  cd /silent_install
  /sapbits/SWPM10SP23_1/sapinst SAPINST_INPUT_PARAMETERS_URL="./nw_other.params" SAPINST_EXECUTE_PRODUCT_ID="NW_DI:S4HANA1709.CORE.HDB.ABAPHA" SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false
  touch /tmp/nwcomplete.txt
}

declare -fxr install_nw
##end of bash function definitions

register_subscription "$SUBEMAIL"  "$SUBID" "$SUBURL"

#get the VM size via the instance api
VMSIZE=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2017-08-01&format=text"`

#install hana prereqs
echo "installing packages"
#retry 5 "zypper update -y"
retry 5 "zypper install -y -l sle-ha-release fence-agents" 
retry 5 "zypper install -y unrar"

# step2
echo $URI >> /tmp/url.txt

# updat the hosts file
cat >>/etc/hosts <<EOF
$VMIPADDR $VMNAME
$OTHERIPADDR $OTHERVMNAME
$NFSILBIP nfsnfslb
$ASCS1IP ASCS1VM
$ASCS2IP ASCS2VM
EOF

# Restart ascd and ers
systemctl restart ascs
systemctl restart ers

###################
mkdir /localstore
#this is for local sapbits
mkfs -t xfs  /dev/vg_NW/lv_NW 
mount -t xfs /dev/vg_NW/lv_NW /localstore
echo "/dev/vg_NW/lv_NW /localstore xfs defaults 0 0" >> /etc/fstab
#################

# make the sapbits directory and mount it
mkdir /sapbits
mount -t nfs4 nfsnfslb:/NWS/SapBits /sapbits
echo "nfsnfslb:/NWS/SapBits /sapbits nfs4 defaults 0 0" >> /etc/fstab

mkdir /sapmnt
#we should be mounting /usr/sap instead
mount -t nfs4 nfsnfslb:/NWS/sapmntH10 /sapmnt

cd /sapbits
download_sapbits $URI /sapbits
touch /tmp/sapbitsdownloaded.txt
create_temp_swapfile "/localstore/tempswap" 2000000

groupadd -g 1000 sapinst
groupadd -g 1001 sapsys
usermod -a -G sapinst root
usermod -a -G sapsys root

zypper install -y saptune
saptune solution apply NETWEAVER
saptune daemon start

mkdir /silent_install
cd /silent_install
chown root:sapinst /silent_install
chmod g+rwx /silent_install
chmod o+rx /silent_install

if [ "$ISPRIMARY" = "yes" ]; then
  write_nw_ini_file "$VMNAME"
  P_MASTERPASSWD=${2}
  P_SAPADMUID=${3}
  P_SAPSYSGID=${4}
  P_SIDADMUID=${5}
  P_DBHOST=${6}
  P_DBSID=${7}
  P_DBINSTANCE=${8}
  P_ASCSSID=${9}
  P_HOSTNAME=${10}
  P_NWINSTANCE



  install_nw  "$VMNAME" 
else
  write_nw_other_ini_file "$VMNAME"
  install_other_nw  "$VMNAME" 
fi

