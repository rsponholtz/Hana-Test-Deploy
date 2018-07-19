#!/bin/bash
source ./azuredeploy.cfg

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
echo "$ASCSIP2 $ASCSVMNAME1"
echo "$ASCSILBIP ascsilb"
echo "$FIRSTNWIPADDR nw-1"
