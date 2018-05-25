echo "Reading config...." >&2
source ./azuredeploy.cfg

./ascs-delete.sh
./ascs-inf.sh
./ascs-sw.sh

