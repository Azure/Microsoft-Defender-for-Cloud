
# What this PowerShell script walks through

When using Azure Management Group to manage policy assignment to subscriptions, you need to ensuare that the ASC Default Policy is assigned to the Management Group level and that the default ASC policy is removed from the subscription level. For more information about this scenario, read [Gain tenant-wide visibility for Azure Security Center](https://docs.microsoft.com/en-us/azure/security-center/security-center-management-groups).

This script can be used when there are dual levels of ASC policies assignments at Management group and subscription level. If you want ASC policy to be inherited correctly at the management group, 
  this script Removes ASC Default policy assignment at subscription level by doing the following steps

  1. Seeking all of your management groups and a match for a ASC Default definition in policy assignment at Management Group Level.
  2. Seeking all subscrptions within your managemnt group, Looking for the following policy assignment name 'ASC Default' applied at subscription level.
  3. If a match is found remove the policy assignment.

More information mentioned here : https://docs.microsoft.com/en-us/azure/governance/management-groups/overview


## Module Requirements

  PowerShell 7
  Az.Resources


## Known Issues
    

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
