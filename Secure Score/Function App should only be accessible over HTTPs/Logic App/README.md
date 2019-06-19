# Logic Apps sample playbook to remediate
This sample playbook allows you to remediate Function App instances that do not have HTTPS enabled according to ASC's recommendation *"Function App should only be accessible over HTTPs"*

The playbook leverages a "Managed Identity" which needs to be configured after deployment. This "Managed Identity" also requires the appropriate permissions on the resources that you would like to remediate.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%2520Score%2FFunction%2520App%2520should%2520only%2520be%2520accessible%2520over%2520HTTPs%2FLogic%2520App%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
