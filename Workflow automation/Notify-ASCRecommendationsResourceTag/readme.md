# Notify-ASCRecommendationsResourceTag

author: João Paulo Ramos / Nathan Swift

This Logic App for Workflow Automations will notify Microsoft Defender for Cloud generated recommendations to Azure Resource TAG Owners including Azure Arc resources.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FNotify-ASCRecommendationsResourceTag%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FNotify-ASCRecommendationsResourceTag%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

**Additional Post Install Notes:**

The Logic App creates and uses a Managed System Identity (MSI) to authenticate and authorize against management.azure.com to obtain resource TAG called 'Owner'. The MSI is also used to authenticate and authorize against the Azure Resource Manager and the resource's TAG.

Assign RBAC 'Reader' role to the Logic App at the Subscription level.
