#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

az account set --subscription $subscriptionid

echo "installing ascs cluster"
az group deployment create \
--name ASCSSWDeployment \
--resource-group $rgname \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-ascs-cluster/azuredeploy-ascs-sw.json" \
   --parameters \
   VMName1=$ASCSVMNAME1 \
   VMName2=$ASCSVMNAME2 \
   VMUserName="testuser" \
   VMPassword=$vmpassword \
   StaticIP1=$ASCSIP1 \
   StaticIP2=$ASCSIP2 \
   IQN="$ASCSIQN" \
   IQNClient1="$ASCSIQNCLIENT1" \
   IQNClient2="$ASCSIQNCLIENT2" \
   iSCSIIP=$ISCSIIP \
   ILBIP=$ASCSILBIP
