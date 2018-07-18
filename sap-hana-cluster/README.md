# SAP HANA in High availability
## Machine Info
The template currently deploys two virtual machines with HANA installed, configures HANA System Replication (HSR) and creates an OS level cluster based on the Linux High Availability Extension for SUSE. The virtual machines are deployed with the configuration listed in the table below with the noted disk configuration.  The deployment takes advantage of Managed Disks, for more information on Managed Disks or the sizes of the noted disks can be found on [this](https://docs.microsoft.com/en-us/azure/storage/storage-managed-disks-overview#pricing-and-billing) page.

#### Cost conscious Azure Storage configuration
The following table shows a configuration of VM types that customers commonly use to host SAP HANA on Azure VMs. There might be some VM types that might not meet all minimum criteria for SAP HANA. But so far those VMs seemed to perform fine for non-production scenarios. 

> [!NOTE]
> For production scenarios, check whether a certain VM type is supported for SAP HANA by SAP in the [SAP documentation for IAAS](https://www.sap.com/dmc/exp/2014-09-02-hana-hardware/enEN/iaas.html).


| VM SKU | RAM | Max. VM I/O<br /> Throughput | /hana/data and /hana/log<br /> striped with LVM or MDADM | /hana/shared | /root volume | /usr/sap | hana/backup |
| --- | --- | --- | --- | --- | --- | --- | -- |
| DS14v2 | 128 GiB | 768 MB/s | 3 x P20 | 1 x S20 | 1 x S6 | 1 x S6 | 1 x S15 |
| E16v3 | 128 GiB | 384 MB/s | 3 x P20 | 1 x S20 | 1 x S6 | 1 x S6 | 1 x S15 |
| E32v3 | 256 GiB | 768 MB/s | 3 x P20 | 1 x S20 | 1 x S6 | 1 x S6 | 1 x S20 |
| E64v3 | 443 GiB | 1200 MB/s | 3 x P20 | 1 x S20 | 1 x S6 | 1 x S6 | 1 x S30 |
| GS5 | 448 GiB | 2000 MB/s | 3 x P20 | 1 x S20 | 1 x S6 | 1 x S6 | 1 x S30 |

#### Storage solution with Azure Write Accelerator for Azure M-Series virtual machines
Azure Write Accelerator is a functionality that is getting rolled out for M-Series VMs exclusively. As the name states, the purpose of the functionality is to improve I/O latency of Writes against the Azure Premium Storage. For SAP HANA, Write Accelerator is supposed to be used against the /hana/log volume only. Therefore the configurations shown so far need to be changed. The main change is the breakup between the /hana/data and /hana/log in order to use Azure Write Accelerator against the /hana/log volume only. 

> [!IMPORTANT]
> SAP HANA certification for Azure M-Series virtual machines is exclusively with Azure Write Accelerator for the /hana/log volume. As a result, production scenario SAP HANA deployments on Azure M-Series virtual machines are expected to be configured with Azure Write Accelerator for the /hana/log volume.  

> [!NOTE]
> For production scenarios, check whether a certain VM type is supported for SAP HANA by SAP in the [SAP documentation for IAAS](https://www.sap.com/dmc/exp/2014-09-02-hana-hardware/enEN/iaas.html).

The recommended configurations look like:

| VM SKU | RAM | Max. VM I/O<br /> Throughput | /hana/data | /hana/log | /hana/shared | /root volume | /usr/sap | hana/backup |
| --- | --- | --- | --- | --- | --- | --- | --- | -- |
| M32ts | 192 GiB | 500 MB/s | 3 x P20 | 2 x P20 | 1 x P20 | 1 x P6 | 1 x P6 |1 x P20 |
| M32ls | 256 GiB | 500 MB/s | 3 x P20 | 2 x P20 | 1 x P20 | 1 x P6 | 1 x P6 |1 x P20 |
| M64ls | 512 GiB | 1000 MB/s | 3 x P20 | 2 x P20 | 1 x P20 | 1 x P6 | 1 x P6 |1 x P30 |
| M64s | 1000 GiB | 1000 MB/s | 4 x P20 | 2 x P20 | 1 x P30 | 1 x P6 | 1 x P6 |2 x P30 |
| M64ms | 1750 GiB | 1000 MB/s | 3 x P30 | 2 x P20 | 1 x P30 | 1 x P6 | 1 x P6 | 3 x P30 |
| M128s | 2000 GiB | 2000 MB/s |3 x P30 | 2 x P20 | 1 x P30 | 1 x P6 | 1 x P6 | 2 x P40 |
| M128ms | 3800 GiB | 2000 MB/s | 5 x P30 | 2 x P20 | 1 x P30 | 1 x P6 | 1 x P6 | 2 x P50 |

## Prerequisites
To create an sbd device for the cluster configuration, the Custom Script Extension leverages an existing ISCSI server. The deployment assumes that an ISCSI target is already set up. For more information on setting up the ISCSI server please refer to the [ISCSI documentation](https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/sap-iscsi-server/README.md).

## Installation Media
Installation media for SAP HANA should be downloaded and placed in the SapBits folder. You will need to provide the URI for the container where they are stored, for example https://yourBlobName.blob.core.windows.net/yourContainerName. For more information on how to upload files to Azure please go [here](UploadToAzure.md)  Specifically you need to download SAP package 51052325, which should consist of four files:
```
51052325_part1.exe
51052325_part2.rar
51052325_part3.rar
51052325_part4.rar
```

If you want to use a newer version of HANA Studio rename your filename to IMC_STUDIO2_212_2-80000323.SAR.

The Server Java Runtime Environment bits can be downloaded [here](http://www.oracle.com/technetwork/java/javase/downloads/server-jre9-downloads-3848530.html).

There should be a folder inside your storage account container called SapBits:

![SapBits Image](https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/media/Structure1.png)

The following files should be present inside the SapBits folder:

![HANA Image](https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/media/Structure2.png)

## Deploy the Solution
### Deploy from the Portal

To deploy  the infrastructre from the portal using a graphic interface you can use the [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2Fsap-hana-cluster%2Fazuredeploy-hsr-infra.json)

To deploy the Custom Script Extension to install and configure the software,  from the portal using a graphic interface you can use [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2Fsap-hana-cluster%2Fazuredeploy-hsr-sw.json)

## Monitoring

For your deployment to be supported by SAP the Azure Enhanced Monitoring Extension must be enabled on the Virtual Machine. Please refer to the following [blog post](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/sap/deployment-guide#d98edcd3-f2a1-49f7-b26a-07448ceb60ca) for more information on how to enable it.

## Infrastructure Parameters

Parameter name | Required | Description | Default Value | Allowed Values
-------------- | -------- | ----------- | ------------- | --------------
VM Name 1 |Yes |Name of the first HANA Virtual Machine. | None | No restrictions
VM Name 2 |Yes |Name of the second HANA Virtual Machine. | None | No restrictions
VM Size |No |Defines the size of the Azure VM for the HANA servers. | Standard_GS5 |  "Standard_DS14_v2 (128 GB)", "Standard_GS5 (448 GB, Certified)", "Standard_M32ts (192 GB)", "Standard_M32ls (256 GB)",  "Standard_M64ls (512 GB)", "Standard_M64s (1 TB, Certified)", "Standard_M64ms (1.7 TB, Certified)", "Standard_M128s (2 TB, Certified)", "Standard_M128ms (3.8 TB, Certified)", "Standard_E16s_v3 (128 GB)", "Standard_E32s_v3 (256 GB)",  "Standard_E64s_v3 (448 GB)" | Only VM sizes specified.
Network Name |No |Name of the Azure VNET to be provisioned | ra-hana-vnet | No restrictions
Address Prefixes |No |Address prefix for the Azure VNET to be provisioned | 10.0.0.0/16 | No restrictions
HANA Subnet Name |No | Name of the subnet where the HANA server will be provisioned | SAPDataSubnet | No restrictions
HANA Subnet Prefix |No |Subnet prefix of the subnet where the HANA server will be provisioned | 10.0.5.0/24 | No restrictions
VM User Name | No | Username for both the HANA server and the HANA jumpbox | testuser | No restrictions
VM Password | Yes | Password for the user defined above | None | No restrictions
Operating System | No | Linux distribution to use for the HANA server | SLES for SAP 12 SP2 | SLES for SAP 12 SP2, RHEL 7.2 for SAP HANA
HANASID | No | HANA System ID | H10 | No restrictions
HANA Number | No | SAP HANA Instance Number | 00 | No restrictions
Existing Network Resource Group | No | This gives you the option to deploy the VMs to an existing VNET in a different Resource Group. The value provided should match the name of the existing Resource Group. To deploy the VNET in the same Resource Group the value should be set to "no" | no | No restrictions
IP Allocation Method | no | Lets you choose between Static and Dynamic IP Allocation | Dynamic | Dynamic, Static
Static IP 1 | No | Allows you to choose the specific IP to be assgined to the first HANA server. | 10.0.0.20 | No restrictions
Static IP 2 | No | Allows you to choose the specific IP to be assgined to the second HANA server. | 10.0.0.21 | No restrictions
ISCSI IP | No | IP Address of the ISCSI server that will be used as target. | 10.0.2.6 | No restrictions
ILB IP | No | IP Address of the Internal Load Balancer | 10.0.0.22 | No restrictions
Subscription Email | No | OS subscription email for BYOS. Leave blank for pay-as-you-go OS image. |  | No restrictions
Subscription ID | No | OS ID or password for BYOS. Leave blank for pay-as-you-go OS image. |  | No restrictions
SMT Uri | No | The URI to a subscription management server if used, blank otherwise |  | No restrictions

## Software Parameters

Parameter name | Required | Description | Default Value | Allowed Values
-------------- | -------- | ----------- | ------------- | --------------
VM Name 1 |Yes |Name of the first HANA Virtual Machine. | None | No restrictions
VM Name 2 |Yes |Name of the second HANA Virtual Machine. | None | No restrictions
Custom URI | Yes | URI where the SAP bits were uploaded | None | No restrictions
VM User Name | No | Username for both the HANA server and the HANA jumpbox | testuser | No restrictions
VM Password | Yes | Password for the user defined above | None | No restrictions
Operating System | No | Linux distribution to use for the HANA server | SLES for SAP 12 SP2 | SLES for SAP 12 SP2, RHEL 7.2 for SAP HANA
HANASID | No | HANA System ID | H10 | No restrictions
HANA Number | No | SAP HANA Instance Number | 00 | No restrictions
Static IP 1 | No | Allows you to choose the specific IP to be assgined to the first HANA server. | 10.0.0.20 | No restrictions
Static IP 2 | No | Allows you to choose the specific IP to be assgined to the second HANA server. | 10.0.0.21 | No restrictions
ISCSI IP | No | IP Address of the ISCSI server that will be used as target. | 10.0.2.6 | No restrictions
IQN | No | IQN for the ISCSI server | iqn.1991-05.com.microsoft:hana-target | No restrictions
IQNClient1 | No | IQN for the first ISCSI client (first HANA VM) | iqn.1991-05.com.microsoft:hana-target:hanavm1 | No restrictions
IQNClient2 | No | IQN for the second ISCSI client (second HANA VM) | iqn.1991-05.com.microsoft:hana-target:hanavm2 | No restrictions
ILB IP | No | IP Address of the Internal Load Balancer | 10.0.0.22 | No restrictions
Subscription Email | No | OS subscription email for BYOS. Leave blank for pay-as-you-go OS image. |  | No restrictions
Subscription ID | No | OS ID or password for BYOS. Leave blank for pay-as-you-go OS image. |  | No restrictions
SMT Uri | No | The URI to a subscription management server if used, blank otherwise |  | No restrictions
NFS IP | No | IP Address of the NFS server | 10.0.1.10 | No restrictions

## Known issues
### When clicking on Deploy to Azure you get redirected to an empty directory
![Directories](https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/media/directories.png)

The only way to get around this is to save the template to your own template library. Click on "Create a Resource" and choose "Template Deployment". Click "Create".

![Directories2](https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/media/directories2.png)

Select the option of "Build your own template in the editor"

![Directories3](https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/media/directories3.png)

Copy the contents from the azuredeploy.json [file](https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/azuredeploy.json) and paste them into the template editor, click Save.

![Directories4](https://raw.githubusercontent.com/AzureCAT-GSI/Hana-Test-Deploy/master/media/directories4.png)

The template is now available in your template library. Changes made to the github repo will not be replicated, make sure to update your template when changes to the azuredeploy.json file are made.
