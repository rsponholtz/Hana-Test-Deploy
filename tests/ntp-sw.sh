#!/bin/bash

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi


echo "installing ntp server software"
az group deployment create \
--name NTPDeployment \
--resource-group "$rgname" \
--template-uri "https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2Fsap-ntp-server/ntpserver-sw.json" \
--parameters \
vmUserName=$vmusername \
ExistingNetworkResourceGroup="$rgname" \
vnetName="$vnetname" \
subnetName="$mgtsubnetname" \
osType="SLES 12 SP3" \
vmPassword="$vmpassword" \
customUri="$customuri" \
StaticIP="$NTPIP"

echo "ntp server software installed"
