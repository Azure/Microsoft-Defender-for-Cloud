Upgrading Pricing Tier
Author: Dharani Dharan Mariappan

This LogicApp leverages the Azure Resource Management REST APIs to get all subscriptions under the tenant and checks if 'Pricing Tier' property is set to 'Standard' or not and changes it to 'Standard'.

The ARM template will create the LogicApp Playbook and an API connection to Office 365 and Azure DevOps. The workflow will loop through each subscription in a tenant and verifies the Pricing tier. if the property "Pricing Tier" is not set to 'Standard' it changes it to 'Standard'. And also after the execution depending on the result it creates a workitem in the Azure Devops. In order to be able to deploy the resources, your user account needs to be granted Contributor rights on the target Resource Group. The LogicApp uses a system-assigned Managed Identity to access data from API. You need to make sure to grant the Managed Identity 'Security Reader' and 'Contributor' rights to all Azure subscriptions.


You can deploy the main template by clicking on the buttons below:

 
To assign Managed Identity to specific scope:

Make sure you have User Access Administrator permissions for this scope.
Go to the subscription/management group page.
Press 'Access Control (IAM)' on the navigation bar.
Press '+Add' and 'Add role assignment'.
Choose 'Security Reader' and 'Contributor'.
Assign access to Logic App.
Press 'save'.

Prerequisites:
Azure Devops Project
