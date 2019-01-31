#!/bin/bash

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi



echo "creating jumpbox"
az group deployment create \
--name JumpboxDeployment \
--resource-group $rgname \
--template-uri "https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2Fhanajumpbox/hanajumpbox.json" \
--parameters vmName=hanajumpbox \
   vmUserName=$vmusername \
   StaticIP=$JBPIP \
   ExistingNetworkResourceGroup=$rgname \
   vnetName=$vnetname \
   subnetName=$mgtsubnetname \
   vmPassword=$vmpassword \
   customUri=$customuri

echo "jumpbox created"
