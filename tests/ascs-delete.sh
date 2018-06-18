#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

echo "deleting ascs servers"
az vm delete --yes --resource-group $rgname --name $ASCSVMNAME1
az vm delete --yes --resource-group $rgname --name $ASCSVMNAME2
az disk delete --yes --resource-group $rgname --name $ASCSVMNAME1-data
az network nic delete --resource-group $rgname --name $ASCSVMNAME1-static
az disk delete --yes --resource-group $rgname --name $ASCSVMNAME2-data
az network nic delete --resource-group $rgname --name $ASCSVMNAME2-static
echo "ascs servers deleted"