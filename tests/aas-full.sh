echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi


#./ascs-delete.sh
./aas-inf.sh
./aas-sw.sh
