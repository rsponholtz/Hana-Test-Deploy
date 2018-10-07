#!/bin/bash

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi


echo "deleting iscsi server"
az vm delete --yes --resource-group $rgname --name iscsiserver   

echo "iscsi server deleted"
