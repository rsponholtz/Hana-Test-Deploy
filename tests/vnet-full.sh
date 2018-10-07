#!/bin/bash
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi

echo "creating resource group"
az group delete --name $rgname 

./vnet-inf.sh
