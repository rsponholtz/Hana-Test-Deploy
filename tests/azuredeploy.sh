echo "Reading config...." >&2
source ./azuredeploy.cfg

az account set --subscription $subscriptionid

./vnet-inf.sh
./ntp-inf.sh
./ntp-sw.sh
./iscsi-inf.sh
./iscsi-sw.sh
./hana-inf.sh
./hana-sw.sh
./nfs-inf.sh
./nfs-sw.sh
./ascs-inf.sh
./ascs-sw.sh