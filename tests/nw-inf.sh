#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

echo "creating netweaver cluster"
az group deployment create \
--name NetWeaver-Deployment \
--resource-group "$rgname" \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-netweaver-server/azuredeploy-nw-infra.json" \
   --parameters \
   vmName="$NWVMNAME" \
   NumberOfVmsToMake="$NWVMCOUNT" \
   DataDisksPerVm=0 \
   vmUserName="$vmusername" \
   vmPassword="$vmpassword" \
   vnetName="$vnetname" \
   ExistingNetworkResourceGroup="$rgname" \
   vmSize="Standard_DS2_v2" \
   osType="SLES 12 SP3" \
   appAvailSetName="nwavailset" \
   StaticIPStartRange="$FIRSTNWIPADDR"
