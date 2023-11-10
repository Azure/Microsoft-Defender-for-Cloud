# Identifying Subscriptions that are not Managed by Microsoft Defender for Cloud
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
By default this automation runs weekly and queries the Root Management group to identify any new subscription(s) that are directly assigned to the root management group. 
If one or more subscriptions are found in the Root management group, the Logic App will send an email with the following details: Subscription Name, Subscription ID, Action, Status of the subscription (If MDC is enabled or disabled). Image 1 has an example of how this email look like:
Make sure to add the subscription(s) to the Management Groups in order to start monitoring using Microsoft Defender for Cloud.
The automation artifact also creates a Storage account with a table storage in it during the deployment of the template. If the intent of assigning the subscription to the root management group was on purpose, you could exclude the subscription from being displayed in the email on next run by just clicking on the hyperlink ‘Exclude <subscriptionname>’ under the Action column of Image 1. 
In the next run (weekly) it will not display the subscriptions you added to the Exclusion list (table storage) and notifies only newly added subscription(s) via email. 

![](https://github.com/Azure/Azure-Security-Center/blob/master/Workflow%20automation/SubscriptionManagement/Images/ExampleEmailOutput.PNG)
***

You can deploy the main template by clicking on the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FSubscriptionManagement%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FSubscriptionManagement%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a> 

***
Check out this [blog](https://techcommunity.microsoft.com/t5/azure-security-center/identifying-subscriptions-that-are-not-managed-by-azure-security/ba-p/2111408) to understand more about the automation and for step by step instructions. 

# Acknowledgements
Thanks to Nicholas DiCola & Gilad Elyashar for this wonderful automation idea. <br>
