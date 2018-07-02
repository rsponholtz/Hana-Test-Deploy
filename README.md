# SAP Automation
This repo contains two different projects. The first one will help you install install SAP HANA on a single VM running SUSE SLES 12 SP 2. It uses the Azure SKU for SAP. The template takes advantage of [Custom Script Extensions](https://github.com/Azure/azure-linux-extensions/tree/master/CustomScript) for the installation and configuration of the machine. This should be used only for demonstration and sandbox environments. This is not a production deployment.
To deploy a single instance of HANA you can use the following button. For more information on the single instance deployment, please refer to the SAP HANA single instance documentation page.
[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzureCAT-GSI%2FHana-Test-Deploy%2Fmaster%2FFazuredeploy.json)

