#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

az account set --subscription $subscriptionid

echo "deleting hana servers"
az vm delete --yes --resource-group $rgname --name $HANAVMNAME1
az vm delete --yes --resource-group $rgname --name $HANAVMNAME2
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-backup1
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-data1
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-data2
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-sap
az disk delete --yes --resource-group $rgname --name $HANAVMNAME1-shared
az network nic delete --resource-group $rgname --name $HANAVMNAME1-static
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-backup1
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-data1
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-data2
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-sap
az disk delete --yes --resource-group $rgname --name $HANAVMNAME2-shared
az network nic delete --resource-group $rgname --name $HANAVMNAME2-static
