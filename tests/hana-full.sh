echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi


./hana-delete.sh
./hana-inf.sh
./hana-sw.sh

