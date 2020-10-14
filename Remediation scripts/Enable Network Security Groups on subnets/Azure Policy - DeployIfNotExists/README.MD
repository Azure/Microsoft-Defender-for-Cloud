# Assign an existing Network Security Group to subnets
Author: Lior Arviv

This policy enables you to protect virtual network subnets with an existing network security group (NSG) found in the same subscription.

## Try on Portal

[![Deploy to Azure](https://docs.microsoft.com/en-us/azure/governance/policy/media/deploy/deploybutton.png)](https://portal.azure.com/?#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FRemediation%2520scripts%2FEnable%2520Network%2520Security%2520Groups%2520on%2520subnets%2FAzure%2520Policy%2520-%2520DeployIfNotExists%2Fassign-nsg-to-subnets.json)

### Please note
The current version of this policy will query out all subnets without NSG including subnets for VPN gateway, Azure Bastion, etc.

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