# Samples for discovering tenant wide subscription management

These samples provide various ways to discover your tenant information with mulitlpe subscriptions for Azure Security Center.

* AzASCSubCount.ps1
    - This is walking through the following: (precheck for modules included in script)
        1. Logging into your tenant - suggested global admin to get full tenant/all subscription information
        2. Checking each subscription within your tenant and collecting the information to be parsed (Note this can take up to 30 seconds per subscription)
        3. After checking each subscription it'll provide a text format of which subscrptions it searched, which subscriptions have "free" and "standard" enabled, for which type. Addtionaly it's checking to see a total of Virtual Machines that have been provisioned or not provisioned within your Azure Tenant.





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
