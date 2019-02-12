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
SAPSOFTWARETODOWNLOAD=${5}

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

#this function will download a given package to the given location.

#
#verified but not tested
IDES_1610_DOWNLOADS=( "0030000000860202018" "0030000000860222018" "0030000000860232018" "0030000000860242018" \
"0020000002171982018" "0030000009413282017" "0030000009413292017" "0030000009413302017" "0030000009413312017" \
"0030000000233052018" "0030000000233152018" "0030000000233182018" "0030000000233202018" "0030000000233252018" \
"0030000000233312018" "0030000000235422018" "0030000000236392018" "0030000000698812016" "0020000002304082018" \
"0020000002266252018" "0020000001703522018" "0020000019623212017" "0020000018734962017" "0020000000248552019" \
"0020000000222862019" \
)

S4_1709_DOWNLOADS=( )
    
S4_1810_DOWNLOADS=(
"0010000002434002018" "0020000002172162018" "0020000000167912019" "0020000000167822019"
"0010000002434012018" "0010000002434022018" "0010000002434032018" "0020000000159362019"
"0010000000026952019" "0030000001872432018" "0030000001872652018" "0030000001872832018"
"0030000001872972018" "0030000001873122018" "0030000001873222018" "0030000001873272018"
"0030000001873292018" "0030000001873302018" "0030000001873372018" "0030000001873442018"
"0030000001873452018" "0030000001873472018" "0030000001873492018" "0030000001873502018"
"0030000001873512018" "0030000001873572018" "0030000001873642018" "0030000001873732018"
"0030000001873832018" "0010000002433912018" "0030000001873852018" "0030000001873892018"
"0030000001873922018" "0030000001873972018" "0030000001874012018" "0030000001874042018"
"0030000001874062018" "0030000001874092018" "0030000001874152018" "0030000001874172018"
"0030000001874202018" "0030000001874252018" "0030000001874292018" "0030000001874332018"
"0030000001874362018" "0030000001874392018" "0030000001874422018" "0030000001874482018"
"0030000001874562018" "0030000001874612018" "0030000001874632018" "0030000001874662018"
"0030000001874672018" "0030000001874712018" "0030000001874732018" "0030000001874782018"
"0030000001874822018" "0030000001874872018" "0030000001874922018" "0030000001874962018"
"0030000001875002018" "0030000001875042018" "0030000001875062018" "0030000001875082018"
"0030000001875112018" "0030000001875132018" "0030000001875152018" "0030000001875192018"
"0030000001875212018" "0020000002120452018" "0020000000703122018" "0010000002469792018"
"0010000002433642018" "0010000002433652018" "0010000002433662018" "0010000001550262018"
"0010000001782192018" "0010000001976222018" "0010000002091612018" "0010000001783292018"
"0010000002433672018" "0010000000093362019" "0010000002014762018" "0010000002257102018"
"0010000000161692019" "0020000000119332019" "0010000002253762018" "0010000001433022018"
"0010000000003932019"
 )



download_requirements() {
    P_USER=${1}
    shift
    P_PASS=${1}
    shift
    local P_REQUIREMENTS=("$@")
    
for i in "${P_REQUIREMENTS[@]}"
do
    # access each element  
    # as $i
    wget -q --user=$P_USER --password=$P_PASS --content-disposition  https://softwaredownloads.sap.com/file/${i}
    #echo $i 
done

}

declare -fxr download_requirements

download_sapbits_from_sap() 
{
    P_SAPSOFTWARETODOWNLOAD=$1
    P_USER=$2
    P_PASS=$3
    P_SAPBITS=$4

    cd $P_SAPBITS
    if [ "$P_SAPSOFTWARETODOWNLOAD" == "NONE" ]
    then
        return;
    fi

    
    if [ "$P_SAPSOFTWARETODOWNLOAD" == "IDES 1610" ]
    then
        download_requirements $P_USER $P_PASS "${IDES_1610_DOWNLOADS[@]}"
    fi
    if [ "$P_SAPSOFTWARETODOWNLOAD" == "S4 1709" ]
    then
        download_requirements $P_USER $P_PASS "${S4_1709_DOWNLOADS[@]}"
    fi

    # zypper install -y unrar
    # unrar x 51050829_JAVA_part1.exe
    # unrar x 51052010_part1.exe
    # unrar x 51052822_part01.exe
    # unrar x 51052190_part1.exe

    # chmod u+x SAPCAR_1014-80000935.EXE
    # ln -s SAPCAR_1014-80000935.EXE sapcar
    # mkdir SWPM10SP23_1
    # cd SWPM10SP23_1
    # ../sapcar -xf ../SWPM10SP23_1-20009701.SAR
    # cd ..
    # mkdir IMDB_CLIENT20_002_76-80002082
    # cd IMDB_CLIENT20_002_76-80002082
    # ../sapcar -xf ../IMDB_CLIENT20_002_76-80002082.SAR
}

setup_nfs_share() 
{
    P_SAPBITS=$1
    #set up nfs

    echo "$P_SAPBITS   *(rw,sync)" >> "/etc/exports"
    systemctl restart nfsserver
}

setup_http_share()
{
    zypper install -y httpd
    systemctl start apache2.service
}

setup_http_share

#!/bin/bash
nfslun=/dev/disk/azure/scsi1/lun0
pvcreate $nfslun
vgcreate vg_sapbits $nfslun 
lvcreate -l 100%FREE -n lv_sapbits vg_sapbits 

mkfs -t xfs  /dev/vg_sapbits/lv_sapbits 
mkdir /srv/www/htdocs/SapBits
mount -t xfs /dev/vg_sapbits/lv_sapbits /srv/www/htdocs/SapBits
echo "/dev/vg_sapbits/lv_sapbits /srv/www/htdocs/SapBits xfs defaults 0 0" >> /etc/fstab

echo "installing packages"
zypper update -y

setup_nfs_share "/srv/www/htdocs/SapBits"
download_sapbits_from_sap  "$SAPSOFTWARETODOWNLOAD" "$SAPID" "$SAPPASSWD" "/srv/www/htdocs/SapBits"
