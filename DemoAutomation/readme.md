# Simple Windows 2019 Server VM with RCE Vulnerabilities and Key Vault Demo Environment

This template allows you to deploy a simple Windows 2019 Server build version 2803, which includes RCE vulnerabilities out of the box (unless you run an update post install). This will deploy a D2s_v3 size VM in the resource group location and return the fully qualified domain name of the VM. To avoid updating the VM, it is configured with Manual Update only. Also, it deploys a Key Vault, a Managed System Identity assigned to the VM with permission to access the Key Vault, and Net Framework 4.8 for additional vulnerabilities.

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FGastori%2Fcloudmapdemoenv%2Fmain%2Fdeploy.json)



## Note: for PoC only
