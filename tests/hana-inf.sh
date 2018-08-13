#!/bin/bash
#   VMSize="Standard_E16s_v3 (128 GB)" \
#Standard_M128ms (3.8 TB, Certified)
set -x
echo "Reading config...." >&2
source ./azuredeploy.cfg

#hanavmsize="Standard_E16s_v3 (128 GB)"
#hanavmsize="Standard_M128s (2 TB, Certified)"

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
   OperatingSystem="SLES for SAP 12 SP3" \
   ExistingNetworkResourceGroup="$rgname" \
   StaticIP1=$HANAIP1 \
   StaticIP2=$HANAIP2 \
   iSCSIIP=$ISCSIIP \
   SubscriptionEmail="$slesemail" \
   SubscriptionID="$slesreg" \
   SMTUri="$slessmt" \
   ILBIP=$HANAILBIP

echo "hana cluster created"
