# Get-SecureScoreData
author: Nicholas DiCola

This playbook uses the new Secure Score API to pull Secure Score, Controls and Assements into a Log Analytics workspace every 24 hours.

The ARM template will create a Log Analytics workspace, API Connection, Logic App Playbook and an Azure Monitor Workbook
The playbook uses a Managed Identity.  You will need to run azuredeploy2.json to the same subscription which will grant access to the subscription for the identity.

If you have many subscriptions, you have 2 options.
1. You can assign reader permissions at he management group level for the managed identity. (preferred)
2. You can use the provided powershell script to add the identity to all subscriptions.

There are 

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%20automation%2FGet-SecureScoreData%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton""/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%20automation%2FGet-SecureScoreData%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>
