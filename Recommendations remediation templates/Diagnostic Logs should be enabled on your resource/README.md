# Enable diagnostic logging automatically on your resources

## Azure Policy - deployIfNotExists

This collection of samples are providing better security logs to your resources by enabling Diagnostic Logs and retaining them up to a year in Azure Policy. When configuring your diagnostic logs settings, you can export the logs into three targets. After the deployment, you need to assign it and set the desired scope. Also it will enable you to create a remediation task which will change the resource settings to enable Diagnostic Logs.
You can use each target, that is not in the same subscription, as the one emitting logs. The user who configures the setting must have the appropriate RBAC access to both subscriptions.

## Storage Account

You can export data to blob storage, export to CSV, and generate graphs in Excel.

## Event Hub

You can export data to Event Hubs and correlate with data from other Azure services.

## Log Analytics

You can export data to Azure Monitor logs and view data in your own Log Analytics workspace.

[Learn more about policy definition structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)
Please provide us your input and suggestions on [this form](https://forms.office.com/Pages/ResponsePage.aspx?id=v4j5cvGGr0GRqy180BHbR_CzuCpXTVhBswcSTF6htOtUMkJKR0pLWUNES0VHVVU1QUMwWFRaR0VCWC4u)
E-mail us at libaruch@microsoft.com with your questions.

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
