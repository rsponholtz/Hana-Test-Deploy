#!/bin/bash
set -x
# store arguments in a special array
args=("$@")
# get number of elements
ELEMENTS=${#args[@]}

# echo each element in array
# for loop
for (( i=0;i<$ELEMENTS;i++)); do
    echo "ARG[${i}]: ${args[${i}]}"
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
ASCSLBIP=${14}
ERSLBIP=${15}
SUBEMAIL=${16}
SUBID=${17}
SUBURL=${18}
NFSILBIP=${19}
ASCSSID=${20}
ASCSINSTANCE=${21}
SAPINSTGID=${22}
SAPSYSGID=${23}
SAPADMUID=${24}
SIDADMUID=${25}
SAPPASSWD=${26}
ERSINSTANCE=${27}
DBHOST=${28}
DBIP=${29}
DBINSTANCE=${30}
ASCSLBIP=${31}
CONFIGURESAP=${32}
CONFIGURECRM=${33}
CONFIGURESCHEMA=${34}
SAPBITSMOUNT=${35} 
SAPMNTMOUNT=${36}
USRSAPSIDMOUNT=${37}
SAPTRANSMOUNT=${38}
USRSAPASCSMOUNT=${39}
USRSAPERSMOUNT=${40}
SAPSOFTWARETODEPLOY=${41}
use_anf=${42}

###
# cluster tuning values
WATCHDOGTIMEOUT="30"
MSGWAITTIMEOUT="60"
STONITHTIMEOUT="150s"
#

echo "small.sh receiving:"
echo "USRNAME: ${USRNAME}" >> /tmp/variables.txt
echo "ASCSPWD: ${ASCSPWD}" >> /tmp/variables.txt
echo "VMNAME: ${VMNAME}" >> /tmp/variables.txt
echo "OTHERVMNAME: ${OTHERVMNAME}" >> /tmp/variables.txt
echo "VMIPADDR: ${VMIPADDR}" >> /tmp/variables.txt
echo "OTHERIPADDR: ${OTHERIPADDR}" >> /tmp/variables.txt
echo "ISPRIMARY: ${ISPRIMARY}" >> /tmp/variables.txt
echo "URI: ${URI}" >> /tmp/variables.txt
echo "HANASID: ${HANASID}" >> /tmp/variables.txt
echo "REPOURI: ${REPOURI}" >> /tmp/variables.txt
echo "ISCSIIP: ${ISCSIIP}" >> /tmp/variables.txt
echo "IQN: ${IQN}" >> /tmp/variables.txt
echo "IQNCLIENT: ${IQNCLIENT}" >> /tmp/variables.txt
echo "ASCSLBIP: ${ASCSLBIP}" >> /tmp/variables.txt
echo "ERSLBIP: ${ERSLBIP}" >> /tmp/variables.txt
echo "SUBEMAIL: ${SUBEMAIL}" >> /tmp/variables.txt
echo "SUBID: ${SUBID}" >> /tmp/variables.txt
echo "SUBURL: ${SUBURL}" >> /tmp/variables.txt
echo "NFSILBIP: ${NFSILBIP}" >> /tmp/variables.txt
echo "ASCSSID: ${ASCSSID}" >> /tmp/variables.txt
echo "ASCSINSTANCE: ${ASCSINSTANCE}" >> /tmp/variables.txt
echo "SAPINSTGID: ${SAPINSTGID}" >> /tmp/variables.txt
echo "SAPSYSGID: ${SAPSYSGID}" >> /tmp/variables.txt
echo "SAPADMUID: ${SAPADMUID}" >> /tmp/variables.txt
echo "SIDADMUID: ${SIDADMUID}" >> /tmp/variables.txt
echo "SAPPASSWD: ${SAPPASSWD}" >> /tmp/variables.txt
echo "ERSINSTANCE: ${ERSINSTANCE}" >> /tmp/variables.txt
echo "DBHOST: ${DBHOST}" >> /tmp/variables.txt
echo "DBIP: ${DBIP}" >> /tmp/variables.txt
echo "DBINSTANCE: ${DBINSTANCE}" >> /tmp/variables.txt
echo "ASCSLBIP: ${ASCSLBIP}" >> /tmp/variables.txt
echo "CONFIGURESAP: ${CONFIGURESAP}" >> /tmp/variables.txt
echo "CONFIGURECRM: ${CONFIGURECRM}" >> /tmp/variables.txt
echo "CONFIGURESCHEMA: ${CONFIGURESCHEMA}" >> /tmp/variables.txt
echo "SAPBITSMOUNT: ${SAPBITSMOUNT}" >> /tmp/variables.txt
echo "SAPMNTMOUNT: ${SAPMNTMOUNT}" >> /tmp/variables.txt
echo "USRSAPSIDMOUNT: ${USRSAPSIDMOUNT}" >> /tmp/variables.txt
echo "SAPTRANSMOUNT: ${SAPTRANSMOUNT}" >> /tmp/variables.txt
echo "USRSAPASCSMOUNT: ${USRSAPASCSMOUNT}" >> /tmp/variables.txt
echo "USRSAPERSMOUNT: ${USRSAPERSMOUNT}" >> /tmp/variables.txt
echo "SAPSOFTWARETODEPLOY: ${SAPSOFTWARETODEPLOY}" >> /tmp/variables.txt
echo "use_anf: ${use_anf}" >> /tmp/variables.txt

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
        expected_votes: 2
        two_node: 1
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

remove_temp_swapfile() {
  P_SWAPNAME=$1

  swapoff $P_SWAPNAME
  rm -f $P_SWAPNAME
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

    crm configure property stonith-timeout=144
    crm configure property stonith-enabled=true

    sudo crm resource stop stonith-sbd
    sudo crm configure delete stonith-sbd
    sudo crm configure primitive stonith-sbd stonith:external/sbd \
      params pcmk_delay_max="15" op monitor interval="15" timeout="15"

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
  SBDIR=$2

  case "$SAPSOFTWARETODEPLOY" in
    'S4 1709')
      filelist=( "51050423_3.ZIP" "51050829_JAVA_part1.exe" "51050829_JAVA_part2.rar" "51052190_part1.exe" "51052190_part2.rar" \
        "51052190_part3.rar"  "51052190_part4.rar"  "51052190_part5.rar"   "51052318_part1.exe"  "51052318_part2.rar"  \
        "SAPCAR_1014-80000935.EXE" "SWPM10SP23_1-20009701.SAR"   "SAPHOSTAGENT36_36-20009394.SAR"  "SAPEXE_200-80002573.SAR" \
        "SAPEXEDB_200-80002572.SAR" )
      swpmsar="SWPM10SP23_1-20009701.SAR"
      swpmdir="SWPM10SP23_1"
      ;;
    'S4 1809')
      filelist=( 51053061_part1.exe 51053061_part2.rar 51053061_part3.rar 51053061_part4.rar 51053381_part1.exe 51053381_part2.rar \
        51053381_part3.rar 51053381_part4.rar 51053787.ZIP igsexe_7-80003187.sar igshelper_17-10010245.sar \
        IMDB_CLIENT20_002_83-80002082.SAR IMDB_CLIENT20_003_144-80002082.SAR IMDB_CLIENT20_004_126-80002082.SAR \
        IMDB_SERVER20_024_9-80002031.SAR IMDB_SERVER20_036_0-80002031.SAR IMDB_SERVER20_037_0-80002031.SAR \
        IMDB_SERVER20_040_0-80002031.SAR K-10301INS4CORE.SAR K-10301INS4FND.SAR K-40001INUIBAS001.SAR K-400AGINUIBAS001.SAR \
        K-60011INSRA004.SAR K-74009INSTPI.SAR K-74010INSTPI.SAR K-75301INSAPBASIS.SAR K-75301INSAPBW.SAR K-75301INSAPGWFND.SAR \
        K-75301INSAPUI.SAR K-75302INSAPUI.SAR K-75D01INSAPABA.SAR K-80301INISUT.SAR K-80301INMDGAPPL.SAR K-80301INMDGFND.SAR \
        K-80301INMDGUX.SAR KD75371.SAR KE60857.SAR KE60858.SAR KE60859.SAR KE60860.SAR KITAB9V.SAR S4HANAOP103_ERP_LANG_AR.SAR \
        S4HANAOP103_ERP_LANG_BG.SAR S4HANAOP103_ERP_LANG_CA.SAR S4HANAOP103_ERP_LANG_CS.SAR S4HANAOP103_ERP_LANG_DA.SAR \
        S4HANAOP103_ERP_LANG_DE.SAR S4HANAOP103_ERP_LANG_EL.SAR S4HANAOP103_ERP_LANG_EN.SAR S4HANAOP103_ERP_LANG_ES.SAR \
        S4HANAOP103_ERP_LANG_ET.SAR S4HANAOP103_ERP_LANG_FI.SAR S4HANAOP103_ERP_LANG_FR.SAR S4HANAOP103_ERP_LANG_HE.SAR \
        S4HANAOP103_ERP_LANG_HI.SAR S4HANAOP103_ERP_LANG_HR.SAR S4HANAOP103_ERP_LANG_HU.SAR S4HANAOP103_ERP_LANG_IT.SAR \
        S4HANAOP103_ERP_LANG_JA.SAR S4HANAOP103_ERP_LANG_KK.SAR S4HANAOP103_ERP_LANG_KO.SAR S4HANAOP103_ERP_LANG_LT.SAR \
        S4HANAOP103_ERP_LANG_LV.SAR S4HANAOP103_ERP_LANG_MS.SAR S4HANAOP103_ERP_LANG_NL.SAR S4HANAOP103_ERP_LANG_NO.SAR \
        S4HANAOP103_ERP_LANG_PL.SAR S4HANAOP103_ERP_LANG_PT.SAR S4HANAOP103_ERP_LANG_RO.SAR S4HANAOP103_ERP_LANG_RU.SAR \
        S4HANAOP103_ERP_LANG_SH.SAR S4HANAOP103_ERP_LANG_SK.SAR S4HANAOP103_ERP_LANG_SL.SAR S4HANAOP103_ERP_LANG_SV.SAR \
        S4HANAOP103_ERP_LANG_TH.SAR S4HANAOP103_ERP_LANG_TR.SAR S4HANAOP103_ERP_LANG_UK.SAR S4HANAOP103_ERP_LANG_VI.SAR \
        S4HANAOP103_ERP_LANG_ZF.SAR S4HANAOP103_ERP_LANG_ZH.SAR SAPCAR_1211-80000935.EXE SAPEXE_28-80003386.SAR \
        SAPEXEDB_28-80003385.SAR SAPHOSTAGENT40_40-20009394.SAR SWPM20SP02_7-80003424.SAR )    
      swpmsar="SWPM20SP02_7-80003424.SAR"
      swpmdir="SWPM20SP02_7"
      ;;
    'IDES 1610"')
      ;;
  esac

  test -e $SBDIR/download_complete.txt
  RESULT=$?
  echo $RESULT
  if [ "$RESULT" = "1" ]; then
    #need to download the sap bits
    cd  $SBDIR
    for i in "${filelist[@]}"
    do
      download_if_needed $SBDIR "$URI/SapBits" "${i}"
    done

    #unpack some of this
    retry 5 "zypper install -y unrar"

    chmod u+x SAPCAR_*.EXE
    ln -s ./SAPCAR_*.EXE sapcar

    mkdir $swpmdir
    ln -s $swpmdir swpmdir
    cd $swpmdir
    ../sapcar -xf ../${swpmsar}
    cd $SBDIR
    touch $SBDIR/download_complete.txt
  fi
}

declare -fxr download_sapbits

download_dbbits() {
  URI=$1
  SBDIR=$2

  retry 5 "zypper install -y unrar"
  test -e $SBDIR/dbdownload_complete.txt
  RESULT=$?
  echo $RESULT
  if [ "$RESULT" = "1" ]; then
      #need to download the sap bits
    cd  $SBDIR

  case "$SAPSOFTWARETODEPLOY" in
    'S4 1709')
      filelist=( "51052190_part1.exe" "51052190_part2.rar" "51052190_part3.rar" "51052190_part4.rar" \
        "51052190_part5.rar" "51052318_part1.exe" "51052318_part2.rar" "51052325_part1.exe" \
        "51052325_part2.rar" "51052325_part3.rar" "51052325_part4.rar" )
      swpmsar="SWPM10SP23_1-20009701.SAR"
      swpmdir="SWPM10SP23_1"
      cd  $SBDIR
      for i in "${filelist[@]}"
      do
        download_if_needed $SBDIR "$URI/SapBits" "${i}"
      done

      unrar -o- x 51052325_part1.exe
      unrar -o- x 51052190_part1.exe

      ;;
    'S4 1809')
      filelist=( S4CORE103_INST_EXPORT_10.zip \
        S4CORE103_INST_EXPORT_11.zip S4CORE103_INST_EXPORT_12.zip S4CORE103_INST_EXPORT_13.zip S4CORE103_INST_EXPORT_14.zip \
        S4CORE103_INST_EXPORT_15.zip S4CORE103_INST_EXPORT_16.zip S4CORE103_INST_EXPORT_17.zip S4CORE103_INST_EXPORT_18.zip \
        S4CORE103_INST_EXPORT_19.zip S4CORE103_INST_EXPORT_1.zip S4CORE103_INST_EXPORT_20.zip S4CORE103_INST_EXPORT_2.zip \
        S4CORE103_INST_EXPORT_3.zip S4CORE103_INST_EXPORT_4.zip S4CORE103_INST_EXPORT_5.zip S4CORE103_INST_EXPORT_6.zip \
        S4CORE103_INST_EXPORT_7.zip S4CORE103_INST_EXPORT_8.zip S4CORE103_INST_EXPORT_9.zip  )
      swpmsar="SWPM20SP02_7-80003424.SAR"
      swpmdir="SWPM20SP02_7"
      cd  $SBDIR
      for i in "${filelist[@]}"
      do
        download_if_needed $SBDIR "$URI/SapBits" "${i}"
      done
      ;;
    'IDES 1610"')
      ;;
  esac
  touch $SBDIR/dbdownload_complete.txt
  fi
}

write_ascs_ini_file() {
  P_INIFILE=${1}
  P_ISPRIMARY=${2}
  P_VMNAME=${3}
  P_OTHERVMNAME=${4} 
  P_ASCSSID=${5}
  P_ASCSINSTANCE=${6}
  P_MASTERPASSWD=${7}
  P_SAPADMUID=${8}
  P_SAPSYSGID=${9}
  P_SIDADMUID=${10}

  echo "setup cluster"
  echo "P_ISPRIMARY:" $P_ISPRIMARY >> /tmp/variables.txt
  echo "P_VMNAME:" $P_VMNAME>> /tmp/variables.txt
  echo "P_OTHERVMNAME:" $P_OTHERVMNAME>> /tmp/variables.txt

  cat > $P_INIFILE <<EOF
NW_GetMasterPassword.masterPwd = $P_MASTERPASSWD
NW_GetSidNoProfiles.sid = $P_ASCSSID
NW_SAPCrypto.SAPCryptoFile = /sapbits/SAPEXE_200-80002573.SAR
NW_SCS_Instance.instanceNumber = $P_ASCSINSTANCE
NW_SCS_Instance.scsVirtualHostname = ascsvh
NW_Unpack.sapExeSar = /sapbits/SAPEXE_200-80002573.SAR
NW_getFQDN.setFQDN = false
archives.downloadBasket = /sapbits
hostAgent.sapAdmPassword = $P_MASTERPASSWD
nwUsers.sapadmUID = $P_SAPADMUID
nwUsers.sapsysGID = $P_SAPSYSGID
nwUsers.sidAdmUID = $P_SIDADMUID
nwUsers.sidadmPassword = $P_MASTERPASSWD
EOF
chown root:sapinst $P_INIFILE
chmod g+r $P_INIFILE
}

write_ers_ini_file() {
  P_INIFILE=${1}
  P_ISPRIMARY=${2}
  P_VMNAME=${3}
  P_OTHERVMNAME=${4} 
  P_ASCSSID=${5}
  P_ERSINSTANCE=${6}
  P_MASTERPASSWD=${7}
  P_SAPADMUID=${8}
  P_SAPSYSGID=${9}
  P_SIDADMUID=${10}



  echo "setup cluster"
  echo "P_ISPRIMARY:" $P_ISPRIMARY >> /tmp/variables.txt
  echo "P_VMNAME:" $P_VMNAME>> /tmp/variables.txt
  echo "P_OTHERVMNAME:" $P_OTHERVMNAME>> /tmp/variables.txt

  cat > $P_INIFILE <<EOF
NW_getFQDN.setFQDN = false
NW_readProfileDir.profileDir = /sapmnt/$P_ASCSSID/profile
archives.downloadBasket = /sapbits
hostAgent.sapAdmPassword = $P_MASTERPASSWD
nwUsers.sapadmUID = $P_SAPADMUID
nwUsers.sapsysGID = $P_SAPSYSGID
nwUsers.sidAdmUID = $P_SIDADMUID
nwUsers.sidadmPassword = $P_MASTERPASSWD
nw_instance_ers.ersInstanceNumber = $P_ERSINSTANCE
nw_instance_ers.ersVirtualHostname = ersvh
EOF
chown root:sapinst $P_INIFILE
chmod g+r $P_INIFILE
}

write_db_ini_file() {
  P_INIFILE=${1}
  P_ASCSSID=${2}
  P_MASTERPASSWD=${3}
  P_SAPSYSGID=${4}
  P_SIDADMUID=${5}
  P_DBHOST=${6}
  P_DBSID=${7}
  P_DBINSTANCE=${8}

#we used to use SAPABAPDB for this, now SAPABAP1
  case "$SAPSOFTWARETODEPLOY" in
    'S4 1709')
  cat > $P_INIFILE <<EOF
NW_HDB_DB.abapSchemaName = SAPABAP1
NW_HDB_DB.abapSchemaPassword = $P_MASTERPASSWD
NW_HDB_DB.javaSchemaName = SAPABAP1
NW_HDB_DB.javaSchemaPassword = $P_MASTERPASSWD
NW_ABAP_Import_Dialog.dbCodepage = 4103
NW_ABAP_Import_Dialog.migmonJobNum = 12
NW_ABAP_Import_Dialog.migmonLoadArgs = -c 100000 -rowstorelist /silent_db/rowstorelist.txt
archives.downloadBasket = /sapbits
NW_GetMasterPassword.masterPwd = $P_MASTERPASSWD
NW_HDB_getDBInfo.dbhost = $P_DBHOST
NW_HDB_getDBInfo.dbsid = $P_DBSID
NW_HDB_getDBInfo.instanceNumber = $P_DBINSTANCE
NW_HDB_getDBInfo.systemDbPassword = $P_MASTERPASSWD
NW_HDB_getDBInfo.systemPassword = $P_MASTERPASSWD
NW_Unpack.sapExeDbSar = /sapbits/SAPEXEDB_200-80002572.SAR
NW_getFQDN.setFQDN = false
NW_getLoadType.loadType = SAP
NW_readProfileDir.profileDir = /usr/sap/$P_ASCSSID/SYS/profile
hanadb.landscape.reorg.useParameterFile = DONOTUSEFILE
nwUsers.sapsysGID = $P_SAPSYSGID
nwUsers.sidAdmUID = $P_SIDADMUID
storageBasedCopy.hdb.instanceNumber = $P_DBINSTANCE
storageBasedCopy.hdb.systemPassword = $P_MASTERPASSWD
SAPINST.CD.PACKAGE.EXPORT1 = /sapbits/51052190/DATA_UNITS
SAPINST.CD.PACKAGE.RDBMS-HDB-CLIENT = /sapbits/51052325/DATA_UNITS/HDB_CLIENT_LINUX_X86_64
#HDB_Schema_Check_Dialogs.dropSchema = true
#HDB_Schema_Check_Dialogs.schemaName = SAPABAPDB2
#HDB_Schema_Check_Dialogs.schemaPassword = $P_MASTERPASSWD
NW_readProfileDir.profilesAvailable = true
hdb.create.dbacockpit.user=true

EOF

      ;;
    'S4 1809')
    SIDADMNAME=""
  cat > $P_INIFILE <<EOF
NW_HDB_DB.abapSchemaName = SAPHANADB
NW_HDB_DB.abapSchemaPassword = $P_MASTERPASSWD
NW_HDB_DB.javaSchemaName = SAPHANADB
NW_HDB_DB.javaSchemaPassword = $P_MASTERPASSWD
#HDB_Schema_Check_Dialogs.schemaName = SAPHANADB
#HDB_Schema_Check_Dialogs.schemaPassword = $P_MASTERPASSWD
HDB_Schema_Check_Dialogs.validateSchemaName = false
NW_GetMasterPassword.masterPwd = $P_MASTERPASSWD
NW_HDB_getDBInfo.dbhost = $P_DBHOST
NW_HDB_getDBInfo.dbsid = $P_DBSID
NW_HDB_getDBInfo.instanceNumber = $P_DBINSTANCE
NW_HDB_getDBInfo.systemDbPassword = $P_MASTERPASSWD
NW_HDB_getDBInfo.systemPassword = $P_MASTERPASSWD
NW_HDB_getDBInfo.systemid = $P_DBINSTANCE
NW_Recovery_Install_HDB.extractLocation = /usr/sap/H10/HDB00/backup/data/DB_H10
NW_Recovery_Install_HDB.extractParallelJobs = 19
NW_Recovery_Install_HDB.sidAdmName = $SIDADMNAME
NW_Recovery_Install_HDB.sidAdmPassword = $P_MASTERPASSWD
NW_Unpack.sapExeDbSar = /sapbits/SAPEXEDB_28-80003385.SAR
archives.downloadBasket = /sapbits
NW_getFQDN.setFQDN = false
NW_getLoadType.loadType = SAP
NW_readProfileDir.profileDir = /usr/sap/${P_ASCSSID}/SYS/profile
#archives.downloadBasket = /sapbits/IMDB_CLIENT20_003_144-80002082.SAR
archives.downloadBasket = /sapbits
nwUsers.sapsysGID = $P_SAPSYSGID
nwUsers.sidAdmUID = $P_SIDADMUID
hdb.create.dbacockpit.user=true

EOF

#NW_HDB_DB.abapSchemaName = SAPABAP1
#NW_HDB_DB.abapSchemaPassword = $P_MASTERPASSWD
#NW_HDB_DB.javaSchemaName = SAPABAP1
#NW_HDB_DB.javaSchemaPassword = $P_MASTERPASSWD
#NW_ABAP_Import_Dialog.dbCodepage = 4103
#NW_ABAP_Import_Dialog.migmonJobNum = 12
#NW_ABAP_Import_Dialog.migmonLoadArgs = -c 100000 -rowstorelist /silent_db/rowstorelist.txt
#archives.downloadBasket = /sapbits
#NW_GetMasterPassword.masterPwd = $P_MASTERPASSWD
#NW_HDB_getDBInfo.dbhost = $P_DBHOST
#NW_HDB_getDBInfo.dbsid = $P_DBSID
#NW_HDB_getDBInfo.instanceNumber = $P_DBINSTANCE
#NW_HDB_getDBInfo.systemDbPassword = $P_MASTERPASSWD
#NW_HDB_getDBInfo.systemPassword = $P_MASTERPASSWD
#NW_Unpack.sapExeDbSar = /sapbits/SAPEXEDB_200-80002572.SAR
#NW_getFQDN.setFQDN = false
#NW_getLoadType.loadType = SAP
#NW_readProfileDir.profileDir = /usr/sap/$P_ASCSSID/SYS/profile
#hanadb.landscape.reorg.useParameterFile = DONOTUSEFILE
#nwUsers.sapsysGID = $P_SAPSYSGID
#nwUsers.sidAdmUID = $P_SIDADMUID
#storageBasedCopy.hdb.instanceNumber = $P_DBINSTANCE
#storageBasedCopy.hdb.systemPassword = $P_MASTERPASSWD
#SAPINST.CD.PACKAGE.EXPORT1 = /sapbits/51052190/DATA_UNITS
#SAPINST.CD.PACKAGE.RDBMS-HDB-CLIENT = /sapbits/51052325/DATA_UNITS/HDB_CLIENT_LINUX_X86_64
##HDB_Schema_Check_Dialogs.dropSchema = true
##HDB_Schema_Check_Dialogs.schemaName = SAPABAPDB2
##HDB_Schema_Check_Dialogs.schemaPassword = $P_MASTERPASSWD
#NW_readProfileDir.profilesAvailable = true
#hdb.create.dbacockpit.user=true

      ;;
    'IDES 1610"')
      ;;
  esac

chown root:sapinst $P_INIFILE
chmod g+r $P_INIFILE
}

exec_sapinst() {
  P_SAPINSTFUNC=${1}
  P_INIFILE=${2}
  P_PRODUCTID=${3}
  P_INSTUSER=${4}
  P_INSTHOST=${5}

  echo "run sapinst"
  echo "P_SAPINSTFUNC:" $P_SAPINSTFUNC >> /tmp/variables.txt
  echo "P_INIFILE:" $P_INIFILE>> /tmp/variables.txt
  echo "P_PRODUCTID:" $P_PRODUCTID>> /tmp/variables.txt
  echo "P_INSTUSER:" $P_INSTUSER>> /tmp/variables.txt
  echo "P_INSTHOST:" $P_INSTHOST>> /tmp/variables.txt

  echo "running sapinst for $P_SAPINSTFUNC"
  SILENTDIR="/silent_$P_SAPINSTFUNC"
  mkdir $SILENTDIR
  chown root:sapinst $SILENTDIR
  chmod 775 $SILENTDIR    
  cd $SILENTDIR

  if [ "${P_INSTHOST}" != "" ]; then
    SAPINSTHOST="SAPINST_USE_HOSTNAME=$P_INSTHOST"
  else
    SAPINSTHOST=""
  fi

##  sudo -u $P_INSTUSER bash << EOF
##  cd $SILENTDIR
##  /sapbits/SWPM10SP23_1/sapinst SAPINST_INPUT_PARAMETERS_URL=$P_INIFILE SAPINST_EXECUTE_PRODUCT_ID=$P_PRODUCTID SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false
## EOF
  /sapbits/swpmdir/sapinst SAPINST_INPUT_PARAMETERS_URL=$P_INIFILE SAPINST_EXECUTE_PRODUCT_ID=$P_PRODUCTID SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false $SAPINSTHOST
}

do_zypper_update() {
  #this will update all packages but waagent and msrestazure
  zypper -q list-updates | tail -n +3 | cut -d\| -f3  >/tmp/zypperlist
  cat /tmp/zypperlist  | grep -v "python.*azure*" > /tmp/cleanlist
  cat /tmp/cleanlist | awk '{$1=$1};1' >/tmp/cleanlist2
  cat /tmp/cleanlist2 | xargs -L 1 -I '{}' zypper update -y '{}'
}

##end of bash function definitions


register_subscription "$SUBEMAIL"  "$SUBID" "$SUBURL"

#get the VM size via the instance api
VMSIZE=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2017-08-01&format=text"`

#install hana prereqs
echo "installing packages"
do_zypper_update

retry 5 "zypper install -y -l sle-ha-release fence-agents" 
retry 5 "zypper install -y unrar"

# step2
echo $URI >> /tmp/url.txt

#turn off automatic management of IP addresses on nic
cd /etc/sysconfig/network
cp ifcfg-eth0 ifcfg-eth0.bak
sbdcmd='s/CLOUD_NETCONFIG_MANAGE=.*/CLOUD_NETCONFIG_MANAGE="no"/g'
cat  ifcfg-eth0.bak | sed $sbdcmd  > /etc/sysconfig/network/ifcfg-eth0


cp -f /etc/waagent.conf /etc/waagent.conf.orig
sedcmd="s/ResourceDisk.EnableSwap=n/ResourceDisk.EnableSwap=y/g"
sedcmd2="s/ResourceDisk.SwapSizeMB=0/ResourceDisk.SwapSizeMB=16384/g"
cat /etc/waagent.conf | sed $sedcmd | sed $sedcmd2 > /etc/waagent.conf.new
cp -f /etc/waagent.conf.new /etc/waagent.conf
# we cannot restart the waagent to get the swap configured immediately - that would kill this script

if [ "$ISPRIMARY" = "yes" ]; then
cat >>/etc/hosts <<EOF
$VMIPADDR $VMNAME
$OTHERIPADDR $OTHERVMNAME
$NFSILBIP nfsnfslb
$VMIPADDR ascsvh
$OTHERIPADDR ersvh
$DBIP hanavh
$DBIP $DBHOST
EOF
else
cat >>/etc/hosts <<EOF
$VMIPADDR $VMNAME
$OTHERIPADDR $OTHERVMNAME
$NFSILBIP nfsnfslb
$OTHERIPADDR ascsvh
$VMIPADDR ersvh
$DBIP hanavh
$DBIP $DBHOST
EOF
fi


##external dependency on sshpt
    retry 5 "zypper --non-interactive --no-gpg-checks addrepo https://download.opensuse.org/repositories/openSUSE:/Tools/SLE_12_SP3/openSUSE:Tools.repo"
    retry 5 "zypper --non-interactive --no-gpg-checks refresh"
    retry 5 "zypper install -y python-pip"
    retry 5 "pip install sshpt==1.3.11"
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
retry 5 "iscsiadm -m discovery --type=st --portal=$ISCSIIP"
retry 5 "iscsiadm -m node -T "$IQN" --login --portal=$ISCSIIP:3260"
retry 5 "iscsiadm -m node -p "$ISCSIIP":3260 --op=update --name=node.startup --value=automatic"

sleep 10 
echo "hana iscsi end" >> /tmp/parameter.txt

device="$(lsscsi 6 0 0 0| cut -c59-)"
diskid="$(ls -l /dev/disk/by-id/scsi-* | grep $device)"
sbdid="$(echo $diskid | grep -o -P '/dev/disk/by-id/scsi-3.{32}')"

#initialize sbd on node1
if [ "$ISPRIMARY" = "yes" ]; then
  sbd -d $sbdid  -1 ${WATCHDOGTIMEOUT} -4 ${MSGWAITTIMEOUT}  create
fi

#!/bin/bash [A]
cd /etc/sysconfig
cp -f /etc/sysconfig/sbd /etc/sysconfig/sbd.new

sbdcmd="s#SBD_DEVICE=\"\"SBD_DEVICE=\"$sbdid\"#g"
sbdcmd2='s/SBD_PACEMAKER=.*/SBD_PACEMAKER="yes"/g'
sbdcmd3='s/SBD_STARTMODE=.*/SBD_STARTMODE="always"/g'
cat sbd.new | sed $sbdcmd | sed $sbdcmd2 | sed $sbdcmd3 > /etc/sysconfig/sbd.modified
echo "SBD_WATCHDOG=yes" >>/etc/sysconfigsbd.modified
cp -f /etc/sysconfig/sbd.modified /etc/sysconfig/sbd
echo "hana sbd end" >> /tmp/parameter.txt

echo softdog > /etc/modules-load.d/softdog.conf
modprobe -v softdog
echo "hana watchdog end" >> /tmp/parameter.txt

cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

setup_cluster "$ISPRIMARY" "$sbdid" "$VMNAME" "$OTHERVMNAME" "$ASCSSID-cl"

retry 5 "zypper install -y sap_suse_cluster_connector"

#!/bin/bash
echo "logicalvol start" >> /tmp/parameter.txt
  nfslun="$(lsscsi 5 0 0 0 | grep -o '.\{9\}$')"
  pvcreate $nfslun
  vgcreate vg_ASCS $nfslun 
  lvcreate -l 100%FREE -n lv_ASCS vg_ASCS 
echo "logicalvol end" >> /tmp/parameter.txt


if [ $use_anf == "yes" ]; then
    NFS_VERSION="nfs"
    NFS_OPTIONS="rw,hard,rsize=65536,wsize=65536,vers=3,tcp"
else
    NFS_VERSION="nfs"
    NFS_OPTIONS="nfsvers=4,nosymlink,sync"
fi

if [ "${SAPBITSMOUNT}" != "" ]; then
  mkdir /sapbits
  mount -t ${NFS_VERSION} -o ${NFS_OPTIONS} ${SAPBITSMOUNT} /sapbits
  echo "${SAPBITSMOUNT} /sapbits ${NFS_VERSION} ${NFS_OPTIONS}  0 0" >> /etc/fstab
  SAPBITSDIR="/sapbits"
else
  mkdir -p /hana/data/sapbits
  SAPBITSDIR="/hana/data/sapbits"
  ln -s /sapbits /hana/data/sapbits
fi


mkdir /localstore
#this is for local sapbits
mkfs -t xfs  /dev/vg_ASCS/lv_ASCS 
mount -t xfs /dev/vg_ASCS/lv_ASCS /localstore
echo "/dev/vg_ASCS/lv_ASCS /localstore xfs defaults 0 0" >> /etc/fstab


#configure autofs
echo "/- /etc/auto.direct" >> /etc/auto.master

mkdir /sapbits
mkdir /sapmnt

mkdir -p /sapmnt/${ASCSSID}
mkdir -p /usr/sap/trans
mkdir -p /usr/sap/${ASCSSID}/SYS
mkdir -p /usr/sap/${ASCSSID}/ASCS${ASCSINSTANCE}
mkdir -p /usr/sap/${ASCSSID}/ERS${ERSINSTANCE}

chattr +i /sapbits
chattr +i /sapmnt/${ASCSSID}
chattr +i /usr/sap/trans
chattr +i /usr/sap/${ASCSSID}/SYS
chattr +i /usr/sap/${ASCSSID}/ASCS${ASCSINSTANCE}
chattr +i /usr/sap/${ASCSSID}/ERS${ERSINSTANCE}

# Add the following lines to the file, save and exit

echo "/sapmnt/${ASCSSID} -${NFS_OPTIONS} ${SAPMNTMOUNT}" >> /etc/auto.direct
echo "/usr/sap/trans -${NFS_OPTIONS} ${SAPTRANSMOUNT}" >> /etc/auto.direct
echo "/usr/sap/${ASCSSID}/SYS -${NFS_OPTIONS} ${USRSAPSIDMOUNT}" >> /etc/auto.direct
echo "/usr/sap/${ASCSSID}/ASCS${ASCSINSTANCE} -${NFS_OPTIONS} ${USRSAPASCSMOUNT}" >> /etc/auto.direct
echo "/usr/sap/${ASCSSID}/ERS${ERSINSTANCE} -${NFS_OPTIONS} ${USRSAPERSMOUNT}" >> /etc/auto.direct

systemctl enable autofs
service autofs restart

cd /sapbits

touch /tmp/sapbitsdownloaded.txt
create_temp_swapfile "/localstore/tempswap" 2000000

groupadd -g $SAPINSTGID sapinst
groupadd -g $SAPSYSGID sapsys
usermod -a -G sapinst root
usermod -a -G sapsys root

echo  "$DBIP $DBHOST"  >>/etc/hosts

if [ "$ISPRIMARY" = "yes" ]; then
  #clean out the usr/sap/SID/SYS
  rm -r -f /usr/sap/${ASCSSID}/SYS/exe/uc/linuxx86_64/*
  if [ "${CONFIGURESAP}" = "yes" ]; then 
    #determine the package to install
    case "$SAPSOFTWARETODEPLOY" in
      'S4 1709')
      ;;
      'IDES 1610"')
      ;;
    esac
    download_sapbits $URI /sapbits $SAPSOFTWARETODEPLOY
    write_ascs_ini_file "/tmp/ascs.params" "$ISPRIMARY" "$VMNAME" "$OTHERVMNAME" "$ASCSSID" "$ASCSINSTANCE" "$SAPPASSWD" "$SAPADMUID" "$SAPSYSGID" "$SIDADMUID"
    case "$SAPSOFTWARETODEPLOY" in
      'S4 1709')
      PRODUCT="NW_ABAP_ASCS:S4HANA1709.CORE.HDB.ABAPHA" 
        ;;
      'S4 1809')
       PRODUCT="NW_ABAP_ASCS:S4HANA1809.CORE.HDB.ABAPHA" 
        ;;
      'IDES 1610"')
        ;;
    esac

    exec_sapinst "ascs" "/tmp/ascs.params" $PRODUCT root ascsvh
  fi
  touch /tmp/ascscomplete.txt

crm node online $VMNAME
crm node standby $OTHERVMNAME

SUBNETMASK=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/subnet/0/prefix?api-version=2017-08-01&format=text"`

crm configure primitive vip_${ASCSSID} IPaddr2 \
        params ip="${ASCSLBIP}" cidr_netmask=${SUBNETMASK} \
        op monitor interval="10s" timeout="20s" 

crm configure primitive rsc_nc_${ASCSSID} anything \
     params binfile="/usr/bin/nc" cmdline_options="-l -k 62000" \
     op monitor timeout=20s interval=10 depth=0

# WARNING: Resources nc_NW1_ASCS,nc_NW1_ERS violate uniqueness for parameter "binfile": "/usr/bin/nc"
# Do you still want to commit (y/n)? y

sudo crm configure group g-${ASCSSID}_ERS rsc_nc_${ASCSSID} vip_${ASCSSID}


  download_dbbits $URI /sapbits
  waitfor  root $P_OTHERVMNAME /tmp/erscomplete.txt
  sleep 10m
  if [ "${CONFIGURESAP}" = "yes" ]; then 
    write_db_ini_file  "/tmp/db.params" "$ASCSSID" "$SAPPASSWD" "$SAPSYSGID" "$SIDADMUID" "hanavh" "$HANASID" "$DBINSTANCE"
    if [ "$CONFIGURESCHEMA" = "yes" ]; then

      case "$SAPSOFTWARETODEPLOY" in
        'S4 1709')
        PRODUCT="NW_ABAP_DB:S4HANA1709.CORE.HDB.ABAPHA" 
          ;;
        'S4 1809')
        PRODUCT="NW_ABAP_DB:S4HANA1809.CORE.HDB.ABAPHA" 
          ;;
        'IDES 1610"')
          ;;
      esac

    exec_sapinst "db" "/tmp/db.params" $PRODUCT root ascsvh
   
    fi
  fi
else
  waitfor  root $P_OTHERVMNAME /tmp/ascscomplete.txt
  if [ "${CONFIGURESAP}" = "yes" ]; then
    write_ers_ini_file "/tmp/ers.params" "$ISPRIMARY" "$VMNAME" "$OTHERVMNAME" "$ASCSSID" "$ERSINSTANCE" "$SAPPASSWD" "$SAPADMUID" "$SAPSYSGID" "$SIDADMUID"
      case "$SAPSOFTWARETODEPLOY" in
        'S4 1709')
        PRODUCT="NW_ERS:S4HANA1709.CORE.HDB.ABAPHA" 
          ;;
        'S4 1809')
        PRODUCT="NW_ERS:S4HANA1809.CORE.HDB.ABAPHA" 
          ;;
        'IDES 1610"')
          ;;
      esac

    exec_sapinst "ers" "/tmp/ers.params" $PRODUCT root ersvh

  fi
  touch /tmp/erscomplete.txt
fi


#node1
if [ "$ISPRIMARY" = "yes" ]; then


 crm configure property maintenance-mode="true"   

crm configure delete stonith-sbd

crm configure primitive stonith-sbd stonith:external/sbd \
     params pcmk_delay_max="15" \
     op monitor interval="15" timeout="15"

  crm configure property stonith-timeout=$STONITHTIMEOUT
  
  crm configure primitive stonith-sbd stonith:external/sbd \
     params pcmk_delay_max="15" \
     op monitor interval="15" timeout="15"

crm configure property \$id="cib-bootstrap-options" stonith-enabled=true \
               no-quorum-policy="ignore" \
               stonith-action="reboot" \
               stonith-timeout=$STONITHTIMEOUT

crm configure  rsc_defaults \$id="rsc-options"  resource-stickiness="1000" migration-threshold="5000"

crm configure  op_defaults \$id="op-options"  timeout="600"

 if [ "${CONFIGURECRM}" = "yes" ]; then
 crm configure primitive rsc_sap_${ASCSSID}_ASCS${ASCSINSTANCE} SAPInstance \
 operations \$id=rsc_sap_${ASCSSID}_ASCS${ASCSINSTANCE}-operations \
 op monitor interval=11 timeout=60 on_fail=restart \
 params InstanceName=${ASCSSID}_ASCS${ASCSINSTANCE}_nw1-ascs START_PROFILE="/sapmnt/${ASCSSID}/profile/${ASCSSID}_ASCS00_ascs1" \
 AUTOMATIC_RECOVER=false \
 meta resource-stickiness=5000 failure-timeout=60 migration-threshold=1 priority=10

 crm configure primitive rsc_sap_${ASCSSID}_ERS${ERSINSTANCE} SAPInstance \
 operations \$id=rsc_sap_${ASCSSID}_ERS${ERSINSTANCE}-operations \
 op monitor interval=11 timeout=60 on_fail=restart \
 params InstanceName=${ASCSSID}_ERS${ERSINSTANCE}_nw1-aers START_PROFILE="/sapmnt/${ASCSSID}/profile/${ASCSSID}_ERS${ERSINSTANCE}_ascs2" AUTOMATIC_RECOVER=false IS_ERS=true \
 meta priority=1000

 crm configure modgroup g-${ASCSSID}_ASCS add rsc_sap_${ASCSSID}_ASCS00
 crm configure modgroup g-${ASCSSID}_ERS add rsc_sap_${ASCSSID}_ERS00

 crm configure colocation col_sap_${ASCSSID}_no_both -5000: g-${ASCSSID}_ERS g-${ASCSSID}_ASCS
 crm configure location loc_sap_${ASCSSID}_failover_to_ers rsc_sap_${ASCSSID}_ASCS00 rule 2000: runs_ers_${ASCSSID} eq 1
 crm configure order ord_sap_${ASCSSID}_first_start_ascs Optional: rsc_sap_${ASCSSID}_ASCS00:start rsc_sap_${ASCSSID}_ERS${ERSINSTANCE}:stop symmetrical=false
fi
 crm node online ${ASCSSID}-cl-0
 crm configure property maintenance-mode="false"
fi

remove_temp_swapfile "/localstore/tempswap" 

echo "software deploy completed.  Please check for proper software install"
