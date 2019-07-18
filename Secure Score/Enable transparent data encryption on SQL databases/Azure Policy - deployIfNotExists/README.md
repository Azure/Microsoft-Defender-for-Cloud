# Azure Policy - deployIfNotExists
This Azure Policy definition will ensure that during the creation of new Azure SQL databases, transparant data encryption (TDE) will be enabled. Also it will enable you to create a remediation task which will enable TDE.<br>

After the deployment, you need to assign it and set the desired scope.

### Deployment with PowerShell
```powershell
New-AzDeployment -Name <yourDeploymentName> -Location <yourLocation> -TemplateFile 'https://raw.githubusercontent.com/Azure/Azure-Security-Center/master/Secure%20Score/Enable%20transparent%20data%20encryption%20on%20SQL%20databases/Azure%20Policy%20-%20deployIfNotExists/azuredeploy.json' -Verbose
```
