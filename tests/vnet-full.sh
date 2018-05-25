#!/bin/bash
source ./azuredeploy.cfg

az account set --subscription $subscriptionid
echo "creating resource group"
az group delete --name $rgname 

./vnet-inf.sh