#!/bin/bash

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi

az account set --subscription "$subscriptionid"

echo "creating netweaver cluster"
az group deployment create \
--name NetWeaver-Deployment \
--resource-group "$rgname" \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-netweaver-server/azuredeploy-nw-infra.json" \
   --parameters \
   vmName="$PASVMNAME" \
   vmUserName="$vmusername" \
   vmPassword="$vmpassword" \
   vnetName="$vnetname" \
   ExistingNetworkResourceGroup="$vnetrgname" \
   vmSize="Standard_DS2_v2" \
   osType="SLES 12 SP4" \
   appAvailSetName="nwavailset" \
   StaticIP="$PASIPADDR" \
   subnetName="$appsubnetname" 

echo "netweaver cluster created"
