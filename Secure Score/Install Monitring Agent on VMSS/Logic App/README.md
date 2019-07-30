# Logic Apps sample playbook to remediate
This sample playbook allows you to install the monitoring agent on your Linux and Windows virtual machine scale set. According to ASC's recommendation *"Monitoring agent should be installed on virtual machine scale sets"*
The playbook leverages a "Managed Identity" which needs to be configured after deployment. This "Managed Identity" also requires the appropriate permissions on the resources that you would like to remediate.


<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%2520Score%2FInstall%20Monitring%20Agent%20on%20VMSS%2FLogic%20App%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>


