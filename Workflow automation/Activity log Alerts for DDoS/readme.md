# Activity Log Alerts For DDoS 
Author: Dharani Dharan Mariappan

This LogicApp leverages the Resource Management, Application Insights and Azure Resource Graph REST APIs to get all subscriptions under the tenant and checks for the VNet and PublicIPAlert on each subscription and creates alert if not found. Enables the alert if it is disabled.

The ARM template will create the LogicApp which will run in recurrence with frequency of 30 minutes. The workflow picks up specific administrative signals from Azure Activity log associated to Vnet and Public Ip Address in every valid subscriptions. Based on the signal it creates Alerts if it is not created earlier or Enables the alert if it is disabled. In order to be able to deploy the resources, your user account needs to be granted Contributor rights on the target Resource Group. The LogicApp uses a system-assigned Managed Identity to access data from API. You need to make sure to grant the Managed Identity 'Security Admin' and 'Monitoring Contributor' rights to all Azure subscriptions.

Click on the **Deploy to Azure** button to create the Logic App in a target resource group.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FActivity%20log%20Alerts%20for%20DDoS%2FActivityLogAlertsForDDoS_Template.json" target="_blank">
<img src="https://aka.ms/deploytoazurebutton"/></a>

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FActivity%20log%20Alerts%20for%20DDoS%2FActivityLogAlertsForDDoS_Template.json" target="_blank">
<img src="https://aka.ms/deploytoazuregovbutton"/></a>

**To assign Managed Identity to specific scope:**

1. Make sure you have User Access Administrator permissions for this scope.
2. Go to the subscription/management group page.
3. Press 'Access Control (IAM)' on the navigation bar.
4. Press '+Add' and 'Add role assignment'.
5. Choose 'Security Admin' and 'Monitoring Contributor'.
6. Assign access to Logic App.
7. Press 'save'.

