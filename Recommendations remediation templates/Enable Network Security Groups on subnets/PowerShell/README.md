# PowerShell script to remediate

This sample script is provided to remediate the "Enable Network Security Group on subnet"
recommendation in Azure Security Center.  The script will enumerate the task from Security Center,
loop through each subscription and associate an existing NSG to a subnet. For this script to work, you need
to have a NSG already created. If you don't have an NSG, you can use New-AzureRmNetworkSecurityGroup to create one.
For more information, read [New-AzureRmNetworkSecurityGroup](https://docs.microsoft.com/en-us/powershell/module/azurerm.network/new-azurermnetworksecuritygroup?view=azurermps-6.13.0)

#Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
