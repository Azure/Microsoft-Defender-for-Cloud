# Get-SecureScoreData
Author: Nicholas DiCola

This playbook uses the new Secure Score API and Assessments API to pull Secure Score, Controls and Assessments into a Log Analytics workspace every 24 hours.

The ARM template will create a Log Analytics workspace, API Connection, Logic App Playbook and an Azure Monitor Workbook.
As part of the template parameters you will need to choose under which subscription and resource group to deploy the resources. It is highly recommended to create a new resource group, which will contain all the required resources for the playbook.

The playbook uses a Managed Identity. You need to assign reader permissions to subscriptions you want to export for the Manage Identity (explained in details below). Notice you can assign permissions only as an owner and make sure all selected subscriptions registered to Azure Security Center.

You have 3 options:
1. You can assign reader permissions at the management group level for the managed identity. (preferred)
2. You can assign reader permissions for the Managed Identity for each one of the subscriptions you want to get data on.
3. You can use the provided powershell script `Grant-SubscriptionPermissions.ps1` to add the identity to all subscriptions.

To deploy main template:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%2520Score%2FGet-SecureScoreData%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%2520Score%2FGet-SecureScoreData%2Fazuredeploy.json" target="_blank">
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
8. Choose 'Get-SecureScoreData' Logic App.
9. Press 'save'.


Please notice that only on the first time you need to manually trigger the Logic App after adding the Managed Identity to the subscriptions. In the deployed Log Analytics you can find your data under Custom Logs. Four new tables will be created: SecureScore_CL, SecureScoreAssessments_CL, SecureScoreControls_CL and Subscriptions_CL. On the first time it can take few minutes until you will be able to see the data in your Log Analytics workspace.
