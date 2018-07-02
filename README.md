# SAP Automation
This repo contains two different projects. The first one will help you install install SAP HANA on a single VM running SUSE SLES 12 SP 2. The second one deals with more complex scenarios, different components and high availability.

 Both use the Azure SKUs for SAP. The templates take advantage of [Custom Script Extensions](https://github.com/Azure/azure-linux-extensions/tree/master/CustomScript) for the installation and configuration of the machine. Both should be used only for demonstration and sandbox environments. This is not a production deployment.

## SAP HANA Single Instance Deployment
To deploy a single instance of HANA you can use the following button. For more information on the single instance deployment, please refer to the SAP HANA single instance [documentation page](https://github.com/AzureCAT-GSI/Hana-Test-Deploy/blob/master/README-single.md).

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2FFazuredeploy.json)

## SAP Landscape Deployment
To deploy a single instance of HANA you can use the following button. For more information on the single instance deployment, please refer to the SAP Landscape [documentation page](https://github.com/AzureCAT-GSI/Hana-Test-Deploy/blob/master/README-full.md).

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2FFazuredeploy-full.json)
