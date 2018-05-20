#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

az account set --subscription $subscriptionid

echo "creating nfs cluster"
az group deployment create \
--name NFSDeployment \
--resource-group $rgname \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-nfs-service/azuredeploy-nfs-sw.json" \
   --parameters \
   VMName1=$NFSVMNAME1 \
   VMName2=$NFSVMNAME2 \
   VMUserName="testuser" \
   VMPassword=$vmpassword \
   StaticIP1=$NFSIP1 \
   StaticIP2=$NFSIP2 \
   IQN="$IQN1" \
   IQNClient1="$IQN1CLIENT1" \
   IQNClient2="$IQN1CLIENT2" \
   iSCSIIP=$ISCSIIP \
   ILBIP=$NFSILBIP
