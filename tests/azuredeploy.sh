echo "Reading config...." >&2
source ./azuredeploy.cfg

az account set --subscription $subscriptionid

#sh ./vnet-inf.sh
#sh ./ntp-inf.sh
#sh ./ntp-sw.sh
#sh ./iscsi-inf.sh
#sh ./iscsi-sw.sh
#sh ./hana-inf.sh
#sh ./hana-sw.sh
#sh ./nfs-inf.sh
#sh ./nfs-sw.sh
sh ./ascs-inf.sh
sh ./ascs-sw.sh