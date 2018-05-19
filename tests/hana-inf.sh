#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

echo "creating hana cluster"
az group deployment create \
--name HANADeployment \
--resource-group $rgname \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-hana-cluster/azuredeploy-hsr-infra.json" \
   --parameters \
   VMName1=$HANAVMNAME1 \
   VMName2=$HANAVMNAME2 \
   VMSize="Standard_E16s_v3 (128 GB)" \
   NetworkName=$vnetname \
   HANASubnetName=$dbsubnetname \
   VMUserName=$vmusername \
   VMPassword=$vmpassword \
   OperatingSystem="SLES for SAP 12 SP2" \
   ExistingNetworkResourceGroup="$rgname" \
   StaticIP1=$HANAIP1 \
   StaticIP2=$HANAIP2 \
   iSCSIIP=$ISCSIIP \
   ILBIP=$HANAILBIP
