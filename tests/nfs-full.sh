echo "Reading config...." >&2
source ./azuredeploy.cfg

./nfs-delete.sh
./nfs-inf.sh
./nfs-sw.sh

