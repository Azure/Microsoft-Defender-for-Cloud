# Time indicators - Average time taken to remediate resources
**Author: Safeena Begum**

Azure Security Center continuously assesses your resources, subscriptions, and organization for security issues. It then aggregates all the findings into a single score so that you can tell, at a glance, your current security situation: the higher the score, the lower the identified risk level. 

## Playbook Description: 
Azure Security Center uses assessments to determine if a resource is flagged as healthy or unhealthy or if a recommendation is not applicable to it. With the new time indicator fields firstEvaluationDate and statusChangeDate, Azure Security Center helps you to react on unhealthy resources. This Automation artifact that runs weekly 
exports the assessments identified by Azure security center, to a custom log analytics workspace and calculates the average time taken to remediate unhealthy resources in your environment, so that you can better calculate the RCA for changes. This playbook will send you a notification email that will inform you about Overtime Graph, Top 5 Security Controls that are unhealthy as well as total count of unhealthy resources for the last 24hrs that needs action immediately to better harden your resources. 
With the help of this OverTimeReport, you can easily calculate RCA for changes as well as stay on top of healthy resources that needs action.

![](https://github.com/Azure/Azure-Security-Center/blob/safeenab786-patch-4/Workflow%20automation/Notify-AverageTimeGraph-TimeIndicators/notificationMail.png)

The template in this folder will deploy a LogicApp and and API connections to Office 365. During the deployment, it is highly recommended to create a new resource group, which will contain all the required resources for the playbook. 

You can deploy the main template by clicking the button below:

***

To deploy main template:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%20automation%2FNotify-AverageTimeGraph-TimeIndicators%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%20automation%2FNotify-AverageTimeGraph-TimeIndicators%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a> 

***

Once you have deployed all resources, you need to authorize the Office 365 API connection. In addition to that, the Logic App uses a system-assigned Managed Identity to query the APIs used in this playbook. To enable the Logic App for this step, you need to grant the Managed Identity at least Reader or Security Reader access rights.

You have 3 options:

1. You can assign reader permissions at the management group level for the managed identity. (preferred)
2. You can assign reader permissions for the Managed Identity for each one of the subscriptions you want to get data on.
3. You can use the provided powershell script Grant-SubscriptionPermissions.ps1 to add the identity to all subscriptions.

To assign Managed Identity to specific scope: 
1. Make sure you have owner permissions for this scope.
2. Go to the subscription/management group page.
3. Press 'Access Control (IAM)' on the navigation bar.
4. Press '+Add' and 'Add role assignment'.
5. Choose Reader role.
6. Assign access to Logic App.
7. Choose the subscription where the logic app was deployed.
8. Choose 'Notify-AverageTimeGraph' Logic App.
9. Press 'save'.

To authorize the API connection:

1. Go to the Resource Group you have used to deploy the template resources.
2. Select the Office365 API connection and press 'Edit API connection'.
3. Press the 'Authorize' button.
4. Make sure to authenticate against Azure AD.
5. Press 'save'.

## NOTE: 
Make sure to manually trigger the playbook once you've met all prerequisites. Since this Playbook creates a custom log in the Log Analytics Workspace, for the first few runs the logicapp will error out until there's data in the workspace for it to pull. Once the custom table gets populated in the workspace, you'll start recieving the results.
