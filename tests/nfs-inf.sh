#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

az account set --subscription $subscriptionid

echo "creating nfs cluster"
az group deployment create \
--name NFSDeployment \
--resource-group $rgname \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-nfs-service/azuredeploy-nfs-infra.json" \
   --parameters prefix=nfs \
   VMName1=$NFSVMNAME1 \
   VMName2=$NFSVMNAME2 \
   VMSize="Standard_D2s_v3" \
   vnetName=$vnetname \
   SubnetName=$appsubnetname \
   VMUserName="testuser" \
   VMPassword=$vmpassword \
   OperatingSystem="SLES for SAP 12 SP2" \
   ExistingNetworkResourceGroup=$rgname \
   StaticIP1=$NFSIP1 \
   StaticIP2=$NFSIP2 \
   iSCSIIP=$ISCSIIP \
   ILBIP=$NFSILBIP
