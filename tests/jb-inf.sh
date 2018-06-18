#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg


echo "creating jumpbox"
az group deployment create \
--name JumpboxDeployment \
--resource-group $rgname \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/Vms/hanajumpbox.json" \
--parameters vmName=hanajumpbox \
   vmUserName=$vmusername \
   StaticIP=$JBPIP \
   ExistingNetworkResourceGroup=$rgname \
   vnetName=$vnetname \
   subnetName=$mgtsubnetname \
   vmPassword=$vmpassword \
   customUri=$customuri

echo "jumpbox created"