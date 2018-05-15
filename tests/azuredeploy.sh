rgname=azuredeploy-full-3
vnetname=vnet
subnetname=subnet
vmpassword="AweS0me@PW1234" 
customuri="https://stagea3d54928db62458aad6.blob.core.windows.net/hanarg5-stageartifacts"

echo "creating resource grouop"
az group create --name $rgname --location "West US 2"

echo "creating vnet"
az group deployment create \
--name vnetDeployment \
--resource-group $rgname \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/vnet.json" \
--parameters vnetResourceGroup=azuredeploy-full \
             addressPrefix="10.0.0.0/16" \
             subnetName=$subnetname \
             subnetPrefix="10.0.0.0/24" \
             vnetName=$vnetname

echo "creating jumpbox"
az group deployment create \
--name JumpboxDeployment \
--resource-group $rgname \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/Vms/hanajumpbox.json" \
--parameters vmName=hanajumpbox \
             vmUserName=testuser \
             ExistingNetworkResourceGroup=$rgname \
             vnetName=$vnetname \
             subnetName=$subnetname \
             vmPassword=$vmpassword \
             customUri=$customuri

echo "creating ntp server"
az group deployment create \
--name NTPDeployment \
--resource-group $rgname \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-ntp-server/ntpserver-infra.json" \
--parameters vmUserName=testuser \
             ExistingNetworkResourceGroup=$rgname \
             vnetName=$vnetname \
             subnetName=$subnetname \
                   osType="SLES 12 SP3" \
             vmPassword=$vmpassword \
             customUri=$customuri \
                   StaticIP="10.0.0.5"

echo "creating iscsi server"
az group deployment create \
--name ISCSIDeployment \
--resource-group $rgname \
--template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-iscsi-server/iscsiserver-infra.json" \
--parameters vmUserName=testuser \
             ExistingNetworkResourceGroup=$rgname \
             vnetName=$vnetname \
             subnetName=$subnetname \
                   osType="SLES 12 SP3" \
             vmPassword=$vmpassword \
             customUri=$customuri \
                   StaticIP="10.0.0.6"

echo "creating nfs cluster"
az group deployment create \
--name NFSDeployment \
--resource-group $rgname \
   --template-uri "https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-nfs-service/azuredeploy-nfs-infra.json" \
   --parameters prefix=nfs \
   VMName1="nfs1" \
   VMName2="nfs2" \
   VMSize="Standard_E16s_v3 (128 GB)" \
   vnetName=$vnetname \
   SubnetName=$subnetname \
   VMUserName="testuser" \
   VMPassword=$vmpassword \
   OperatingSystem="SLES for SAP 12 SP2" \
   ExistingNetworkResourceGroup=$rgname \
   StaticIP1="10.0.0.7" \
   StaticIP2="10.0.0.8" \
   iSCSIIP="10.0.0.6" \
   ILBIP="10.0.0.10"

