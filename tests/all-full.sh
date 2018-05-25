echo "Reading config...." >&2
source ./azuredeploy.cfg

./vnet-full.sh
./ntp-full.sh
./iscsi-full.sh
./hana-full.sh
./nfs-full.sh
./ascs-full.sh

