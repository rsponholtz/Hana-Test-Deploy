#!/bin/bash
set -x
echo "Reading config...." >&2

if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi

az account set --subscription "$subscriptionid"

echo "creating ascs cluster"
az group deployment create \
--name ASCSDeployment \
--resource-group $rgname \
   --template-uri "https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2Fsap-ascs-cluster/azuredeploy-ascs-infra.json" \
   --parameters prefix=ascs \
   VMName1=$ASCSVMNAME1 \
   VMName2=$ASCSVMNAME2 \
   VMSize="Standard_DS3_v2" \
   vnetName="$vnetname" \
   SubnetName="$appsubnetname" \
   VMUserName="$vmusername" \
   VMPassword="$vmpassword" \
   OperatingSystem="SLES for SAP 12 SP3" \
   ExistingNetworkResourceGroup="$vnetrgname" \
   StaticIP1="$ASCSIP1" \
   StaticIP2="$ASCSIP2" \
   iSCSIIP="$ISCSIIP" \
   ASCSLBIP="$ASCSLBIP" \
   ERSLBIP="$ERSLBIP" \
   SubscriptionEmail="${slesemail}" \
   SubscriptionID="$slesreg" \
   SMTUri="$slessmt"


echo "ascs cluster created"
