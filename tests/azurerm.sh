echo "Reading config...." >&2
source ./azuredeploy.cfg

az account set --subscription $subscriptionid
az group delete -y --name $rgname 
