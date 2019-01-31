#!/bin/bash

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi

az account set --subscription "$subscriptionid"

echo "installing hana software"
az group deployment create \
--name HANADeployment \
--resource-group "$rgname" \
   --template-uri "https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2Fsap-hana-cluster/azuredeploy-hsr-sw.json" \
   --parameters \
   HanaVersion="SAP HANA PLATFORM EDITION 2.0 SPS03 REV30 (51053061)" \
   VMName1="$HANAVMNAME1" \
   VMName2="$HANAVMNAME2" \
   customURI="$customuri" \
   VMUserName="$vmusername" \
   VMPassword="$vmpassword" \
   StaticIP1="$HANAIP1" \
   StaticIP2="$HANAIP2" \
   iSCSIIP="$ISCSIIP" \
   IQN="$HANAIQN" \
   HANASID="$HANASID" \
   IQNClient1="$HANAIQNCLIENT1" \
   IQNClient2="$HANAIQNCLIENT2" \
   ILBIP="$HANAILBIP" \
   SubscriptionEmail="$slesemail" \
   SubscriptionID="$slesreg" \
   SMTUri="$slessmt" \
   NFSIP="$NFSILBIP"

echo "hana software installed"
