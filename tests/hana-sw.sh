#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

IQN="iqn.1991-05.com.microsoft:hana-target" 
IQNClient1="iqn.1991-05.com.microsoft:hana-target:hanavm1" 
IQNClient2="iqn.1991-05.com.microsoft:hana-target:hanavm2"


echo "creating hana cluster"
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
   IQN="$IQN" \
   IQNClient1="$IQNClient1" \
   IQNClient2="$IQNClient2" \
   ILBIP="$HANAILBIP"
