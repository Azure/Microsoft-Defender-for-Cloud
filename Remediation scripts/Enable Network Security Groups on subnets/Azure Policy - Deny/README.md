# Azure Policy Enable NSG on Subnets Sample

This policy sample will allow you to assign an existing network security group (NSG) to every virtual subnet. You specify the ID of the network security group to use.  
You can deploy the template using Azure CLI, Azure PowerShell or the deploy to Azure button below:

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%2520Score%2FEnable%2520Network%2520Security%2520Groups%2520on%2520subnets%2FAzure%2520Policy%2520-%2520Deny%2FAssignNSGtoSub%2520Deny.json)

# Azure PowerShell

New-AzDeployment -Location location -TemplateFile path-to-template

# Azure CLI

az deployment create --location location --template-file path-to-template

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
