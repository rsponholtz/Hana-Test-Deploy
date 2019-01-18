echo "Reading config...." >&2
source ./azuredeploy.cfg

./vnet-full.sh
./jb-inf.sh
./linuxjumpbox-full.sh
#./ntp-full.sh
./iscsi-full.sh
./nfs-full.sh
./hana-full.sh
./ascs-full.sh
./pas-full.sh
./aas-full.sh