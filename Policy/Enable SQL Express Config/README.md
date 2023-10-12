# Deploy SQL Vulnerability Express Config

SQL vulnerability assessment is an easy-to-configure service that can discover, track, and help you remediate potential database security misconfigurations.  Results of the scan include actionable steps to resolve each issue and provide customized remediation scripts where applicable.  You can custome an assessment report for your environment by setting an acceptable baseline for:
* Permission configurations
* Feature configurations
* Database Settings

Express Configuration is the default procedure that lets you configure vulnerability assessment without a dependency on an external storage account to store baseline and scan result data.  

> NOTE: As of 9/1/2023 Express Configuration is only supported on Azure SQL Database and Azure Synapse Dedicated SQL Pools (formerly known as SQL DW)

This policy detects instances of Classic Configuration and converts it to Express Configuration.  </b> It does not migrate baselines over</b>

## Try on Portal

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-For-Cloud%2Fmain%2FPolicy%2FConfigure-DCSPM-Extensions%2Fazurepolicy.json)


## Try with PowerShell:
````powershell
$definition = New-AzPolicyDefinition -Name "$(New-Guid)" `
                                    -DisplayName 'Configure Microsoft Defender CSPM to be enabled - fine grain' `
                                    -Description 'Defender Cloud Security Posture Management (CSPM) provides enhanced posture capabilities and a new intelligent cloud security graph to help identify, prioritize, and reduce risk. Defender CSPM is available in addition to the free foundational security posture capabilities turned on by default in Defender for Cloud.' `
                                    -Policy 'https://raw.githubusercontent.com/Azure/Microsoft-Defender-For-Cloud/main/Policy/Configure-DCSPM-Extensions/azurepolicy.rules.json'`
                                    -Parameter 'https://raw.githubusercontent.com/Azure/Microsoft-Defender-For-Cloud/main/Policy/Configure-DCSPM-Extensions/azurepolicy.parameters.json'`
                                    -Mode Indexed
$definition
$assignment = New-AzPolicyAssignment -Name <assignmentName>`
                                    -Scope <scope>`
                                    -PolicyDefinition $definition
$assignment
````



### Contributors:
Dick Lake
