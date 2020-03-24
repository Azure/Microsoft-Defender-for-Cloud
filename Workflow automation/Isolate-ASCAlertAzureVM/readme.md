# Isolate-ASCAlertAzureVM
author: Nathan Swift

This playbook will generate a ISOLATE Subnet, A Deny All NSG and place on ISOLATE Subnet, It will place the Azure VM on ISOLATE Subnet restarting and dropping any persisted connections, It will generate a PIP and Azure Bastion Host.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FIsolate-ASCAlertAzureVM%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FIsolate-ASCAlertAzureVM%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

**Additional Post Install Notes:**

The Logic App creates and uses a Managed System Identity (MSI) to authenticate and authorize against management.azure.com for several Azure networking functions.  

Assign RBAC 'Reader' role to the Logic App at the Subscription level.
Assign RBAC 'Network Contributor' role to the Logic App at the Subscription level.
Assign RBAC 'Managed Application Contributor Role' role to the Logic App at the Subscription level.
