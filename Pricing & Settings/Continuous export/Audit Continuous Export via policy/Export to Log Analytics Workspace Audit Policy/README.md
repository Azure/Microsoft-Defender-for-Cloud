# Audit Export to Log Analytics Workspace

Audit if there aren't any Export configurations to Log Analytics Workspace in your subscription.
This Azure Policy definition will check if at least one Export configuration to Log Analytics Workspace exists in your subscription, and if not then this subscription will be non-compliant on this policy. 

## Create custom policy in Azure Portal

"Deploy to Azure" button will open this policy definition in the portal, where you should fill:
1) Definition location (For example a management group. When you assign this policy the assignment scope must be within this definition location).
2) Name (For example "Audit Export to Log Analytics Workspace")
3) Optional parameters are: description and category.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FPricing%2520%2526%2520Settings%252FContinuous%2520export%252FAudit%2520Continuous%2520Export%2520via%2520policy%252FExport%2520to%2520Log%2520Analytics%2520Workspace%2520Audit%2520Policy%252FExportToLogAnalyticsWorkspaceAuditPolicy.json)

[Learn more about Continuous Export](https://docs.microsoft.com/en-us/azure/security-center/continuous-export)

## Assign the custom policy

After the deployment, you should assign the policy and set the desired scope and input parameters.

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
