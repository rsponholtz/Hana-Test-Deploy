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

URI=${1}
SAPID=${2}
SAPPASSWD=${3}
DOWNLOADBITSFROM=${4}

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

download_sapbits() {
    URI=$1

  cd  /sapbits
#retry 5 "wget $URI/SapBits/50144807_6.ZIP"
retry 5 "wget $URI/SapBits/51050423_3.ZIP"
retry 5 "wget $URI/SapBits/51050829_JAVA_part1.exe"
retry 5 "wget $URI/SapBits/51050829_JAVA_part2.rar"
retry 5 "wget $URI/SapBits/51052190_part1.exe"
retry 5 "wget $URI/SapBits/51052190_part2.rar"
retry 5 "wget $URI/SapBits/51052190_part3.rar"
retry 5 "wget $URI/SapBits/51052190_part4.rar"
retry 5 "wget $URI/SapBits/51052190_part5.rar"
retry 5 "wget $URI/SapBits/51052318_part1.exe"
retry 5 "wget $URI/SapBits/51052318_part2.rar"
retry 5 "wget $URI/SapBits/51052916.ZIP"
retry 5 "wget $URI/SapBits/51053061_part1.exe"
retry 5 "wget $URI/SapBits/51053061_part2.rar"
retry 5 "wget $URI/SapBits/51053061_part3.rar"
retry 5 "wget $URI/SapBits/51053061_part4.rar"
#retry 5 "wget $URI/SapBits/70SWPM10SP23_1-20009701.sar"
retry 5 "wget $URI/SapBits/HWCCT_212_5-20011536.SAR"
retry 5 "wget $URI/SapBits/igsexe_0-80003187.sar"
retry 5 "wget $URI/SapBits/igsexe_1-80003187.sar"
retry 5 "wget $URI/SapBits/igsexe_2-80003187.sar"
retry 5 "wget $URI/SapBits/igsexe_3-80003187.sar"
retry 5 "wget $URI/SapBits/igsexe_4-80003187.sar"
retry 5 "wget $URI/SapBits/igsexe_5-80003187.sar"
retry 5 "wget $URI/SapBits/igshelper_0-10010245.sar"
retry 5 "wget $URI/SapBits/igshelper_15-10010245.sar"
retry 5 "wget $URI/SapBits/igshelper_17-10010245.sar"
retry 5 "wget $URI/SapBits/igshelper_3-10010245.sar"
retry 5 "wget $URI/SapBits/igshelper_4-10010245.sar"
#retry 5 "wget $URI/SapBits/SAPACEXT_44-20010403"
retry 5 "wget $URI/SapBits/SAPACEXT_44-20010403.SAR"
retry 5 "wget $URI/SapBits/SAPCAR_1014-80000935.EXE"
retry 5 "wget $URI/SapBits/SAPEXE_200-80002573.SAR"
retry 5 "wget $URI/SapBits/SAPEXEDB_200-80002572.SAR"
#retry 5 "wget $URI/SapBits/SAPHOSTAGENT36_36-20009394.SAR"
#retry 5 "wget $URI/SapBits/SAPHOSTAGENT40_40-20009394"
retry 5 "wget $URI/SapBits/SAPHOSTAGENT40_40-20009394.SAR"
retry 5 "wget $URI/SapBits/saprouter_211-80003478.sar"
retry 5 "wget $URI/SapBits/SWPM10SP23_1-20009701.SAR"
#retry 5 "wget $URI/SapBits/SWPM20SP00_2-80003424.SAR"
retry 5 "wget $URI/SapBits/vc_redist.x64.exe"
retry 5 "wget $URI/SapBits/51052822_part01.exe"
retry 5 "wget $URI/SapBits/51052822_part02.rar"
retry 5 "wget $URI/SapBits/51052822_part03.rar"
retry 5 "wget $URI/SapBits/51052822_part04.rar"
retry 5 "wget $URI/SapBits/51052822_part05.rar"
retry 5 "wget $URI/SapBits/51052822_part06.rar"
retry 5 "wget $URI/SapBits/51052822_part07.rar"
retry 5 "wget $URI/SapBits/51052822_part08.rar"
zypper install -y unrar
unrar x 51050829_JAVA_part1.exe
unrar x 51052010_part1.exe
unrar x 51052822_part01.exe
unrar x 51052190_part1.exe

chmod u+x SAPCAR_1014-80000935.EXE
ln -s SAPCAR_1014-80000935.EXE sapcar
mkdir SWPM10SP23_1
cd SWPM10SP23_1
../sapcar -xf ../SWPM10SP23_1-20009701.SAR
cd ..
mkdir IMDB_CLIENT20_002_76-80002082
cd IMDB_CLIENT20_002_76-80002082
../sapcar -xf ../IMDB_CLIENT20_002_76-80002082.SAR
}

#!/bin/bash
  nfslun=/dev/disk/azure/scsi1/lun0
  pvcreate $nfslun
  vgcreate vg_sapbits $nfslun 
  lvcreate -l 100%FREE -n lv_sapbits vg_sapbits 

mkdir /sapbits
mkfs -t xfs  /dev/vg_sapbits/lv_sapbits 
 mount -t xfs /dev/vg_sapbits/lv_sapbits /sapbits
echo "/dev/vg_sapbits/lv_sapbits /sapbits xfs defaults 0 0" >> /etc/fstab

#install hana prereqs
echo "installing packages"
zypper update -y
#set up nfs

echo "/sapbits   *(rw,sync)" >> "/etc/exports"
systemctl restart nfsserver
download_sapbits $URI