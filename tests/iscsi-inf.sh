#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

az account set --subscription $subscriptionid

echo "creating iscsi server"
az group deployment create \
--name ISCSIDeployment \
--resource-group $rgname \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-iscsi-server/iscsiserver-infra.json" \
--parameters vmUserName=testuser \
             ExistingNetworkResourceGroup=$rgname \
             vnetName=$vnetname \
             subnetName=$mgtsubnetname \
                   osType="SLES 12 SP3" \
             vmPassword=$vmpassword \
             customUri=$customuri \
                   StaticIP=$ISCSIIP
