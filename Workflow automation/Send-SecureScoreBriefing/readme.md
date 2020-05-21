# Send-SecureScoreBriefing
author: Nathan Swift

This playbook will send a weekly Security Score briefing to the Compliance and Security teams to help track progress on Secure Score per Subscription.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%20automation%2FSend-SecureScoreBriefing%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton""/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%20automation%2FSend-SecureScoreBriefing%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

**Additional Post Install Notes:**

Ensure you are using the Import-SecureScore playbook to send security score data your log analytics workspace. Be sure to authorize the API connections created.