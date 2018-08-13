#!/bin/bash
set -x
echo "Reading config...." >&2
source ./azuredeploy.cfg

echo "creating ascs cluster"
az group deployment create \
--name ASCSDeployment \
--resource-group $rgname \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-ascs-cluster/azuredeploy-ascs-infra.json" \
   --parameters prefix=ascs \
   VMName1=$ASCSVMNAME1 \
   VMName2=$ASCSVMNAME2 \
   VMSize="Standard_DS3_v2" \
   vnetName="$vnetname" \
   SubnetName="$appsubnetname" \
   VMUserName="$vmusername" \
   VMPassword="$vmpassword" \
   OperatingSystem="SLES for SAP 12 SP3" \
   ExistingNetworkResourceGroup="$rgname" \
   StaticIP1="$ASCSIP1" \
   StaticIP2="$ASCSIP2" \
   iSCSIIP="$ISCSIIP" \
   ASCSLBIP="$ASCSLBIP" \
   ERSLBIP="$ERSLBIP" \
   SubscriptionEmail="${slesemail}" \
   SubscriptionID="$slesreg" \
   SMTUri="$slessmt"


echo "ascs cluster created"
