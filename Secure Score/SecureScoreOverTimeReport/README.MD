# Weekly Secure Score Progress Report
**Author: Safeena Begum**

Azure Security Center continuously assesses your resources, subscriptions, and organization for security issues. It then aggregates all the findings into a single score so that you can tell, at a glance, your current security situation: the higher the score, the lower the identified risk level. 

## Playbook Description: 
It is very important to monitor Secure Score and stay on top of the recommendations displayed by Security Center. This Automation artifact that runs weekly will send you a notification email displaying Secure Score Weekly report, in which your current secure score across subscriptions will be displayed along with Secure Score OverTime Report in a graph format and the Security controls that are open plus the Top 5 security controls that needs to be taken care of immediately. With the help of this OverTimeReport, you can easily keep track of Secure Score as well as stay on top of the new/exisiting security controls that needs to be remediated. 

## Requirements:
This automation is querying Log Analytics Workspace data. Using Continuous export feature of Azure Security Center, make sure you are streaming Security Center data to the Log Analytics workspace. Also make sure you have enabled export of secure score. In the drop-down menu you can choose to export both the overall score of the subscription and the score per control. Please follow this article for enabling Continuous export option

The ARM template uses your Log Analytics workspace and creates two API Connections, O365 and an Azure Monitor Logs API connection. As part of the template parameters you will need to enter your Log Analytics Workspace Subscription ID, Resource Group Name and Workspace Name.  During the deployment, it is highly recommended to create a new resource group, which will contain all the required resources for the playbook. 

The playbook uses a Managed Identity. You need to assign reader permissions to the subscriptions you want to export for the Manage Identity (explained in details below).Notice you can assign permissions only as an owner and make sure all selected subscriptions registered to Azure Security Center.

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
8. Choose 'SecureScoreOverTimeReport' Logic App.
9. Press 'save'.

***

To deploy main template:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%20Score%2FSecureScoreOverTimeReport%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%20Score%2FSecureScoreOverTimeReport%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a> 

***

# Acknowledgements
Thanks to *Yuri Diogenes* for this wonderful automation idea. <br>
