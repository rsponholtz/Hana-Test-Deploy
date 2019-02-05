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
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/vnet.json" \
--parameters \
             addressPrefix=$vnetaddressPrefix \
             DBSubnetName=$dbsubnetname \
             DBSubnetPrefix=$DBSubnetPrefix \
             AppSubnetName=$appsubnetname \
             AppSubnetPrefix=$AppSubnetPrefix \
             MgtSubnetName=$mgtsubnetname \
             MgtSubnetPrefix=$MgtSubnetPrefix \
             vnetName=$vnetname
