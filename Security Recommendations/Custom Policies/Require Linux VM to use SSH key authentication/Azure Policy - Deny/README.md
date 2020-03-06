# Azure Policy Deny Sample

This policy sample will block the creation of Linux VMs which use password instead of SSH key authentication for SSH. Use of SSH key is more secure than passwords. The policy checks if the VM Publisher and Offer are in a list of known Linux offers..
You can not deploy this via template deployment in the Azure Portal.  You can deploy the template
using Azure CLI or Azure PowerShell.

# Azure PowerShell

New-AzDeployment -Location location -TemplateFile path-to-template

# Azure CLI

az deployment create --location location --template-file path-to-template
