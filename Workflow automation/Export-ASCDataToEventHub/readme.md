# Export ASC Data to Azure EventHub
Author: Tom Janetscheck

This Playbook leverages the Secure Score and Assessment APIs to regularly (every 24h) pull information about Secure Score, Controls, and Assessments into an EventHub.

The ARM template will create an EventHub, API connection, and LogicApp Playbook. In order to be able to deploy these resources, your user account needs to be granted [Contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor) rights on the target Resource Group. The LogicApp uses a system-assigned [Managed Identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) to access data from the APIs. You need to make sure to grant the Managed Identity [Read](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#reader) access to all Azure subscriptions you want to export security data from. You need to have the [User Access Administrator](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#user-access-administrator) role assigned to your user account for the respective scope (Management Group or Subscriptions) in order to assign access rights for the Managed Identity.

You have three different options to assign access rights to the Managed Identity:

1. Grant read access to the Managed Identity on Management Group level to include all subscriptions within this scope (preferred).
2. Grant read access to the Managed Identity on every single subscription you want to export data from.
3. Use the provided PowerShell script `Grant-SubscriptionPermissions.ps1` to grant read access to all subscriptions within your scope.

You can deploy the main template by clicking on the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FExport-ASCDataToEventHub%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FExport-ASCDataToEventHub%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a> 

To assign Managed Identity to specific scope:
1. Make sure you have owner permissions for this scope.
2. Go to the subscription/management group page.
3. Press 'Access Control (IAM)' on the navigation bar.
4. Press '+Add' and 'Add role assignment'.
5. Choose Reader role.
6. Assign access to Logic App.
7. Choose the subscription where the logic app was deployed.
8. Choose 'Get-ASCData' Logic App.
9. Press 'save'.

Please notice that only on the first time you need to manually trigger the Logic App after adding the Managed Identity to the subscriptions. The LogicApp will then run every 24 hours to export a snapshot of Subscription, Secure Score, Recommendations, and Assessments to the EventHub.
