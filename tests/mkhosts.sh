#!/bin/bash
if [ "${1}" != "" ]; then
    source ${1}
else
    source ./azuredeploy.cfg
fi


echo "$NTPIP $NTPNAME"
echo "$NFSIP1 $NFSVMNAME1"
echo "$NFSIP2 $NFSVMNAME2"
echo "$NFSILBIP nfsnfslb"
echo "$HANAIP1 $HANAVMNAME1"
echo "$HANAIP2 $HANAVMNAME2"
echo "$HANAILBIP hanailb"
echo "$ISCSIIP iscsi"
echo "$JBPIP hanajumpbox"
echo "$ASCSIP1 $ASCSVMNAME1"
echo "$ASCSIP2 $ASCSVMNAME2"
echo "$ASCSLBIP ascslb"
echo "$PASIPADDR $PASVMNAME"
echo "$AASIPADDR $AASVMNAME"
