#!/bin/bash
set -x
echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi

az account set --subscription $subscriptionid
echo "creating resource group"
az group create --name $rgname --location "${location}"

echo "creating vnet"
az group deployment create \
--name vnetDeployment \
--resource-group $rgname \
--template-uri "https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2Fvnet.json" \
--parameters \
             addressPrefix="10.0.0.0/16" \
             DBSubnetName=$dbsubnetname \
             DBSubnetPrefix="10.0.0.0/24" \
             AppSubnetName=$appsubnetname \
             AppSubnetPrefix="10.0.1.0/24" \
             MgtSubnetName=$mgtsubnetname \
             MgtSubnetPrefix="10.0.2.0/24" \
             vnetName=$vnetname
