# Notify-ASCAlertsbyAzureActivity
author: Nathan Swift

This Logic App for Workflow Automations will notify Microsoft Defender for Cloud generated threat alerts to recent users within last 14 days that created or updated the Azure Resource.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FNotify-ASCAlertsbyAzureActivity%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FNotify-ASCAlertsbyAzureActivity%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

**Additional Post Install Notes:**

The Logic App creates and uses a Managed System Identity (MSI) to obtain the AzureActivity Logs on the resource and find the Callers.

Assign RBAC 'Reader' role to the Logic App at the ManagementGroup or Subscription level.