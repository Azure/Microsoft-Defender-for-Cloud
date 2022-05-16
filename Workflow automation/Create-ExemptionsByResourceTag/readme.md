# Create resource exemptions from Azure Security Benchmark (ASB) built-in initiative for specific resource tags

**Author: Lara Goldstein**

This automation runs on a scheduled interval to create exemptions from the ASB initiative to exempt resources with a specified tag from Secure Score calculations.

You can deploy the main template by clicking on the button below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Flaragoldstein13%2FMicrosoft-Defender-for-Cloud%2Fpatch-1%2FWorkflow%2520automation%2FCreate-ExemptionsByResourceTag%2FAzuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>


The ARM template will create the Logic App Automation. In order to be able to deploy the resources, your user account needs to be granted Contributor rights on the target Resource Group.

The Logic App uses a system-assigned Managed Identity. You need to assign [Reader](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#reader) permissions and [Resource Policy Contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#resource-policy-contributor) permissions to the Logic App's Managed Identity so it is able to query for resources with a specific tag in Azure Resource Graph and create the appropriate policy exemptions. You need to assign these roles on all subscriptions or management groups you want to manage resources in using this playbook.
Notice that you can assign permissions only if your account has been assigned Owner or User Access Administrator roles, and make sure all selected subscriptions registered to Microsoft Defender for Cloud.

**To assign Managed Identity to specific scope:**

1. Make sure you have User Access Administrator or Owner permissions for this scope.
2. Go to the subscription/management group page.
3. Press _Access Control (IAM)_ on the navigation bar.
4. Press _+Add_ and _Add role assignment_.
5. Select the respective role.
6. Assign access to Logic App.
7. Select the subscription where the logic app was deployed.
8. Select _Create-ExemptionsByResourceTag_ Logic App.
9. Press _save_.
