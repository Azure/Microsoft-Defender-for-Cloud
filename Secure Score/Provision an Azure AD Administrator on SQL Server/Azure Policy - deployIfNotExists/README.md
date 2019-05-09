# Azure Policy - deployIfNotExists
This Azure Policy definition will ensure that during the creation of a new SQL Server, an Azure AD administrator must be added. Also it will enable you to create a remediation task which will add a Azure AD administrator.<br>

After the deployment, you need to assign it and set the desired scope.

### Deployment with PowerShell
```powershell
New-AzDeployment -Name <yourDeploymentName> -Location <yourLocation> -TemplateFile 'https://raw.githubusercontent.com/Azure/Azure-Security-Center/master/Secure%20Score/Provision%20an%20Azure%20AD%20Administrator%20on%20SQL%20Server/Azure%20Policy%20-%20deployIfNotExists/azuredeploy.json' -Verbose
```


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
