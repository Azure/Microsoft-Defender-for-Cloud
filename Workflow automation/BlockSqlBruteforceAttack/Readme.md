# Block attacking IP addresses in an NSG as response to a SQL brute force attack on Azure VM when an Defender for SQL on machines alert is triggered/created

**Author: Ayelet Shpigelman**

When Microsoft Defender for Cloud detects a SQL brute force attack on Azure VM, this playbook will create a security rule in the NSG attached to the VM's network interface to deny inbound traffic to SQL port from the attacking IP addresses.
This automation will consider the following settings:

1. The Logic App will create one Network Security Group (NSG) rule with the lowest possible (= free) priority number. For example, if there are existing NSG rules with priorities from 100 to 105, and from 110 to 1,000, the Logic App will create the rule with priority 106.
2. The NSG rule will contain all attacking IP addresses that are mentioned in the alert.
3. The NSG rule name will be unique, consisting of _BlockSqlBruteForce_ and the priority number. For example, if the priority is 106, the name will be _BlockSqlBruteForce-106_.

You can deploy the main template by clicking on the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FBlockSqlBruteforceAttack%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FBlockSqlBruteforceAttack%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a> 

The ARM template will create the Logic App Playbook, an API connection to ASCalert and a [new Workflow automation](https://docs.microsoft.com/en-us/azure/security-center/workflow-automation) in Microsoft Defender for Cloud. In order to be able to deploy the resources, your user account needs to be granted Contributor rights on the target Subscription.

The Logic App uses a system-assigned Managed Identity. The template will assign [Contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor) permissions to the Logic App's Managed Identity so it is able to create an NSG rule once there is an attack detected.
Notice that you can assign permissions only if your account has been assigned Owner or User Access Administrator roles, and make sure all selected subscriptions registered to Microsoft Defender for Cloud.
