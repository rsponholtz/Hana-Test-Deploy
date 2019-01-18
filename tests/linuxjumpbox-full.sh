echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi


#
./linuxjumpbox-inf.sh
./linuxjumpbox-sw.sh
