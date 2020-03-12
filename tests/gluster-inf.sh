#!/bin/bash

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi

az account set --subscription "$subscriptionid"

echo "creating gluster cluster"
az group deployment create \
--name GlusterDeployment \
--resource-group $rgname \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-gluster-service/azuredeploy-gluster-infra.json" \
   --parameters prefix=nfs \
   VMName1=$GLUSTERVMNAME1 \
   VMName2=$GLUSTERVMNAME2 \
   VMName2=$GLUSTERVMNAME3 \   
   VMSize="Standard_D4s_v3" \
   vnetName=$vnetname \
   SubnetName=$appsubnetname \
   VMUserName=$vmusername \
   VMPassword=$vmpassword \
   OperatingSystem="RHEL 7.4 for SAP HANA" \
   ExistingNetworkResourceGroup=$vnetrgname \
   StaticIP1=$GLUSTERIP1 \
   StaticIP2=$GLUSTERIP2 \
   StaticIP2=$GLUSTERIP3 \
   DataDiskSize=$GLUSTERDISKSIZE

echo "gluster cluster created"
