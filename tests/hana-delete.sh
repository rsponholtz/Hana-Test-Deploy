#!/bin/bash

echo "Reading config...." >&2
source ./azuredeploy.cfg

az account set --subscription $subscriptionid

echo "deleting hana servers"
az vm delete --yes --resource-group $rgname --name $HANAVMNAME1
az vm delete --yes --resource-group $rgname --name $HANAVMNAME2

