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
IQN1="$IQN1" \
IQN1client1="$IQN1CLIENT1" \
IQN1client2="$IQN1CLIENT2" \
IQN2="$IQN2" \
IQN2client1="$IQN2CLIENT1" \
IQN2client2="$IQN2CLIENT2" \
IQN3="$IQN3" \
IQN3client1="$IQN3CLIENT1" \
IQN3client2="$IQN3CLIENT2" 
