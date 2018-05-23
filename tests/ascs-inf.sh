#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

az account set --subscription $subscriptionid

echo "creating ascs cluster"
az group deployment create \
--name ASCSDeployment \
--resource-group $rgname \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-ascs-cluster/azuredeploy-ascs-infra.json" \
   --parameters prefix=ascs \
   VMName1=$ASCSVMNAME1 \
   VMName2=$ASCSVMNAME2 \
   VMSize="Standard_D2s_v3" \
   vnetName=$vnetname \
   SubnetName=$appsubnetname \
   VMUserName="testuser" \
   VMPassword=$vmpassword \
   OperatingSystem="SLES for SAP 12 SP2" \
   ExistingNetworkResourceGroup=$rgname \
   StaticIP1=$ASCSIP1 \
   StaticIP2=$ASCSIP2 \
   iSCSIIP=$ISCSIIP \
   ILBIP=$ASCSILBIP
