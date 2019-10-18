# Logic App sample to remediate

This Logic App deployment template is provided to remediate the "Vulnerability assessment should be enabled 
on your SQL managed instances" recommendation in Azure Security Center.  The workflow will enumerate all 
subscriptions via the API and enumerate all ASC Security Tasks via API.  Then for each task for this recommendation
get the security task details via API.  Lastly configure each SQL Server VA settings.  You will need to set the 1st veriable (StorageAccountName) to the storage account you want to use.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https:%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%20Score%2FVulnerability%20assessment%20should%20be%20enabled%20on%20your%20SQL%20managed%20instances%2FLogic%20App%2Fazuredeploy.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
</a>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https:%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%20Score%2FVulnerability%20assessment%20should%20be%20enabled%20on%20your%20SQL%20managed%20instances%2FLogic%20App%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"
</a>
<a href="http://armviz.io/#/?load=https:%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%20Score%2FVulnerability%20assessment%20should%20be%20enabled%20on%20your%20SQL%20managed%20instances%2FLogic%20App%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
