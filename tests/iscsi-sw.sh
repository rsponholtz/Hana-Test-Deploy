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
NFSIQN="$IQN1" \
NFSIQNCLIENT1="$IQN1CLIENT1" \
NFSIQNCLIENT2="$IQN1CLIENT2" \
HANAIQN="$IQN2" \
HANAIQNCLIENT1="$IQN2CLIENT1" \
HANAIQNCLIENT2="$IQN2CLIENT2" \
ASCSIQN="$IQN3" \
ASCSIQNCLIENT1="$IQN3CLIENT1" \
ASCSIQNCLIENT2="$IQN3CLIENT2" 
