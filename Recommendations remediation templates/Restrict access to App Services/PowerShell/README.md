
# What this PowerShell script walks through

  1. Seeking all of your subscrptions within your tenant, looking for the following rule "Restrict access to App Services" within your Azure Security Center recommendtations list
  2. You'll be prompted for the WebApp service that is too not meeting the correct restrctions for your secure score, asking for the following required configurations

    A. Name
    B. Action ( "Alloy or Deny' )
    C. Priority
    D. IP address block
  3. This process will repeat untill all App services have been configured
More information mentioned here : https://docs.microsoft.com/en-us/azure/app-service/app-service-ip-restrictions


## Module Requirements

  Az.Resources
  Az.Accounts
  Az.Security

## Known Issues
    
  AzureRM Module mixed in with Az Module will break scripting due to conflict of current migration


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
