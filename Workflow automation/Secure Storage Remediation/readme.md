# Secure Storage Remediation
Author: Dharani Dharan Mariappan

This LogicApp leverages the Resource Management and Azure Storage REST APIs to get all subscriptions under the tenant and checks if 'supportsHttpsTrafficOnly' property is enabled or not and enable it.

The ARM template will create the LogicApp which will run in recurrence with frequency of once in a week. The workflow will loop through each subscription in a tenant and scan the available storage accounts. Based on the results it will check if the property "supportsHttpsTrafficOnly" is enabled or not. If the property is not enabled, it will set the property to true and update the storage account. In order to be able to deploy the resources, your user account needs to be granted Contributor rights on the target Resource Group. The LogicApp uses a system-assigned Managed Identity to access data from API. You need to make sure to grant the Managed Identity 'Security Reader' and 'Storage Account Contributor' rights to all Azure subscriptions.

Click on the **Deploy to Azure** button to create the Logic App in a target resource group.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FSecure%20Storage%20Remediation/SecureStorageRemediation_Template.json" target="_blank">
<img src="https://aka.ms/deploytoazurebutton"/></a>

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FSecure%20Storage%20Remediation/SecureStorageRemediation_Template.json" target="_blank">
<img src="https://aka.ms/deploytoazuregovbutton"/></a>
 
**To assign Managed Identity to specific scope:**

Make sure you have User Access Administrator permissions for this scope.
Go to the subscription/management group page.
Press 'Access Control (IAM)' on the navigation bar.
Press '+Add' and 'Add role assignment'.
Choose 'Security Reader' and 'Storage Account Contributor'.
Assign access to Logic App.
Press 'save'.

