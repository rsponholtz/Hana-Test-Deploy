#!/bin/bash
set -x
echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi

echo "installing ascs cluster"
az group deployment create \
--name ASCSSWDeployment \
--resource-group $rgname \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-ascs-cluster/azuredeploy-ascs-sw.json" \
   --parameters \
   VMName1=$ASCSVMNAME1 \
   VMName2=$ASCSVMNAME2 \
   VMUserName=$vmusername \
   VMPassword=$vmpassword \
   StaticIP1=$ASCSIP1 \
   StaticIP2=$ASCSIP2 \
   iSCSIIP=$ISCSIIP \
   IQN="$ASCSIQN" \
   IQNClient1="$ASCSIQNCLIENT1" \
   IQNClient2="$ASCSIQNCLIENT2" \
   customURI="$customuri" \
   HANASID=$HANASID \
   NFSILBIP=$NFSILBIP \
   ASCSSID=$ASCSSID \
   SAPPASSWD="$vmpassword" \
   DBHOST="hanailb" \
   DBIP="$HANAILBIP" \
   ASCSLBIP="$ASCSLBIP" \
   CONFIGURESAP="yes" \
   CONFIGURECRM="no" \
   CONFIGURESCHEMA="yes" \
   SubscriptionEmail="$slesemail" \
   SubscriptionID="$slesreg" \
   SMTUri="$slessmt" \
   SAPBITSMOUNT="$SAPBITSMOUNT" \
   SAPMNTMOUNT="$SAPMNTMOUNT" \
   USRSAPSIDMOUNT="$USRSAPSIDMOUNT" \
   SAPTRANSMOUNT="$SAPTRANSMOUNT" \
   USRSAPASCSMOUNT="$USRSAPASCSMOUNT" \
   USRSAPERSMOUNT="$USRSAPERSMOUNT"

echo "ascs cluster installed"
