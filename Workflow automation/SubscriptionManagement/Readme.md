# Subscription Management for Azure Security Center, Secure Score Monitoring
**Author: Safeena Begum**

Azure Management Groups provide the ability to effeiciently manage access, policies and reporting on groups of subscriptions as well as effectively manage the entire Azure estate by performing actions on the root management group. Organizations can organize subscriptions into management groups and apply governance policies to the management groups so that all subscriptions within a management group automatically inherit the policies applied to the management group and that would help monitor Secure Score percentage.

## Playbook Description: 
With the above understanding of Management Groups, in an event where users create new subscriptions often, stays in the Root Management Group. We heard your feedback on the difficulties in managing monitored vs non-monitored subscriptions for Secure Score. 
So, this automation queries Root management group for subscription(s) that are not in any management groups and notifies you accordingly for better management of Secure Score.

## Prerequisites: 
The automation uses User Assigned Managed Identity to be able to query Root management groups. Please follow the steps below:
a. Create User Assigned Managed Identity. Follow the instructions listed in the doc to [create user-assigned managed identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-portal#create-a-user-assigned-managed-identity)
b. Once User-assgined managed identity is created, make sure to provide Reader Permissions to the Root Management Group  
c. Enable and add the above created User assigned Identity to the Logic App. Follow the instructions [here](https://docs.microsoft.com/en-us/azure/logic-apps/create-managed-service-identity#create-user-assigned-identity-in-the-azure-portal) to assign the User assigned identity to the Logic App. 

## How it works: 
The Automation that runs weekly, queries RootManagement Group to query and identify the subscription(s) that are directly assigned to the RootManagement Group and not any child MG. 
If subscription(s) are found in the Root Management Group, the LogicApp sends an email listing the Subscription name and ID and Action. (as shown in the 'image 1')
If the intent of the subscription assigned to the Root management group was on purpose, you have an option to exclude any subscription (s) you want to exclude from this query. The hyperlink in the email will add the subscription id to the storage account's table storage. 
In the next run (weekly) it will not display the subscriptions you added to the Exclusion list (table storage) and notifies only newly added subscription(s) via email. 

![](https://github.com/Azure/Azure-Security-Center/blob/master/Workflow%20automation/SubscriptionManagement/Images/EmailOutput_Example.PNG)
***

You can deploy the main template by clicking on the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https://github.com/Azure/Azure-Security-Center/blob/master/Workflow%20automation/SubscriptionManagement/azuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https://github.com/Azure/Azure-Security-Center/blob/master/Workflow%20automation/SubscriptionManagement/azuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a> 

***

# Acknowledgements
Thanks to Nicholas DiCola & Gilad Elyashar for this wonderful automation idea. <br>
