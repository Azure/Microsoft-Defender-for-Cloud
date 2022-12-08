# Assign-MDCRecommendationsbyAzureActivity
author: Nathan Swift

This Logic App for Workflow Automations will assign a governance owner and notify to ASC generated recommendations to recent users within last 7 days that created or updated the Azure Resource.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FAssign-MDCRecommendationsbyAzureActivity%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FAssign-MDCRecommendationsbyAzureActivity%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

**Additional Post Install Notes:**

The Logic App creates and uses a Managed System Identity (MSI) to authenticate and authorize against management.azure.com to obtain AzureActivity Logs on the resource and find the Callers. The Logic App will also assign a governance owner to the resource recommendation.

Assign RBAC 'Security Admin' role to the Logic App at the ManagementGroup or Subscription level.

Assign RBAC 'Reader' role to the Logic App at the ManagementGroup or Subscription level.