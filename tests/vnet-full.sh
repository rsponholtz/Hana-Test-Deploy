#!/bin/bash
source ./azuredeploy.cfg

echo "creating resource group"
az group delete --name $rgname 

./vnet-inf.sh