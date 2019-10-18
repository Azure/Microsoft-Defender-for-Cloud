# Logic App sample to remediate

This Logic App deployment template is provided to remediate the "Enable auditing on SQL Server" 
recommendation in Azure Security Center.  The workflow has some variables that are static that
you must initalize/set at the start.

This logic app is configured to use a managed service principal.  After deploying the logic app, you will
need to add the managed identity to the subscriptions for contributor access.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https://raw.githubusercontent.com/Azure/Azure-Security-Center/master/Secure%20Score/Enable%20auditing%20for%20the%20SQL%20server/Logic%20App/azuredeploy.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https://raw.githubusercontent.com/Azure/Azure-Security-Center/master/Secure%20Score/Enable%20auditing%20for%20the%20SQL%20server/Logic%20App/azuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%20Score%2FRequire%20secure%20transfer%20to%20storage%20account%2FLogic%20App%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
