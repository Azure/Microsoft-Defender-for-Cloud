# Upgrading Pricing Tier
Author: Dharani Dharan Mariappan

This LogicApp leverages the Azure Resource Management REST APIs to get all subscriptions under the tenant and checks if 'Pricing Tier' property is set to 'Standard' or not and changes it to 'Standard'.

The ARM template will create the LogicApp and an API connection to Office 365 and Azure DevOps. The workflow will loop through each subscription in a tenant and verifies the Pricing tier. if the property "Pricing Tier" is not set to 'Standard' it changes it to 'Standard'. And also after the execution depending on the result it creates a workitem in the Azure Devops. In order to be able to deploy the resources, your user account needs to be granted Contributor rights on the target Resource Group. The LogicApp uses a system-assigned Managed Identity to access data from API. You need to make sure to grant the Managed Identity 'Security Reader' and 'Contributor' rights to all Azure subscriptions.

**To assign Managed Identity to specific scope:**

Click on the **Deploy to Azure** button to create the Logic App in a target resource group.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FUpgrade%20Pricing%20Tier%2FUpgradePricingTierForSubs_Template.json" target="_blank">
<img src="https://aka.ms/deploytoazurebutton"/></a>

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FUpgrade%20Pricing%20Tier%2FUpgradePricingTierForSubs_Template.json" target="_blank">
<img src="https://aka.ms/deploytoazuregovbutton"/></a>

**To assign Managed Identity to specific scope:**

1. Make sure you have User Access Administrator permissions for this scope.
2. Go to the subscription/management group page.
3. Press 'Access Control (IAM)' on the navigation bar.
4. Press '+Add' and 'Add role assignment'.
5. Choose 'Security Reader' and 'Contributor'.
6. Assign access to Logic App.
7. Press 'save'.

**Prerequisites:**
Azure Devops Project



