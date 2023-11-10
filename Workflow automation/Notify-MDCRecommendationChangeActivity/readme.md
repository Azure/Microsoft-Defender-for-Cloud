# Notify-MDCRecommendationChangeActivity
author: Nathan Swift

This Logic App for Workflow Automations will notify MDC generated recommendation to GRC team and recent users within last 24 hours that made changes to the Azure Resource.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FNotify-MDCRecommendationChangeActivity%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FNotify-MDCRecommendationChangeActivity%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

**Additional Post Install Notes:**

The Logic App creates and uses a Managed System Identity (MSI) to authenticate and authorize against management.azure.com to obtain Change Anslysis on the Azure Resource and find the identities making changes.

Assign RBAC 'Reader' role to the Logic App at the ManagementGroup or Subscription level.

![Notification mail](./images/emailexample.png)

Logic App Steps:

![Logic App](./images/logicapp.png)