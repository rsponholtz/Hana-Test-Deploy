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
vol2fp=$hana1dataFilePath \
vol2ut=$hana1dataUsageThreshold \
vol3fp=$hana1logFilePath \
vol3ut=$hana1logUsageThreshold \
vol4fp=$hana1sharedFilePath \
vol4ut=$hana1sharedUsageThreshold \
vol5fp=$hana1usrsapFilePath \
vol5ut=$hana1usrsapUsageThreshold \
vol6fp=$hana1backupFilePath \
vol6ut=$hana1backupUsageThreshold \
vol7fp=$hana2dataFilePath \
vol7ut=$hana2dataUsageThreshold \
vol8fp=$hana2logFilePath \
vol8ut=$hana2logUsageThreshold \
vol9fp=$hana2sharedFilePath \
vol9ut=$hana2sharedUsageThreshold \
vol10fp=$hana2usrsapFilePath \
vol10ut=$hana2usrsapUsageThreshold \
vol11fp=$hana2backupFilePath \
vol11ut=$hana2backupUsageThreshold \
vol12fp=$sapmntFilePath \
vol12ut=$sapmntUsageThreshold \
vol13fp=$ascsFilePath \
vol13ut=$ascsUsageThreshold \
vol14fp=$sapsysFilePath \
vol14ut=$sapmntUsageThreshold \
vol15fp=$ersFilePath \
vol15ut=$ersUsageThreshold \
vol16fp=$transFilePath \
vol16ut=$transUsageThreshold \
vol17fp=$usrsapsidFilePath \
vol17ut=$usrsapsidUsageThreshold 

echo "anf service created"
