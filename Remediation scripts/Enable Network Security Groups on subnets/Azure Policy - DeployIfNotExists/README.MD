# Assign an existing Network Security Group to subnets
Author: Lior Arviv

This policy enables you to protect virtual network subnets with an existing network security group (NSG) found in the same subscription.

### Please note
The current version of this policy will query out all subnets without NSG including subnets for VPN gateway, Azure Bastion, etc.

## Try on Portal

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https://raw.githubusercontent.com/liorarviv/Azure-Security-Center/master/Remediation%20scripts/Enable%20Network%20Security%20Groups%20on%20subnets/Azure%20Policy%20-%20DeployIfNotExists/assign-nsg-to-subnets.json)

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