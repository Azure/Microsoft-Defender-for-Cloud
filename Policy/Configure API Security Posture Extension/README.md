# Fine Grain Control of Defender CSPM (DCSPM)

Configure DCSPM's API Security Extension

## Try on Portal

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-For-Cloud%2Fmain%2FPolicy%2FConfigure-API-Security-Posture-Extension%2Fazurepolicy.json)


## Try with PowerShell:
````powershell
$definition = New-AzPolicyDefinition -Name "$(New-Guid)" `
                                    -DisplayName 'Configure Microsoft Defender CSPM API Security Extension' `
                                    -Description 'Defender Cloud Security Posture Management (CSPM) provides enhanced posture capabilities and a new intelligent cloud security graph to help identify, prioritize, and reduce risk. Defender CSPM is available in addition to the free foundational security posture capabilities turned on by default in Defender for Cloud.' `
                                    -Policy 'https://raw.githubusercontent.com/Azure/Microsoft-Defender-For-Cloud/main/Policy/Configure-API-Security-Posture-Extension/azurepolicy.rules.json'`
                                    -Parameter 'https://raw.githubusercontent.com/Azure/Microsoft-Defender-For-Cloud/main/Policy/Configure-API-Security-Posture-Extension/azurepolicy.parameters.json'`
                                    -Mode Indexed
$definition
$assignment = New-AzPolicyAssignment -Name <assignmentName>`
                                    -Scope <scope>`
                                    -PolicyDefinition $definition
$assignment
````



### Contributors:
Dick Lake
Walner Dort
