#!/bin/bash

echo "Reading config...." >&2
source ../azuredeploy.cfg

az account set --subscription $subscriptionid

echo "creating sapbits server"
az group deployment create \
--name sapbitsDeployment \
--resource-group $rgname \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/tests/sapbits-svr/sapbits-infra.json" \
--parameters vmUserName=testuser \
             ExistingNetworkResourceGroup=$rgname \
             vnetName=$vnetname \
             subnetName=$mgtsubnetname \
                   osType="SLES 12 SP3" \
             vmPassword=$vmpassword \
             customUri=$customuri \
                   StaticIP=$SAPBITSIP
