# Logic Apps sample playbook to remediate
This sample playbook allows you to remediate Azure SQL database instances that do not have transparent data encryption (TDE) enabled,  according to ASC's recommendation *"Enable transparent data encryption on SQL databases"*

The playbook leverages a "Managed Identity" which needs to be configured after deployment. This "Managed Identity" also requires the appropriate permissions on the resources that you would like to remediate.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FRemediation%2520scripts%2FEnable%2520transparent%2520data%2520encryption%2520on%2520SQL%2520databases%2FLogic%2520App%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>