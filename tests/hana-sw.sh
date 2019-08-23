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
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-hana-cluster/azuredeploy-hsr-sw.json" \
   --parameters \
   HanaVersion="$HANAVERSION" \
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
   NFSIP="$NFSILBIP" \
   use_anf=$USE_ANF \
   sapbitsfilepath=$sapbitsmount \
   hana1datafilepath=$hana1datamount \
   hana1logfilepath=$hana1logmount \
   hana1sharedfilepath=$hana1sharedmount \
   hana1usrsapfilepath=$hana1usrsapmount \
   hana1backupfilepath=$hana1backupmount \
   hana2datafilepath=$hana2datamount \
   hana2logfilepath=$hana2logmount \
   hana2sharedfilepath=$hana2sharedmount \
   hana2usrsapfilepath=$hana2usrsapmount \
   hana2backupfilepath=$hana2backupmount 



echo "hana software installed"
