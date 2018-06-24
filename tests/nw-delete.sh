#!/bin/bash
set -x
echo "Reading config...." >&2
source ./azuredeploy.cfg

echo "deleting netweaver cluster"

for (( c=0; c<$NWVMCOUNT; c++ ))
do  
   az vm delete --yes --resource-group $rgname --name $NWVMNAME-$c
   az network nic delete --resource-group $rgname --name $NWVMNAMEnic-$c
done
echo "netweaver cluster deleted"
