#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

echo "deleting hana servers"
VM1DISK=`az vm show --resource-group $rgname --name $HANAVMNAME1  --query storageProfile.osDisk.managedDisk.id`
az vm delete --yes --resource-group $rgname --name $HANAVMNAME1
VM2DISK=`az vm show --resource-group $rgname --name $HANAVMNAME2  --query storageProfile.osDisk.managedDisk.id`
az vm delete --yes --resource-group $rgname --name $HANAVMNAME2
az disk delete --yes --ids $VM1DISK
az disk delete --yes --ids $VM2DISK
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-backup1
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-backup2
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-data1
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-data2
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-data3
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-log1
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-log2
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-sap
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-shared
az network nic delete --resource-group $rgname --name $HANAVMNAME1-static
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-backup1
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-backup2
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-data1
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-data2
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-data3
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-log1
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-log2
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-sap
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-shared
az network nic delete --resource-group $rgname --name $HANAVMNAME2-static

echo "hana servers deleted"