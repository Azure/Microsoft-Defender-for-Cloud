# Enable AI workloads
This script will help you activate the AI workloads plan in Microsoft Defender for Cloud. 

## Description 


There are three ways to activate AI workloads plan:

1. Powershell 
#### Example for Powershell command:

```PowerShell
Set-AzSecurityPricing -Name "AI" -PricingTier "Standard" -Extension '[{"name":"AIPromptEvidence","isEnabled":"True","additionalExtensionProperties":null}]'
Set-AzSecurityPricing -Name "AI" -PricingTier "Standard" -Extension '[{"name":"AIPromptEvidence","isEnabled":"False","additionalExtensionProperties":null}]'
```
[Reference Documentation](https://learn.microsoft.com/en-us/powershell/module/az.security/set-azsecuritypricing?view=azps-12.2.0)

2. Azure CLI 
#### Example for Azure CLI:

```CLI
az security pricing create -n AI --tier standard --extensions name=AIPromptEvidence isEnabled=true
az security pricing create -n AI --tier standard --extensions name=AIPromptEvidence isEnabled=false
```
[Reference Documentation](https://learn.microsoft.com/en-us/cli/azure/security/pricing?view=azure-cli-latest)

3. Azure Policy

Activate AI workloads plan using a built-in policy "Enable threat protection for AI worklaods" 

#### Link
The powershell script ready to use is posted in the following location:
[https://github.com/Azure/Azure-Security-Center/tree/master/Powershell scripts](https://github.com/Azure/Azure-Security-Center/tree/master/Powershell%20scripts)
