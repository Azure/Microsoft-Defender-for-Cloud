# Azure Policy - deployIfNotExists
This Azure Policy definition will ensure that during the creation of new Azure SQL databases, transparant data encryption (TDE) will be enabled. Also it will enable you to create a remediation task which will enable TDE.<br>

After the deployment, you need to assign it and set the desired scope.

### Deployment with PowerShell
```powershell
New-AzDeployment -Name <yourDeploymentName> -Location <yourLocation> -TemplateFile 'https://github.com/Azure/Azure-Security-Center/blob/master/Secure%20Score/Web%20Application%20should%20only%20be%20accessible%20over%20HTTPS/Azure%20Policy%20-%20deployIfNotExists/azuredeploy.json' -Verbose
```
