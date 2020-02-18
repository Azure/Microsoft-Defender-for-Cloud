# Samples for remediating "Enable the built-in vulnerability assessment solution on virtual machines"

* PowerShell script - Will loop through and rememdiate each instance
    - Requires Azure (Az) PowerShell module
* Logic App - Uses the REST API to enumerate and remediate each instance
    - Requires a Managed Identity, which must be enabled and granted appropriate access to the resources to the subscriptions.
* Policy
    - Policy does not yet fully support Azure Disk Encryption operations.

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
