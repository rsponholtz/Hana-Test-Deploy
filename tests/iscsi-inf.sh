#!/bin/bash
set -x
echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi

az account set --subscription "$subscriptionid"

echo "creating iscsi server"
az group deployment create \
--name ISCSIDeployment \
--resource-group $rgname \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-iscsi-server/iscsiserver-infra.json" \
--parameters vmName="${ISCSIVMNAME}" \
            vmUserName=$vmusername \
             ExistingNetworkResourceGroup=$vnetrgname \
             vnetName=$vnetname \
             subnetName=$mgtsubnetname \
             OperatingSystem="SLES 15 SP1" \
             vmPassword=$vmpassword \
                   StaticIP=$ISCSIIP

echo "iscsi server created"
