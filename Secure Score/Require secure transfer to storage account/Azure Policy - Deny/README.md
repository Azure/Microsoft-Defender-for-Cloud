# Azure Policy Deny Sample

This policy sample will block users from setting HTTPs only to disabled on storage accounts.
You can not deploy this via template deployment in the Azure Portal.  You can deploy the template
using Azure CLI or Azure PowerShell.

# Azure PowerShell

New-AzDeployment -Location <location> -TemplateFile <path-to-template>

# Azure CLI

az deployment create --location <location> --template-file <path-to-template>

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
