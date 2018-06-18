#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

echo "installing iscsi server software"
az group deployment create \
--name ISCSIDeployment \
--resource-group $rgname \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-iscsi-server/iscsiserver-sw.json" \
   --parameters \
                   osType="SLES 12 SP3" \
		   customUri="$customuri" \
IQN1="$NFSIQN" \
IQN1client1="$NFSIQNCLIENT1" \
IQN1client2="$NFSIQNCLIENT2" \
IQN2="$HANAIQN" \
IQN2client1="$HANAIQNCLIENT1" \
IQN2client2="$HANAIQNCLIENT2" \
IQN3="$ASCSIQN" \
IQN3client1="$ASCSIQNCLIENT1" \
IQN3client2="$ASCSIQNCLIENT2" 

echo "iscsi server software installed"