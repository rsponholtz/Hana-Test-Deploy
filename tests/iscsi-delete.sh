#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

az account set --subscription $subscriptionid

echo "deleting iscsi server"
az vm delete --yes --resource-group $rgname --name iscsiserver   


