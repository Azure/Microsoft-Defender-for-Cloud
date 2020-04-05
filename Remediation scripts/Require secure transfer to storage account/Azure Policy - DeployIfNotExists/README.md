# Azure Policy DeployIfNotExists Sample

This policy sample will remediate and set HTTPs only to storage accounts.
You can deploy this via template deployment in the Azure Portal. You can deploy the template
using Azure CLI or Azure PowerShell.

# Azure PowerShell

New-AzDeployment -Location location -TemplateFile path-to-template

# Azure CLI

az deployment create --location location --template-file path-to-template
