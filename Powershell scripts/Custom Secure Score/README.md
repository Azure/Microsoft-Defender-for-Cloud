# Custom Secure Score
The Powershell module here allows you to map your own policy definitions into existing Secure Score controls in Azure Security Center.

> Please note that Custom Secure Score is a preview feature and is subject to change.

# Prerequisites
This Powershell module comes with the following prerequisites:

- Powershell version must be at least 5.
- Az Powershell module should be installed (a.k.a Azure Powershell). 
> If it is not installed, the module will install it for you.

# Feature prerequisites
The feature works by customizing the metadata of an existing custom policy initiative, in a way which Azure Security Center can then consume.

This means that in order to properly use the feature, you would need the following:
1. An existing custom policy initiative
2. Write access to said initiative

# Usage
1. Download the module and place it in a folder.
2. Open Powershell and change the directory to where the module was downloaded.
3. Import the module: `Import-Module .\CustomSecureScore.psm1`

After importing the module, the following CMDlets will become available:
 - `Get-SecureScoreControlKeys` - returns an array of all supported control keys.
 - `New-SecureScoreControlMapping` - creates a new control mapping object. It requires the following parameters:
   - `ControlKey` - The key of the control to which you'd like to map additional assessments, e.g. `ASC_EnableMFA`. The list of supported controls can be obtained by executing the `Get-SecureScoreControlKeys` CMDlet. In any case, the command validates the control key, so you can't get it wrong.
   - `PolicyDefinitionIds` - An array of the policy definition IDs which you'd like to add to the control. The IDs should be identical to the policy definition IDs which were defined inside the initiative.
 - `Update-AzSecurityCenterSecureScoreControlMappings` - This CMDlet will update the metadata of the policy set definition object which represents the initiative, and when specified, will persist the changes to Azure Policy. It requires the following parameters:
   - `PolicySetDefinition` - An object representing the policy initiative to be updated (usually acquired by executing `Get-AzPolicySetDefinition`)
   - `ControlMappings` - The array of control mappings to apply to the policy initiative's metadata (created by `New-SecureScoreControlMapping`)
   - `PersistToAzurePolicy` - An optional switch. If specified, changes will be persisted to Azure Policy. If not, only the object passed as `PolicySetDefinition` will be updated in-memory.

## Example
```powershell
# Import the module
Import-Module .\CustomSecureScore.psm1
# Perform actual login to Azure
Connect-AzAccount
# Get the relevant policy set definition - Modify this to fit your own custom policy initiative
$policySetDefinitionId = "/subscriptions/bccb4c1d-7346-4a9e-9d1b-eee2be282bba/providers/Microsoft.Authorization/policySetDefinitions/77eb6fde-19e5-44d5-ac2e-d57a95d05001"
$policySetDef = Get-AzPolicySetDefinition -Id $policySetDefinitionId

# Get policy definition IDs - these should be from the policy set definition
$policyDef1 = "/providers/Microsoft.Authorization/policyDefinitions/0015ea4d-51ff-4ce3-8d8c-f3f8f0179a56"
$policyDef2 = "/providers/Microsoft.Authorization/policyDefinitions/6134c3db-786f-471e-87bc-8f479dc890f6"

# Create mappings
$secureScoreMappings = @( $(New-SecureScoreControlMapping ASC_EncryptDataInTransit -PolicyDefinitionIds @($policyDef1, $policyDef2)))
# Apply the mappings and persist to Azure Policy
Update-AzSecurityCenterSecureScoreControlMappings -PolicySetDefinition $policySetDef -ControlMappings $secureScoreMappings -PersistToAzurePolicy
```

