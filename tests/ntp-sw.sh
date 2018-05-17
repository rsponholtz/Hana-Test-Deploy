#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

az account set --subscription "$subscriptionid"

echo "installing ntp server software"
az group deployment create \
--name NTPDeployment \
--resource-group "$rgname" \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-ntp-server/ntpserver-sw.json" \
--parameters \
vmUserName=testuser \
ExistingNetworkResourceGroup="$rgname" \
vnetName="$vnetname" \
subnetName="$mgtsubnetname" \
osType="SLES 12 SP3" \
vmPassword="$vmpassword" \
customUri="$customuri" \
StaticIP="$NTPIP"

