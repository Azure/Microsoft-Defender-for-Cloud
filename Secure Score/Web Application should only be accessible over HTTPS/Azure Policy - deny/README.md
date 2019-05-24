# Azure Policy - Deny
This Azure Policy definition will **deny** the creation of new Web Applications which do not have HTTPS enabled. Also it will prevent someone from changing the setting from HTTPS to HTTP for existing resources. <br><br>
After deployment you need to assign it and set the desired scope.

### Deployment with PowerShell
```powershell
New-AzDeployment -Name <yourDeploymentName> -Location <yourLocation> -TemplateFile 'https://github.com/Azure/Azure-Security-Center/blob/master/Secure%20Score/Web%20Application%20should%20only%20be%20accessible%20over%20HTTPS/Azure%20Policy%20-%20deny/azuredeploy.json' -Verbose
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
