# Export-ASCQualysVulnerabities
author: Yaniv Shasha

This playbook is for continuous export.  Continuous export doesnt have a way to export the detail data for Qualys vulnerability results.  This palybook will export the data daily to a Log Analytics workspace.

It does a single subscription.  You could add a loop to get subscriptions using https://docs.microsoft.com/en-us/rest/api/subscription/2018-03-01-preview/operations/list the parse each subscription.

NOTE:  The playbook uses a managed identity so you will need to grant access for the managed identity to subscriptions.


<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FPricing%2520%2526%2520Settings%252FContinuous%2520export%252FExport-ASCQualysVulnerabities%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton""/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FPricing%2520%2526%2520Settings%252FContinuous%2520export%252FExport-ASCQualysVulnerabities%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>