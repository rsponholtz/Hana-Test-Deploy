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
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-netweaver-server/azuredeploy-nw-infra.json" \
   --parameters \
   vmName="$NWVMNAME" \
   vmUserName="$vmusername" \
   vmPassword="$vmpassword" \
   vnetName="$vnetname" \
   ExistingNetworkResourceGroup="$rgname" \
   vmSize="Standard_DS2_v2" \
   osType="SLES 12 SP3" \
   appAvailSetName="nwavailset" \
   StaticIP="$FIRSTNWIPADDR"

echo "netweaver cluster created"
