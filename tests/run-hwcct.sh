#!/bin/bash
set -x

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    URI=${1}
else
    source ./azuredeploy.cfg
    URI="$customuri"
fi

if [ "${URI}" != "" ]; then
    echo "usage: run-hwcct.sh <uri>"
    exit
fi



mkdir -p /hana/shared/hwcct
cd /hana/shared/hwcct
wget $URI/SapBits/HWCCT_212_5-20011536.SAR
wget $URI/SapBits/SAPCAR_1014-80000935.EXE
chmod u+x ./SAPCAR_1014-80000935.EXE
ln -s ./SAPCAR_1014-80000935.EXE ./sapcar
./sapcar -xf HWCCT_212_5-20011536.SAR
cd hwcct
cat > disktest.json <<EOF
{
        "use_hdb":false,
        "blades":["localhost"],
        "tests": [{
                "package": "FilesystemTest",
                "test_timeout": 0,
                "id": 2,
                "config": {
                        "mount":{"hana1":["/hana/data"]},
                        "duration":"short"
                        },
                        "class": "DataVolumeIO"
        }],
"output_dir":"/hana/shared/hwcct_outputDir"
}

EOF
cat > logtest.json <<EOF
{
"use_hdb":false,
"blades":["localhost"],
"tests": [{
"package": "FilesystemTest",
"test_timeout": 0,
"id": 3,
"config": {
"mount":{"hana1":["/hana/log"]},
"duration":"short"
},
"class": "LogVolumeIO"
}],
"output_dir":"/hana/shared/hwcct_outputDir"
}

EOF
. ./envprofile.sh
./hwval -f ./disktest.json
./hwval -f ./logtest.json
