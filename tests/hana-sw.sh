#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

echo "installing hana software"
az group deployment create \
--name HANADeployment \
--resource-group "$rgname" \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-hana-cluster/azuredeploy-hsr-sw.json" \
   --parameters \
   VMName1="$HANAVMNAME1" \
   VMName2="$HANAVMNAME2" \
   customURI="$customuri" \
   VMUserName="$vmusername" \
   VMPassword="$vmpassword" \
   StaticIP1="$HANAIP1" \
   StaticIP2="$HANAIP2" \
   iSCSIIP="$ISCSIIP" \
   IQN="$HANAIQN" \
   IQNClient1="$HANAIQNCLIENT1" \
   IQNClient2="$HANAIQNCLIENT2" \
   ILBIP="$HANAILBIP" \
   SubscriptionEmail="$slesemail" \
   SubscriptionID="$slesreg" \
   SMTUri="$slessmt"
