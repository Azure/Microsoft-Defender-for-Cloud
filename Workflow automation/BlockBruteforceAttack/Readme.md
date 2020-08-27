# Block the IPs in NSG as response to a brute force attack when an ASC alert is triggered/created
**Author: Safeena Begum**

When Azure Security Center detects a brute force attack, this playbook will create a security rule in the NSG attached to the VM to deny inbound traffic from the IP addresses attached to the alert. 

You can deploy the main template by clicking on the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FBlockBruteforceAttack%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FBlockBruteforceAttack%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a> 

The ARM template will create the Logic App Playbook and an API connection to Office 365, and ASCalert. In order to be able to deploy the resources, your user account needs to be granted Contributor rights on the target Resource Group.

The Logic App uses a system-assigned Managed Identity. You need to assign [Contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor) permissions or [Security Reader](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#security-reader) and [Network Contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#network-contributor) permissions to the Logic App's Managed Identity so it is able to create an NSG rule once there is an attack detected. You need to assign these roles on all subscriptions or management groups you want to monitor and manage resources in using this playbook.
Notice that you can assign permissions only if your account has been assigned Owner or User Access Administrator roles, and make sure all selected subscriptions registered to Azure Security Center.

In addition to that, you need to authorize the Office 365 API connection so it can access the sender mailbox and send the emails from there.

To assign Managed Identity to specific scope:
1. Make sure you have User Access Administrator or Owner permissions for this scope.
2. Go to the subscription/management group page.
3. Press 'Access Control (IAM)' on the navigation bar.
4. Press '+Add' and 'Add role assignment'.
5. Choose the respective role.
6. Assign access to Logic App.
7. Choose the subscription where the logic app was deployed.
8. Choose 'BlockBruteForceAttackedIP' Logic App.
9. Press 'save'.

To authorize the API connection:
1. Go to the Resource Group you have used to deployed the template resources.
2. Select the Office365 API connection and press 'Edit API connection'.
3. Press the 'Authorize' button.
4. Make sure to authenticate against Azure AD.
5. Press 'save'.

Once you have deployed and authorized the Logic App, you can create a new Workflow automation in Azure Security Center:
1. Go to Azure Security Center and select the _Workflow automation_ button in the navigation pane.
2. Select _+ Add workflow automation_.
3. Enter the values needed. Especially make sure you select _Threat detection alerts_ as the trigger condition.
4. In the _Alert name contains_ field, enter _brute_.
5. In the _actions_ area, make sure to select the _BlockBruteForceAttackedIP_ Logic App you have deployed and authorized before.
6. Press 'create'.