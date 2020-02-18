# Logic Apps sample playbook to remediate
This sample playbook allows you to remediate IP forwarding is enabled on some of your virtual machines. according to ASC's recommendation *"IP forwarding on your virtual machine should be disabled (Preview)"*
The playbook leverages a "Managed Identity" which needs to be configured after deployment. This "Managed Identity" also requires the appropriate permissions on the resources that you would like to remediate.


<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%2520Score%2FIP%20forwarding%20on%20your%20virtual%20machine%20should%20be%20disabled%2FLogic%20App%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>


