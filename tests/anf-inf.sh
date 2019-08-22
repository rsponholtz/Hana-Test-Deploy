#!/bin/bash
set -x

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi

az account set --subscription "$subscriptionid"

echo "creating nfs cluster"
az group deployment create \
--name ANFDeployment \
--resource-group $rgname \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-anf-service/sap-anf.json" \
   --parameters \
    ExistingNetworkResourceGroup="$vnetrgname" \
    vnetName="$vnetname" \
    subnetName="$anfsubnetname" \
    netappAccountName="$anfaccountname" \
    capacityPoolName="$anfcappoolname" \
    capacityPoolSize="$anfcappoolsize" \
    capacityPoolServiceLevel="Premium" \
    volumeFilePath="$anfvolpath" \
    volumeUsageThreshold="$anfvolthresh"

echo "anf service created"
