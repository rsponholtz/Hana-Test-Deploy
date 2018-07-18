# ISCSI Server
## Machine Info
This template will deploy a Linux ISCSI server into your environment. The purpose of this is server is to enable the creation of ICSI targets to use as SBD devices for the cluster configuration of the different cluster. For this purpose, the Custom Script Extension will create three different ISCSI targets and two client IQNs per ISCSI target.

#### Storage Configuration

This VM doesn't require any additional data disks.

## Deploy the Solution
### Deploy from the Portal

To deploy  the infrastructre from the portal using a graphic interface you can use the [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2Fsap-hana-cluster%2Fazuredeploy-hsr-infra.json)

To deploy the Custom Script Extension to install and configure the software,  from the portal using a graphic interface you can use [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2Fsap-hana-cluster%2Fazuredeploy-hsr-sw.json)


## Infrastructure Parameters

Parameter name | Required | Description | Default Value | Allowed Values
-------------- | -------- | ----------- | ------------- | --------------
VM Name |Yes |Name of the ISCSI Server | None | No restrictions
Existing Network Resource Group | No | This gives you the option to deploy the VMs to an existing VNET in a different Resource Group. The value provided should match the name of the existing Resource Group. To deploy the VNET in the same Resource Group the value should be set to "no" | no | No restrictions
VNET Name |No |Name of the Azure VNET which will be used for the VM | vnet | No restrictions
Subnet Name |No | Name of the subnet where the ISCSI server will be provisioned | mgtsubnet | No restrictions
VM User Name | No | Username for both the HANA server and the HANA jumpbox | testuser | No restrictions
VM Password | Yes | Password for the user defined above | None | No restrictions
OS Type | No | OS to use for the ISCSI Server | SLES 12 SP3 | "Windows Server 2016 Datacenter", "SLES 12 SP3",  "SLES 12 SP3 BYOS",  "SLES 12 SP2", "SLES 12 SP2 BYOS"
Static IP | No | Allows you to choose the specific IP to be assgined to the ISCSI server. | 10.0.0.21 | No restrictions
_artifactsLocation | No | The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated. | https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/ | No restrictions
_artifactsLocationSasToken | No | The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated | | No restrictions

## Software Parameters

Parameter name | Required | Description | Default Value | Allowed Values
-------------- | -------- | ----------- | ------------- | --------------
OS Type | No | OS to use for the ISCSI Server | SLES 12 SP3 | "Windows Server 2016 Datacenter", "SLES 12 SP3",  "SLES 12 SP3 BYOS",  "SLES 12 SP2", "SLES 12 SP2 BYOS"
IQN 1 | Yes | IQN for the first ISCSI target | No | No restrictions
IQN 1 Client 1 | Yes | IQN for the first client connecting to the first ISCSI target | No | No restrictions
IQN 1 Client 2 | Yes | IQN for the second client connecting to the first ISCSI target | No | No restrictions
IQN 2 | Yes | IQN for the second ISCSI target | No | No restrictions
IQN 2 Client 1 | Yes | IQN for the first client connecting to the second ISCSI target | No | No restrictions
IQN 2 Client 2 | Yes | IQN for the second client connecting to the second ISCSI target | No | No restrictions
IQN 3 | Yes | IQN for the third ISCSI target | No | No restrictions
IQN 3 Client 1 | Yes | IQN for the first client connecting to the third ISCSI target | No | No restrictions
IQN 3 Client 2 | Yes | IQN for the second client connecting to the third ISCSI target | No | No restrictions
_artifactsLocation | No | The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated. | https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/ | No restrictions
_artifactsLocationSasToken | No | The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated | | No restrictions
