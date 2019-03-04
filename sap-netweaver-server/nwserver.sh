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


VMNAME=${1}
VMIPADDR=${2}
ISPRIMARY=${3}
URI=${4}
SUBEMAIL=${5}
SUBID=${6}
SUBURL=${7}
NFSILBIP=${8}
ASCS1VM=${9}
ASCS1IP=${10}
ASCS2VM=${11}
ASCS2IP=${12}
MASTERPASSWORD=${13}
SAPADMUID=${14}
SAPSYSGID=${15}
SIDADMUID=${16}
DBHOST=${17}
DBSID=${18}
DBINSTANCE=${19}
ASCSSID=${20}
ASCSHOST=${21}
NWINSTANCE=${22}
ASCSINSTANCE=${23}
ERSINSTANCE=${24}
SAPBITSMOUNT=${25}
SAPMNTMOUNT=${26}
USRSAPSIDMOUNT=${27}
USRSAPASCSMOUNT=${28}
USRSAPERSMOUNT=${29}
SAPINSTGID=${30}
ASCSILBIP=${31}
DBIP=${32}
CONFIGURESAP=${33}

echo "nwserver.sh receiving:"
echo "VMNAME:" $VMNAME >> /tmp/variables.txt
echo "VMIPADDR:" $VMIPADDR >> /tmp/variables.txt
echo "ISPRIMARY:" $ISPRIMARY >> /tmp/variables.txt
echo "URI:" $URI >> /tmp/variables.txt
echo "SUBEMAIL:" $SUBEMAIL >> /tmp/variables.txt
echo "SUBID:" $SUBID >> /tmp/variables.txt
echo "SUBURL:" $SUBURL >> /tmp/variables.txt
echo "NFSILBIP:" $NFSILBIP >> /tmp/variables.txt
echo "ASCS1VM:" $ASCS1VM >> /tmp/variables.txt
echo "ASCS1IP:" $ASCS1IP >> /tmp/variables.txt
echo "ASCS2VM:" $ASCS2VM >> /tmp/variables.txt
echo "ASCS2IP:" $ASCS2IP >> /tmp/variables.txt
echo "MASTERPASSWORD:" $MASTERPASSWORD >> /tmp/variables.txt
echo "SAPADMUID:" $SAPADMUID >> /tmp/variables.txt
echo "SAPSYSGID:" $SAPSYSGID >> /tmp/variables.txt
echo "SIDADMUID:" $SIDADMUID >> /tmp/variables.txt
echo "DBHOST:" $DBHOST >> /tmp/variables.txt
echo "DBSID:" $DBSID >> /tmp/variables.txt
echo "DBINSTANCE:" $DBINSTANCE >> /tmp/variables.txt
echo "ASCSSID:" $ASCSSID >> /tmp/variables.txt
echo "ASCSHOST:" $ASCSHOST >> /tmp/variables.txt
echo "NWINSTANCE:" $NWINSTANCE >> /tmp/variables.txt
echo "ASCSINSTANCE:" $ASCSINSTANCE >> /tmp/variables.txt
echo "ERSINSTANCE:" $ERSINSTANCE >> /tmp/variables.txt
echo "SAPBITSMOUNT:" $SAPBITSMOUNT >> /tmp/variables.txt
echo "SAPMNTMOUNT:" $SAPMNTMOUNT >> /tmp/variables.txt
echo "USRSAPSIDMOUNT:" $USRSAPSIDMOUNT >> /tmp/variables.txt
echo "USRSAPASCSMOUNT:" $USRSAPASCSMOUNT >> /tmp/variables.txt
echo "USRSAPERSMOUNT:" $USRSAPERSMOUNT >> /tmp/variables.txt
echo "SAPINSTGID:" $SAPINSTGID >> /tmp/variables.txt
echo "ASCSILBIP:" $ASCSILBIP >> /tmp/variables.txt
echo "DBIP:" $DBIP >> /tmp/variables.txt
echo "CONFIGURESAP:" $CONFIGURESAP >> /tmp/variables.txt

##

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

create_temp_swapfile() {
  P_SWAPNAME=$1
  P_SWAPSIZE=$2

  dd if=/dev/zero of=$P_SWAPNAME bs=1024 count=$P_SWAPSIZE
  chown root:root $P_SWAPNAME
  chmod 0600 $P_SWAPNAME
  mkswap $P_SWAPNAME
  swapon $P_SWAPNAME
}

remove_temp_swapfile() {
  P_SWAPNAME=$1

  swapoff $P_SWAPNAME
  rm -f $P_SWAPNAME
}


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

update_hostsfile() {
  P_VMNAME=${1}
  P_IPADDR=${2}
#update the hosts file# updat the hosts file
cat >>/etc/hosts <<EOF
$P_IPADDR $P_VMNAME
EOF
}

create_sap_ids() {
  P_SAPINSTGID=${1}
  P_SAPSYSGID=${2}

  groupadd -g ${P_SAPINSTGID} sapinst
  groupadd -g ${P_SAPSYSGID} sapsys
  usermod -a -G sapinst root
  usermod -a -G sapsys root
} 

configure_mounts() {
  P_ASCSSID=${1}
  P_ASCSINSTANCE=${2}
  P_ERSINSTANCE=${3}
  P_SAPBITSMOUNT=${4}
  P_SAPMNTMOUNT=${5}
  P_SAPTRANSMOUNT=${6}
  P_USRSAPSIDMOUNT=${7}
  P_USRSAPASCSMOUNT=${8}
  P_USRSAPERSMOUNT=${9}

  echo "/- /etc/auto.direct" >> /etc/auto.master

  mkdir /sapbits
  mkdir /sapmnt

  mkdir -p /sapmnt/${P_ASCSSID}
  mkdir -p /usr/sap/trans
  mkdir -p /usr/sap/${P_ASCSSID}/SYS
  mkdir -p /usr/sap/${P_ASCSSID}/ASCS${P_ASCSINSTANCE}
  mkdir -p /usr/sap/${P_ASCSSID}/ERS${P_ERSINSTANCE}

  chattr +i /sapbits
  chattr +i /sapmnt/${P_ASCSSID}
  chattr +i /usr/sap/trans
  chattr +i /usr/sap/${P_ASCSSID}/SYS
  chattr +i /usr/sap/${P_ASCSSID}/ASCS${P_ASCSINSTANCE}
  chattr +i /usr/sap/${P_ASCSSID}/ERS${P_ERSINSTANCE}

  # Add the following lines to the auto.direct file, save and exit
  echo "/sapbits -nfsvers=4,nosymlink,sync ${P_SAPBITSMOUNT}" >> /etc/auto.direct
  echo "/sapmnt/${P_ASCSSID} -nfsvers=4,nosymlink,sync ${P_SAPMNTMOUNT}" >> /etc/auto.direct
  echo "/usr/sap/trans -nfsvers=4,nosymlink,sync ${P_SAPTRANSMOUNT}" >> /etc/auto.direct
  echo "/usr/sap/${P_ASCSSID}/SYS -nfsvers=4,nosymlink,sync ${P_USRSAPSIDMOUNT}" >> /etc/auto.direct
  echo "/usr/sap/${P_ASCSSID}/ASCS00 -nfsvers=4,nosymlink,sync ${P_USRSAPASCSMOUNT}" >> /etc/auto.direct
  echo "/usr/sap/${P_ASCSSID}/ERS00 -nfsvers=4,nosymlink,sync ${P_USRSAPERSMOUNT}" >> /etc/auto.direct

  systemctl enable autofs
  service autofs restart  
}

do_zypper_update() {
  #this will update all packages but waagent and msrestazure
  zypper -q list-updates | tail -n +3 | cut -d\| -f3  >/tmp/zypperlist
  cat /tmp/zypperlist  | grep -v "python.*azure*" > /tmp/cleanlist
  cat /tmp/cleanlist | awk '{$1=$1};1' >/tmp/cleanlist2
  cat /tmp/cleanlist2 | xargs -L 1 -I '{}' zypper update -y '{}'
}

nw_prereqs() {
  P_SUBEMAIL=${1}
  P_SUBID=${2}
  P_SUBURL=${3}
  P_ASCSSID=${4}
  P_ASCSINSTANCE=${5}
  P_ERSINSTANCE=${6}
  P_SAPBITSMOUNT=${7}
  P_SAPMNTMOUNT=${8}
  P_USRSAPSIDMOUNT=${9}
  P_USRSAPASCSMOUNT=${10}
  P_USRSAPERSMOUNT=${11}
  P_SAPINSTGID=${12}
  P_SAPSYSGID=${13}
  P_VMIPADDR=${14}
  P_VMNAME=${15}
  P_NFSILBIP=${16}
  P_ASCSLBIP=${17}
  P_DBIP=${18}
  P_DBHOST=${19}

  register_subscription "$P_SUBEMAIL"  "$P_SUBID" "$P_SUBURL"

  #get the VM size via the instance api
  VMSIZE=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2017-08-01&format=text"`

  #install sap prereqs
  echo "installing packages"
  do_zypper_update
  retry 5 "zypper install -y unrar"
  retry 5 "zypper install -y saptune"

  saptune solution apply NETWEAVER
  saptune daemon start
  # step2

  cp -f /etc/waagent.conf /etc/waagent.conf.orig
  sedcmd="s/ResourceDisk.EnableSwap=n/ResourceDisk.EnableSwap=y/g"
  sedcmd2="s/ResourceDisk.SwapSizeMB=0/ResourceDisk.SwapSizeMB=163840/g"
  cat /etc/waagent.conf | sed $sedcmd | sed $sedcmd2 > /etc/waagent.conf.new
  cp -f /etc/waagent.conf.new /etc/waagent.conf

  # we may be able to restart the waagent and get the swap configured immediately
  #if you are running this by hand (eg NOT as a custom script extension), do
  #systemctl restart waagent

  update_hostsfile nfsnfslb $P_NFSILBIP
  update_hostsfile nfsvh $P_NFSILBIP 
  update_hostsfile ascs $P_ASCSLBIP 
  update_hostsfile ascsvh $P_ASCSLBIP  
  update_hostsfile $P_DBHOST $P_DBIP 
  update_hostsfile hanavh $P_DBIP 
  update_hostsfile $VMNAME $VMIPADDR 


  #configure autofs
  configure_mounts ${P_ASCSSID} ${P_ASCSINSTANCE} ${P_ERSINSTANCE} ${P_SAPBITSMOUNT} ${P_SAPMNTMOUNT} ${P_SAPTRANSMOUNT} \
    ${P_USRSAPSIDMOUNT} ${P_USRSAPASCSMOUNT} ${P_USRSAPERSMOUNT}

  create_sap_ids ${P_SAPINSTGID} ${P_SAPSYSGID}

  mkdir /localstore
  create_temp_swapfile "/localstore/tempswap" 2000000

  mkdir /silent_install
  cd /silent_install
  chown root:sapinst /silent_install
  chmod g+rwx /silent_install
  chmod o+rx /silent_install
}


######

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

declare -fxr download_if_needed

download_sapbits() {
  URI=$1
  SBDIR=$2

  test -e $SBDIR/appdownload_complete.txt
  RESULT=$?
  echo $RESULT
  if [ "$RESULT" = "1" ]; then
    #need to download the sap bits
    cd  $SBDIR
    download_if_needed "/sapbits" "$URI/SapBits" "51050423_3.ZIP"
    download_if_needed "/sapbits" "$URI/SapBits" "51050829_JAVA_part1.exe"   
    download_if_needed "/sapbits" "$URI/SapBits" "51050829_JAVA_part2.rar" 
    #retry 5 "wget  --quiet $URI/SapBits/51052190_part1.exe"
    #retry 5 "wget  --quiet $URI/SapBits/51052190_part2.rar"
    #retry 5 "wget  --quiet $URI/SapBits/51052190_part3.rar"
    #retry 5 "wget  --quiet $URI/SapBits/51052190_part4.rar"
    #retry 5 "wget  --quiet $URI/SapBits/51052190_part5.rar"
    download_if_needed "/sapbits" "$URI/SapBits" "51052318_part1.exe"
    download_if_needed "/sapbits" "$URI/SapBits" "51052318_part2.rar"
    download_if_needed "/sapbits" "$URI/SapBits" "SAPCAR_1014-80000935.EXE"
    download_if_needed "/sapbits" "$URI/SapBits" "SWPM10SP23_1-20009701.SAR"
    download_if_needed "/sapbits" "$URI/SapBits" "SAPHOSTAGENT36_36-20009394.SAR"
    download_if_needed "/sapbits" "$URI/SapBits" "SAPEXE_200-80002573.SAR"
    download_if_needed "/sapbits" "$URI/SapBits" "SAPEXEDB_200-80002572.SAR"

    download_if_needed "/sapbits" "$URI/SapBits" "igsexe_5-80003187.sar"
    download_if_needed "/sapbits" "$URI/SapBits" "igshelper_17-10010245.sar"
    #unpack some of this
    #retry 5 "zypper install -y unrar"

    chmod u+x SAPCAR_1014-80000935.EXE
    ln -s ./SAPCAR_1014-80000935.EXE sapcar

    mkdir SWPM10SP23_1
    cd SWPM10SP23_1
    ../sapcar -xf ../SWPM10SP23_1-20009701.SAR
    cd $SBDIR
    touch $SBDIR/appdownload_complete.txt
  fi
}

declare -fxr download_sapbits

write_nw_ini_file() {
  P_VMNAME=${1}
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
  cat > /silent_install/nw.params <<EOF
HDB_Schema_Check_Dialogs.schemaName = SAPABAP1
HDB_Schema_Check_Dialogs.schemaPassword = $P_MASTERPASSWD
NW_CI_Instance.ascsVirtualHostname = $P_VMNAME
NW_CI_Instance.ciInstanceNumber = $P_NWINSTANCE
NW_CI_Instance.ciVirtualHostname = $P_VMNAME
NW_CI_Instance.scsVirtualHostname = $P_VMNAME
NW_CI_Instance_ABAP_Reports.executeReportsForDepooling = true
NW_GetMasterPassword.masterPwd = $P_MASTERPASSWD
NW_HDB_getDBInfo.systemDbPassword = $P_MASTERPASSWD
NW_Unpack.igsExeSar = /sapbits/igsexe_5-80003187.sar
NW_Unpack.igsHelperSar = /sapbits/igshelper_17-10010245.sar
NW_Unpack.sapExeSar = /sapbits/SAPEXE_200-80002573.SAR
NW.Unpack.sapExeDbSar = /sapbits/SAPEXEDB_200-80002572.SAR
SAPINST.CD.PACKAGE.EXPORT1 = /sapbits/51052190/DATA_UNITS
SAPINST.CD.PACKAGE.EXPORT_1 = /sapbits/51052190/DATA_UNITS
SAPINST.CD.PACKAGE.RDBMS-HDB-CLIENT = /sapbits/51052325/DATA_UNITS/HDB_CLIENT_LINUX_X86_64
SAPINST.CD.PACKAGE.HDB_CLIENT = /sapbits/51052325/DATA_UNITS/HDB_CLIENT_LINUX_X86_64
archives.downloadBasket = /sapbits
#NW_checkMsgServer.abapMSPort = 3600
NW_getFQDN.FQDN = $P_VMNAME.xx.internal.cloudapp.net
NW_getFQDN.setFQDN = false
NW_getLoadType.loadType = SAP
NW_liveCache.useLiveCache = false
NW_readProfileDir.profileDir = /usr/sap/$P_ASCSSID/SYS/profile
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
  P_VMNAME=${1}
  P_ISPRIMARY=${2}

  echo "install_nw"
  echo "P_VMNAME:" $P_VMNAME>> /tmp/variables.txt
  echo "P_ISPRIMARY:" $P_ISPRIMARY> /tmp/variables.txt

  if [ "${P_ISPRIMARY}" = "YES" ]; then
    PRODUCT="NW_ABAP_CI:S4HANA1709.CORE.HDB.ABAPHA"
  else
    PRODUCT="NW_DI:S4HANA1709.CORE.HDB.ABAPHA" 
  fi

  echo "setup nw"
  rm -r -f /tmp/sapinst_instdir
  cd /silent_install
  /sapbits/SWPM10SP23_1/sapinst SAPINST_INPUT_PARAMETERS_URL="./nw.params" SAPINST_EXECUTE_PRODUCT_ID="$PRODUCT" \
      SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false
  touch /tmp/nwcomplete.txt
}

declare -fxr install_nw

##end of bash function definitions



nw_prereqs  "$SUBEMAIL" "$SUBID" "$SUBURL" "$ASCSSID" "$ASCSINSTANCE" "$ERSINSTANCE" "$SAPBITSMOUNT" "$SAPMNTMOUNT" "$USRSAPSIDMOUNT" "$USRSAPASCSMOUNT" \
    "$USRSAPERSMOUNT" "$SAPINSTGID" "$SAPSYSGID" "$VMIPADDR" "$VMNAME" "$NFSILBIP" "$ASCSILBIP" "$DBIP" "$DBHOST"
if [ "${CONFIGURESAP}" = "yes" ]; then     
  download_sapbits "$URI" "/sapbits"
  write_nw_ini_file "$VMNAME" "$MASTERPASSWORD" "$SAPADMUID" "$SAPSYSGID" "$SIDADMUID" "$DBHOST" "$DBSID" "$DBINSTANCE" "$ASCSSID" "$ASCSILBIP" "$NWINSTANCE"
  install_nw  "$VMNAME" "$ISPRIMARY" 
fi
