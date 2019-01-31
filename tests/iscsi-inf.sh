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
--template-uri "https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2Fsap-iscsi-server/iscsiserver-infra.json" \
--parameters vmName="${ISCSIVMNAME}" \
            vmUserName=$vmusername \
             ExistingNetworkResourceGroup=$vnetrgname \
             vnetName=$vnetname \
             subnetName=$mgtsubnetname \
                   osType="SLES 12 SP3" \
             vmPassword=$vmpassword \
             customUri=$customuri \
                   StaticIP=$ISCSIIP

echo "iscsi server created"
