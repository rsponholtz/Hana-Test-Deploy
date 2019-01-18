#!/bin/bash

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi

az account set --subscription "$subscriptionid"

echo "installing linuxjumpbox software"
az group deployment create \
--name LINUXJUMPBOXDeployment \
--resource-group "$rgname" \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/linuxjumpbox/linuxjumpbox-sw.json" \
--parameters \
vmName="$LINUXJUMPBOXNAME"
vmUserName=$vmusername \
ExistingNetworkResourceGroup="$rgname" \
vnetName="$vnetname" \
subnetName="$mgtsubnetname" \
osType="SLES 12 SP3" \
vmPassword="$vmpassword" \
customUri="$customuri" \
StaticIP="$LINUXJUMPBOXIP" \
sapid="$SAPID" \
sappasswd="$SAPPASSWD" \
downloadbitsfrom="SAP"

