#!/bin/bash

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi


echo "creating netweaver cluster"
az group deployment create \
--name NetWeaver-Deployment \
--resource-group "$rgname" \
   --template-uri "https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2Fsap-netweaver-server/azuredeploy-nw-sw.json" \
   --parameters \
   vmName="$PASVMNAME" \
   vmUserName="$vmusername" \
   vmPassword="$vmpassword" \
   vnetName="$vnetname" \
   ExistingNetworkResourceGroup="$rgname" \
   vmSize="Standard_DS2_v2" \
   osType="SLES 12 SP3" \
   appAvailSetName="nwavailset" \
   StaticIP="$PASIPADDR"

echo "netweaver cluster created"
