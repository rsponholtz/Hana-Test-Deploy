#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

echo "deleting iscsi server"
az vm delete --yes --resource-group $rgname --name iscsiserver   

echo "iscsi server deleted"
