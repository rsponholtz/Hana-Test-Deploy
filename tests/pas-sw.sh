#!/bin/bash

echo "Reading config...." >&2
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi


echo "creating netweaver cluster"
az group deployment create \
--name NetWeaver-Deployment \
--resource-group "$rgname" \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-netweaver-server/azuredeploy-nw-sw.json" \
   --parameters \
        VMNAME="$PASVMNAME" \
        VMIPADDR="$PASIPADDR" \
        ISPRIMARY="YES" \
        URI="$customuri" \
        NFSILBIP="$NFSILBIP" \
        ASCS1VM="$ASCSVMNAME1" \
        ASCS1IP="$ASCSIP1" \
        ASCS2VM="$ASCSVMNAME2" \
        ASCS2IP="$ASCSIP2" \
        MASTERPASSWORD="$vmpassword" \
        DBHOST="hanailb" \
        DBSID="$HANASID" \
        DBINSTANCE="00" \
        ASCSSID="$ASCSSID" \
        ASCSHOST="ascsilb" \
        NWINSTANCE="05" \
        ASCSINSTANCE="00" \
        ERSINSTANCE="01" \
        SAPBITSMOUNT="$SAPBITSMOUNT" \
        SAPMNTMOUNT="$SAPMNTMOUNT" \
        USRSAPSIDMOUNT="$USRSAPSIDMOUNT" \
        USRSAPASCSMOUNT="$USRSAPASCSMOUNT" \
        USRSAPERSMOUNT="$USRSAPERSMOUNT" \
        ASCSILBIP="$ASCSLBIP" \
        DBIP="$HANAILBIP" \
        CONFIGURESAP="YES"

echo "netweaver cluster created"


