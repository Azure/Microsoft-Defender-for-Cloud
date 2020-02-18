# Logic App sample to remediate

This Logic App deployment template is provided to apply Azure Disk Encryption to VMs. It will loop through all Security Center recommendations in all subscriptions to find unencrypted VM disks, then encrypt the VMs. Note that this will also create Key Vaults in each region VMs exist. This Logic App relies on a Managed Identity, which must be enabled for the app and given appropriate permissions in the subscriptions.

<a
href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FRemediation%2520scripts%2FDisk%2520encryption%2520should%2520be%2520applied%2520on%2520virtual%2520machines%2FLogic%2520App%2FEnable-AzureDiskEncryption.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

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
