# Azure Policy - deployIfNotExists
This Azure Policy definition will ensure that during the creation of new Azure SQL databases, transparant data encryption (TDE) will be enabled. Also it will enable you to create a remediation task which will enable TDE.<br>

After the deployment, you need to assign it and set the desired scope.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FRemediation%2520scripts%2FEnable%2520transparent%2520data%2520encryption%2520on%2520SQL%2520databases%2FAzure%2520Policy%2520-%2520deployIfNotExists%2Fazuredeploy.json
)



### Deployment with PowerShell
```powershell
New-AzDeployment -Name <yourDeploymentName> -Location <yourLocation> -TemplateFile 'https://raw.githubusercontent.com/Azure/Azure-Security-Center/master/Secure%20Score/Enable%20transparent%20data%20encryption%20on%20SQL%20databases/Azure%20Policy%20-%20deployIfNotExists/azuredeploy.json' -Verbose
```