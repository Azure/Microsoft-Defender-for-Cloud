#PREREQUISITES
# Check powershell version
if ($host.Version.Major -lt 5)
{
	Write-Host "Supported Windows versions are Server 2016/Windows 10 or above"
	break
}

#Check if Az installed, install if not
$AzModule = Get-InstalledModule -Name Az -ErrorAction SilentlyContinue
if ($null -eq $AzModule) 
{
	Write-Warning "Azure PowerShell module not found"
	#check for Admin Privleges
	$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

	if (-not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)))
	{
	    #No Admin, install to current user
	    Write-Warning -Message "Can not install Az Module for all users. You are not running as Administrator"
	    Write-Information -Message "Installing Az Module to Current User Scope"
	    Install-Module Az -Scope CurrentUser -Force
	    Install-Module Az.Security -Scope CurrentUser -Force
        Install-Module Az.Accounts -Scope CurrentUser -Force
	}
	Else
	{
	    #Admin, install to all users
	    Write-Information -Message "Installing Az Module to all users"
	    Install-Module -Name Az -AllowClobber -Force
	    Import-Module -Name Az.Accounts -Force
        Import-Module -Name Az.Security -Force
	}
}

$AzResourcesModule = Get-InstalledModule -Name "Az.Resources" -ErrorAction SilentlyContinue
if ($null -eq $AzResourcesModule) 
{
    Write-Host "Az.Resources module was not found, please install it first."
    break
}
elseif ($AzResourcesModule.Version.Major -lt 2) 
{
    Write-Host "Az.Resources module must be at least version 2.0.0, please update it and try again."
    break
}

class SecureScoreControlMapping {
    [ValidateSet(
        "ASC_ProtectAgainstDDoS",
        "ASC_EnableMFA",
        "ASC_EncryptDataInTransit",
        "ASC_RestrictUnauthorizedNetworkAccess",
        "ASC_ImplementSecurityBestPractices",
        "ASC_ApplyAdaptiveApplicationControl",
        "ASC_ApplyDataClassification",
        "ASC_EnableAuditingAndLogging",
        "ASC_EnableEncryptionAtRest",
        "ASC_EnableEndpointProtection",
        "ASC_ApplySystemUpdates",
        "ASC_ManageAccessAndPermissions",
        "ASC_RemediateSecurityConfigurations",
        "ASC_SecureManagementPorts",
        "ASC_RemediateVulnerabilities")]
    [string]
    $controlKey

    [string[]]
    $policyDefinitionIds
}

Function New-SecureScoreControlMapping {
    Param (
        [ValidateSet(
            "ASC_ProtectAgainstDDoS",
            "ASC_EnableMFA",
            "ASC_EncryptDataInTransit",
            "ASC_RestrictUnauthorizedNetworkAccess",
            "ASC_ImplementSecurityBestPractices",
            "ASC_ApplyAdaptiveApplicationControl",
            "ASC_ApplyDataClassification",
            "ASC_EnableAuditingAndLogging",
            "ASC_EnableEncryptionAtRest",
            "ASC_EnableEndpointProtection",
            "ASC_ApplySystemUpdates",
            "ASC_ManageAccessAndPermissions",
            "ASC_RemediateSecurityConfigurations",
            "ASC_SecureManagementPorts",
            "ASC_RemediateVulnerabilities")]
        [string]
        $ControlKey,

        [string[]]
        $PolicyDefinitionIds
    )

    return [SecureScoreControlMapping]@{ controlKey = $ControlKey; policyDefinitionIds = $PolicyDefinitionIds }
}

Function Get-Property {
    Param(
        $Object,

        [string]
        $PropertyName,

        [switch]
        $CreateIfNotExist,

        $DefaultCreationValue
    )

    $noteProperty = Get-Member -InputObject $Object | Where-Object { $_.MemberType -eq "NoteProperty" } | Where-Object { $_.Name -eq $PropertyName }
    if (($null -eq $noteProperty) -And $CreateIfNotExist) {
        $Object | Add-Member -NotePropertyName $PropertyName -NotePropertyValue $DefaultCreationValue
    }

    return $Object.$PropertyName
}

Function Test-ControlMappings {
    Param(
        [Parameter(Mandatory=$true)]
        [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.Policy.PsPolicySetDefinition]
        $PolicySetDefinition,

        [Parameter(Mandatory=$true)]
        [SecureScoreControlMapping[]]
        $ControlMappings
    )

    $policyDefinitionIds = @($PolicySetDefinition.Properties.PolicyDefinitions.policyDefinitionId)
    foreach ($mapping in $ControlMappings) {
        foreach ($policyDefId in $mapping.PolicyDefinitionIds) {
            if (-Not ($policyDefinitionIds -ccontains $policyDefId)) {
                $errorMessage = @"
Bad mapping for control key $($mapping.ControlKey):

Policy set definition does not contain the following policy definition ID: $policyDefId

Valid policy definition IDs:
$policyDefinitionIds


"@

                throw $errorMessage
            }
        }
    }
}

Function Update-AzSecurityCenterSecureScoreControlMappings {
    Param(
        [Parameter(Mandatory=$true)]
        [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.Policy.PsPolicySetDefinition]
        $PolicySetDefinition,

        [Parameter(Mandatory=$true)]
        [SecureScoreControlMapping[]]
        $ControlMappings,

        [switch]
        $PersistToAzurePolicy
    )

    Test-ControlMappings -PolicySetDefinition $PolicySetDefinition -ControlMappings $ControlMappings -ErrorAction Stop

    $metadata = $PolicySetDefinition.Properties.Metadata
    $securityCenter = Get-Property -Object $metadata -PropertyName "securityCenter" -CreateIfNotExist -DefaultCreationValue $(New-Object -TypeName psobject)
    Get-Property -Object $securityCenter -PropertyName "enabled" -CreateIfNotExist -DefaultCreationValue $true | Out-Null
    $secureScore = Get-Property -Object $securityCenter -PropertyName "secureScore" -CreateIfNotExist -DefaultCreationValue $(New-Object -TypeName psobject)
    Get-Property -Object $secureScore -PropertyName "controlMappings" -CreateIfNotExist -DefaultCreationValue @() | Out-Null

    $securityCenter.enabled = $true
    $secureScore.controlMappings = $ControlMappings

    if ($PersistToAzurePolicy) {
        return $(Set-AzPolicySetDefinition -Id $PolicySetDefinition.PolicySetDefinitionId -Metadata $(ConvertTo-Json -Depth 10 $PolicySetDefinition.Properties.Metadata))
    }
}

Function Get-AzSecurityCenterSecureScoreControlMappings {
    Param(
        [Parameter(Mandatory=$true)]
        [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.Policy.PsPolicySetDefinition]
        $PolicySetDefinition
    )

    $metadata = $PolicySetDefinition.Properties.Metadata
    if ($null -ne $metadata) {
        $securityCenterMetadata = $metadata.securityCenter
        if ($null -ne $securityCenterMetadata) {
            $secureScoreMetadata = $securityCenterMetadata.secureScore
            if ($null -ne $secureScoreMetadata) {
                $controlMappings = $secureScoreMetadata.controlMappings

                if ($null -ne $controlMappings) {
                    return @($controlMappings | ForEach-Object { [SecureScoreControlMapping]$_ })
                }
            }
        }
    }
}

Function Get-SecureScoreControlKeys {
    return @(
            "ASC_ProtectAgainstDDoS",
            "ASC_EnableMFA",
            "ASC_EncryptDataInTransit",
            "ASC_RestrictUnauthorizedNetworkAccess",
            "ASC_ImplementSecurityBestPractices",
            "ASC_ApplyAdaptiveApplicationControl",
            "ASC_ApplyDataClassification",
            "ASC_EnableAuditingAndLogging",
            "ASC_EnableEncryptionAtRest",
            "ASC_EnableEndpointProtection",
            "ASC_ApplySystemUpdates",
            "ASC_ManageAccessAndPermissions",
            "ASC_RemediateSecurityConfigurations",
            "ASC_SecureManagementPorts",
            "ASC_RemediateVulnerabilities")
}

Export-ModuleMember -Function Get-SecureScoreControlKeys
Export-ModuleMember -Function Update-AzSecurityCenterSecureScoreControlMappings
Export-ModuleMember -Function New-SecureScoreControlMapping
Export-ModuleMember -Function Get-AzSecurityCenterSecureScoreControlMappings