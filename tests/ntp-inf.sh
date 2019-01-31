#!/bin/bash

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi


echo "creating ntp server"
az group deployment create \
--name NTPDeployment \
--resource-group $rgname \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-ntp-server/ntpserver-infra.json" \
--parameters vmUserName=$vmusername \
             ExistingNetworkResourceGroup=$vnetrgname \
             vnetName=$vnetname \
             subnetName=$mgtsubnetname \
                   osType="SLES 12 SP3" \
             vmPassword=$vmpassword \
             customUri=$customuri \
                   StaticIP=$NTPIP

echo "ntp server created"
