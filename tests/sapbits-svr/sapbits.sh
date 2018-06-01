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

  cd  /srv/nfs/NWS/SapBits

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
  retry 5 "wget $URI/SapBits/70SWPM10SP23_1-20009701.sar"
  retry 5 "wget $URI/SapBits/SAPCAR_1014-80000935.EXE"
  retry 5 "wget $URI/SapBits/SWPM20SP00_2-80003424.SAR"
}

#!/bin/bash
  nfslun="$(lsscsi 5 0 0 0 | grep -o '.\{9\}$')"
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
