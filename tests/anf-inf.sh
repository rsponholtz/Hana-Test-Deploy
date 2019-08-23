#!/bin/bash
set -x

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi

az account set --subscription "$subscriptionid"

echo "creating nfs cluster"
az group deployment create \
--name ANFDeployment \
--resource-group $rgname \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-anf-service/sap-anf.json" \
   --parameters \
    ExistingNetworkResourceGroup="$vnetrgname" \
    vnetName="$vnetname" \
    subnetName="$anfsubnetName" \
    netappAccountName="$netappAccountName" \
    capacityPoolName="$capacityPoolName" \
    capacityPoolSize="$capacityPoolSize" \
    capacityPoolServiceLevel="Premium" \
vol1fp=$sapbitsFilePath \ 
vol1ut=$sapbitsUsageThreshold \
vol2fp=$hanadataFilePath \ 
vol2ut=$hanadataUsageThreshold \
vol3fp=$hanalogFilePath \ 
vol3ut=$hanalogUsageThreshold \
vol4fp=$hanasharedFilePath \ 
vol4ut=$hanasharedUsageThreshold \
vol5fp=$hanausrsapFilePath \ 
vol5ut=$hanausrsapUsageThreshold \
vol6fp=$hanabackupFilePath \ 
vol6ut=$hanabackupUsageThreshold \
vol7fp=$sapmntFilePath \ 
vol7ut=$sapmntUsageThreshold \
vol8fp=$ascsFilePath \ 
vol8ut=$ascsUsageThreshold \
vol9fp=$sapsysFilePath \ 
vol9ut=$sapmntUsageThreshold \
vol10fp=$ersFilePath \ 
vol10ut=$ersUsageThreshold \
vol11fp=$transFilePath \ 
vol11ut=$transUsageThreshold \
vol12fp=$usrsapsidFilePath \ 
vol12ut=$usrsapsidUsageThreshold 

echo "anf service created"
