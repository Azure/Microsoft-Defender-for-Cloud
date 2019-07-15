# Logic App sample to remediate

This Logic App deployment template is provided to remediate the "Require secure transfer to storage account" 
recommendation in Azure Security Center.  The workflow will enumerate all subscriptions via the API, loop 
through each subscrption and enumerate all storage accounts and their properties.  It will then check the 
HTTS only property for each storage account and if it is not enabled it will set it to enabled.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%20Score%2FRequire%20secure%20transfer%20to%20storage%20account%2FLogic%20App%2Fazuredeploy.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
</a>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%20Score%2FRequire%20secure%20transfer%20to%20storage%20account%2FLogic%20App%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%20Score%2FRequire%20secure%20transfer%20to%20storage%20account%2FLogic%20App%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
