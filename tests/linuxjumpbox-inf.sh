#!/bin/bash

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi
az account set --subscription $subscriptionid

echo "creating linuxjumpbox"
az group deployment create \
--name sapbitsDeployment \
--resource-group $rgname \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/linuxjumpbox/linuxjumpbox-infra.json" \
--parameters \
vmName="$LINUXJUMPBOXNAME" \
vmUserName=$vmusername  \
             ExistingNetworkResourceGroup=$vnetrgname \
             vnetName=$vnetname \
             subnetName=$mgtsubnetname \
                   osType="SLES 12 SP3" \
             adminPublicKey=$jumpboxkey \
             customUri=$customuri \
                   StaticIP=$LINUXJUMPBOXIP
