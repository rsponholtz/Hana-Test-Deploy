#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

az account set --subscription $subscriptionid

echo "installing iscsi server software"
az group deployment create \
--name ISCSIDeployment \
--resource-group $rgname \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-iscsi-server/iscsiserver-sw.json" \
   --parameters \
                   osType="SLES 12 SP3" \
		   customUri="$customuri" \
IQN1="iqn.1991-05.com.microsoft:nfsserver-target" \
IQN1client1="iqn.1991-05.com.microsoft:nfsserver-target:nfsvm1" \
IQN1client2="iqn.1991-05.com.microsoft:nfsserver-target:nfsvm2" \
IQN2="iqn.1991-05.com.microsoft:hana-target" \
IQN2client1="iqn.1991-05.com.microsoft:hana-target:hanavm1" \
IQN2client2="iqn.1991-05.com.microsoft:hana-target:hanavm2" \
IQN3="iqn.1991-05.com.microsoft:ascs-target" \
IQN3client1="iqn.1991-05.com.microsoft:ascs-target:ascsvm1" \
IQN3client2="iqn.1991-05.com.microsoft:ascs-target:ascsvm2" 
