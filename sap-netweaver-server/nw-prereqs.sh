!/bin/bash
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

VMNAME=${1}
VMIPADDR=${2}
HANASID=${3}
ASCSLBIP=${4}
ERSLBIP=${5}
SUBEMAIL=${6}

SUBID=${7}
SUBURL=${8}
NFSILBIP=${9}
ASCSSID=${10}
ASCSINSTANCE=${11}
SAPINSTGID=${12}
SAPSYSGID=${13}

SAPADMUID=${14}
SIDADMUID=${15}
SAPPASSWD=${16}
ERSINSTANCE=${17}
DBHOST=${18}
DBIP=${19}
DBINSTANCE=${20}

SAPBITSMOUNT=${21}
SAPMNTMOUNT=${22}
USRSAPSIDMOUNT=${23}
SAPTRANSMOUNT=${24}
USRSAPASCSMOUNT=${25}
USRSAPERSMOUNT=${26}

#

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


register_subscription "$SUBEMAIL"  "$SUBID" "$SUBURL"

#get the VM size via the instance api
VMSIZE=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2017-08-01&format=text"`

#install sap prereqs
echo "installing packages"
#retry 5 "zypper update -y"
retry 5 "zypper install -y unrar"
retry 5 "zypper install -y saptune"

saptune solution apply NETWEAVER
saptune daemon start
# step2
echo $URI >> /tmp/url.txt

cp -f /etc/waagent.conf /etc/waagent.conf.orig
sedcmd="s/ResourceDisk.EnableSwap=n/ResourceDisk.EnableSwap=y/g"
sedcmd2="s/ResourceDisk.SwapSizeMB=0/ResourceDisk.SwapSizeMB=163840/g"
cat /etc/waagent.conf | sed $sedcmd | sed $sedcmd2 > /etc/waagent.conf.new
cp -f /etc/waagent.conf.new /etc/waagent.conf

# we may be able to restart the waagent and get the swap configured immediately
#if you are running this by hand (eg NOT as a custom script extension), do
#systemctl restart waagent

cat >>/etc/hosts <<EOF
$VMIPADDR $VMNAME
$NFSILBIP nfsnfslb
EOF

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

# Add the following lines to the auto.direct file, save and exit

echo "/sapmnt/${ASCSSID} -nfsvers=4,nosymlink,sync ${SAPMNTMOUNT}" >> /etc/auto.direct
echo "/usr/sap/trans -nfsvers=4,nosymlink,sync ${SAPTRANSMOUNT}" >> /etc/auto.direct
echo "/usr/sap/${ASCSSID}/SYS -nfsvers=4,nosymlink,sync ${USRSAPSIDMOUNT}" >> /etc/auto.direct
echo "/usr/sap/${ASCSSID}/ASCS00 -nfsvers=4,nosymlink,sync ${USRSAPASCSMOUNT}" >> /etc/auto.direct
echo "/usr/sap/${ASCSSID}/ERS00 -nfsvers=4,nosymlink,sync ${USRSAPERSMOUNT}" >> /etc/auto.direct

systemctl enable autofs
service autofs restart

cd /sapbits

groupadd -g $SAPINSTGID sapinst
groupadd -g $SAPSYSGID sapsys
usermod -a -G sapinst root
usermod -a -G sapsys root