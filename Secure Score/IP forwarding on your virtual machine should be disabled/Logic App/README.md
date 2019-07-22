# Logic Apps sample playbook to remediate
This sample playbook allows you to remediate IP forwarding is enabled on some of your virtual machines. according to ASC's recommendation *"IP forwarding on your virtual machine should be disabled (Preview)"*
The playbook leverages a "Managed Identity" which needs to be configured after deployment. This "Managed Identity" also requires the appropriate permissions on the resources that you would like to remediate.

<a href="https%3A%2F%2Fportal.azure.com%2F%23create%2FMicrosoft.Template%2Furi%2Fhttps%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%20Score%2FIP%252520forwarding%252520on%252520your%252520virtual%252520machine%252520should%252520be%20disabled%2FLogic%252520App%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
