# Deploy Auditing on SQL servers

This policy ensures that Auditing is enabled on SQL Servers for enhanced security & compliance. It
will automatically create a Log Analytics workspace in the same region as the SQL server to store audit
records.

## Try on Portal

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com/Azure/Azure-Security-Center/Secure%20Score/Enable%20auditing%20for%20the%20SQL%20server/Azure%20Policy%20DeployIfNotExists/Log%20Analytics/azurepolicy.json)

## Try with PowerShell

````powershell
$definition = New-AzPolicyDefinition -Name "deploy-sql-server-auditing" -DisplayName "Deploy Auditing on SQL servers" -description "This policy ensures that Auditing is enabled on SQL Servers for enhanced security and compliance. It will automatically create a storage account in the same region as the SQL server to store audit records." -Policy 'https://raw.githubusercontent.com/Azure/Azure-Security-Center/Secure%20Score/Enable%20auditing%20for%20the%20SQL%20server/Azure%20Policy%20DeployIfNotExists/Log%20Analytics/azurepolicy.rules.json' -Parameter 'https://raw.githubusercontent.com/Azure/Azure-Security-Center/Secure%20Score/Enable%20auditing%20for%20the%20SQL%20server/Azure%20Policy%20DeployIfNotExists/Log%20Analytics/azurepolicy.parameters.json' -Mode Indexed
$definition
$assignment = New-AzPolicyAssignment -Name <assignmentname> -Scope <scope> -workspacesResourceGroup <resourceGroupName> -PolicyDefinition $definition
$assignment
````

## Try with CLI

````cli
az policy definition create --name 'deploy-sql-server-auditing' --display-name 'Deploy Auditing on SQL servers' --description 'This policy ensures that Auditing is enabled on SQL Servers for enhanced security and compliance. It will automatically create a storage account in the same region as the SQL server to store audit records.' --rules 'https://raw.githubusercontent.com/Azure/Azure-Security-Center/Secure%20Score/Enable%20auditing%20for%20the%20SQL%20server/Azure%20Policy%20DeployIfNotExists/Log%20Analytics/azurepolicy.rules.json' --params 'https://raw.githubusercontent.com/Azure/Azure-Security-Center/Secure%20Score/Enable%20auditing%20for%20the%20SQL%20server/Azure%20Policy%20DeployIfNotExists/Log%20Analytics/azurepolicy.parameters.json' --mode Indexed

az policy assignment create --name <assignmentname> --scope <scope> --policy "deploy-sql-server-auditing" --params '{ "workspacesResourceGroup": { "value": "myResourceGroup" } }'
````