echo "Reading config...." >&2
source ./azuredeploy.cfg

./hana-delete.sh
./hana-inf.sh
./hana-sw.sh

