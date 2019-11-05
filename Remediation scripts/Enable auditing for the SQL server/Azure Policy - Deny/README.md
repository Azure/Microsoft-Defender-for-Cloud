# Deny disable of Auditing on SQL servers

This policy ensures that Auditing cannot be set to disabled on SQL Servers for enhanced security & compliance.

## Try on Portal

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FRemediation%2520scripts%2FEnable%2520auditing%2520for%2520the%2520SQL%2520server%2FAzure%2520Policy%2520-%2520Deny%2Fazurepolicy.json
)

## Try with PowerShell

````powershell
$definition = New-AzPolicyDefinition -Name "deny-disable-sql-server-auditing" -DisplayName "Deny Disable Auditing on SQL servers" -description "This policy ensures that Auditing cannot be disabled on SQL Servers for enhanced security and compliance." -Policy 'https://raw.githubusercontent.com/Azure/Azure-Security-Center/Secure%20Score/Enable%20auditing%20for%20the%20SQL%20server/Azure%20Policy%20-%20Deny/azurepolicy.rules.json' -Parameter 'https://raw.githubusercontent.com/Azure/Azure-Security-Center/Secure%20Score/Enable%20auditing%20for%20the%20SQL%20server/Azure%20Policy%20-%20Deny/azurepolicy.parameters.json' -Mode Indexed
$definition
$assignment = New-AzPolicyAssignment -Name <assignmentname> -Scope <scope> -PolicyDefinition $definition
$assignment
````

## Try with CLI

````cli
az policy definition create --name 'deny-disable-sql-server-auditing' --display-name 'Deny Disable Auditing on SQL servers' --description 'This policy ensures that Auditing cannot be disabled on SQL Servers for enhanced security and compliance.' --rules 'https://raw.githubusercontent.com/Azure/Azure-Security-Center/Secure%20Score/Enable%20auditing%20for%20the%20SQL%20server/Azure%20Policy%20-%20Deny/azurepolicy.rules.json' --params 'https://raw.githubusercontent.com/Azure/Azure-Security-Center/Secure%20Score/Enable%20auditing%20for%20the%20SQL%20server/Azure%20Policy%20-%20Deny/azurepolicy.parameters.json' --mode Indexed

az policy assignment create --name <assignmentname> --scope <scope> --policy "deploy-sql-server-auditing"
````