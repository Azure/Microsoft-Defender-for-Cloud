

# What this PowerShell script walks through

More information: https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security 


 1. Seeking all of your subscrptions within your tenant, looking for the following rule "Restrict access to storage accounts with firewall and virtual network configurations" within your Azure Security Center recommendtations list
 2. The script will check if the service has been configured for harderning, if not, it'll change the "Allow all" to "Deny All"
 2. You'll be prompted for the IP address or IP Address range for your stroage acccounts
 3. This process will repeat untill all stroage Accounts have been configured

- (Get-AzStorageAccountNetworkRuleSet -ResourceGroupName "myresourcegroup" -AccountName "mystorageaccount").DefaultAction
- Update-AzStorageAccountNetworkRuleSet -ResourceGroupName "myresourcegroup" -Name "mystorageaccount" -DefaultAction Deny
- (Get-AzStorageAccountNetworkRuleSet -ResourceGroupName "myresourcegroup" -AccountName "mystorageaccount").VirtualNetworkRules
- (Get-AzStorageAccountNetworkRuleSet -ResourceGroupName "myresourcegroup" -AccountName "mystorageaccount").IPRules
- Update-AzStorageAccountNetworkRuleSet -ResourceGroupName "myresourcegroup" -Name "mystorageaccount" -Bypass AzureServices,Metrics,Logging
 - Add-AzStorageAccountNetworkRule -ResourceGroupName "myresourcegroup" -AccountName "mystorageaccount" -IPAddressOrRange "16.17.18.0/24"

## Module Requirements

  Az.Resources
  Az.Accounts
  Az.Storage
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
