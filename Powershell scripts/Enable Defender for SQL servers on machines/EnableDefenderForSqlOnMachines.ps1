#Requires -Modules Az.Resources, Az.OperationalInsights, Az.Accounts, Az,  Az.PolicyInsights, Az.Security

<#
.SYNOPSIS
Enable Defender for SQL servers on machines.

.DESCRIPTION
This script enables Defender for SQL servers on machines at a subscription level.

.PARAMETER SubscriptionId
[Required] The Azure subscription ID that you want to enable Defender for SQL servers on machines for.

.PARAMETER RegisterSqlVmAgnet
[Required] A flag indicating whether to register the SQL VM Agent in bulk. For more information: https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/sql-agent-extension-manually-register-vms-bulk?view=azuresql

.PARAMETER WorkspaceResourceId
[Optional] The resource ID of the Log Analytics workspace, if you want to use a custom one and not the default one.

.PARAMETER DataCollectionRuleResourceId
[Optional] The resource ID of the data collection rule, if you want to use a custom one and not the default one.

.PARAMETER UserAssignedIdentityResourceId
[Optional] The resource ID of the user-assigned identity, if you want to use a custom one and not the default one.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$true)]
    [bool]$RegisterSqlVmAgnet,
    [string]$WorkspaceResourceId,
    [string]$DataCollectionRuleResourceId,
    [string]$UserAssignedIdentityResourceId
)

$policyDefinitionReferenceIdsDefault = @(
    "MDC_DfSQL_AddUserAssignedIdentity_VM",
    "MDC_DfSQL_DeployWindowsAMA_VM",
    "MDC_DfSQL_DeployMicrosoftDefenderForSQLWindowsAgent_VM",
    "MDC_DfSQL_DeployDefaultWorkspace",
    "MDC_DfSQL_AMA_DefaultPipeline_VM",
    "MDC_DfSQL_DeployWindowsAMA_Arc",
    "MDC_DfSQL_DeployMicrosoftDefenderForSQLWindowsAgent_Arc",
    "MDC_DfSQL_AMA_DefaultPipeline_Arc",
    "MDC_DfSQL_AMA_DefaultPipeline_DCRA_Arc"
)

$policyDefinitionReferenceIdsCustom = @(
    "MDC_DfSQL_AddUserAssignedIdentity_VM",
    "MDC_DfSQL_DeployWindowsAMA_VM",
    "MDC_DfSQL_DeployMicrosoftDefenderForSQLWindowsAgent_VM",
    "MDC_DfSQL_AMA_UserWorkspacePipeline_VM",
    "MDC_DfSQL_DeployWindowsAMA_Arc",
    "MDC_DfSQL_DeployMicrosoftDefenderForSQLWindowsAgent_Arc",
    "MDC_DfSQL_AMA_UserWorkspacePipeline_Arc",
    "MDC_DfSQL_AMA_UserWorkspacePipeline_DCRA_Arc"
)

$policyInitiativeNames = @{
    "default" = "d7c3ea3a-edf3-4bd5-bd64-d5b635b05393"
    "custom" = "de01d381-bae9-4670-8870-786f89f49e26"
}

$defaultLocation = "eastus"

$ErrorActionPreference = "Stop"

# Function to assign policy initiative definition with parameters
function AssignPolicyInitiative {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        [Parameter(Mandatory=$true)]
        [string]$PolicyInitiativeName,
        [Parameter(Mandatory=$true)]
        [string]$AssignmentName,
        [string]$WorkspaceResourceId
    )

    $policySetDefinition = Get-AzPolicySetDefinition -Name $PolicyInitiativeName

    if($AssignmentName.Length -gt 63) {
        $AssignmentName = $AssignmentName.Substring(0, 63)
    }

    # Assign policy initiative definition
    $assignmentParams = @{
        "PolicySetDefinition" = $policySetDefinition
        "Name" = $AssignmentName
        "PolicyParameterObject" = @{}
    }

    if ($WorkspaceResourceId) {
        if ($WorkspaceResourceId.StartsWith("/")) {
            $WorkspaceResourceId = $WorkspaceResourceId.Substring(1)
        }
        
        # Get the Log Analytics workspace
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName ($WorkspaceResourceId -split '/')[3] -Name ($WorkspaceResourceId -split '/')[7]

        $assignmentParams["PolicyParameterObject"]["userWorkspaceResourceId"] = "/" + $WorkspaceResourceId
        $assignmentParams["PolicyParameterObject"]["workspaceRegion"] = $workspace.Location
        $assignmentParams["PolicyParameterObject"]["userWorkspaceId"] = $workspace.CustomerId
        
        if ($DataCollectionRuleResourceId) {
            $assignmentParams["PolicyParameterObject"]["bringYourOwnDcr"] = $true
            $assignmentParams["PolicyParameterObject"]["dcrResourceId"] = $DataCollectionRuleResourceId
        }
    }

    if ($UserAssignedIdentityResourceId) {
        $assignmentParams["PolicyParameterObject"]["bringYourOwnUserAssignedManagedIdentity"] = $true
        $assignmentParams["PolicyParameterObject"]["userAssignedIdentityResourceId"] = $UserAssignedIdentityResourceId
    }

    return New-AzPolicyAssignment @assignmentParams -Scope "/subscriptions/$SubscriptionId" -IdentityType "SystemAssigned" -Location $defaultLocation
}

function Get-SubscriptionIdFromWorkspaceResourceId {
    param(
        [Parameter(Mandatory=$true)]
        [string]$WorkspaceResourceId
    )

    return ($WorkspaceResourceId -split '/')[2]
}

# Main script

try
{  
    Write-Host "Connecting to Azure..."
    Connect-AzAccount

    Write-Host "Selecting Azure subscription $SubscriptionId..."
    # Select the subscription
    Select-AzSubscription -SubscriptionId $SubscriptionId

    # SQL VM bulk registration
    $bulkRegistration = $RegisterSqlVmAgnet

    $policyDefinitionReferenceIds = $policyDefinitionReferenceIdsDefault

    $policyAssignment = @{}

    Write-Host "Assigning policy initiative definition with parameters..."

    # Assign policy initiative definition with parameters
    if ($WorkspaceResourceId) {
        $policyAssignmentName = "Defender for SQL on SQL VMs and Arc-enabled SQL Servers- Custom"

        $policyAssignment = AssignPolicyInitiative -SubscriptionId $SubscriptionId -PolicyInitiativeName $policyInitiativeNames["custom"] -AssignmentName $policyAssignmentName -WorkspaceResourceId $WorkspaceResourceId
        $policyDefinitionReferenceIds = $policyDefinitionReferenceIdsCustom
    }
    else {
        $policyAssignmentName = "Defender for SQL on SQL VMs and Arc-enabled SQL Servers"
        $policyAssignment = AssignPolicyInitiative -SubscriptionId $SubscriptionId -PolicyInitiativeName $policyInitiativeNames["default"] -AssignmentName $policyAssignmentName
    }

    # Create custom role assignments
    $permissions = @(
        "92aaf0da-9dab-42b6-94a3-d43ce8d16293", # Log Analytics Contributor
        "9980e02c-c2be-4d73-94e8-173b1dc7cf3c", # Virtual Machine Contributor
        "749f88d5-cbae-40b8-bcfc-e573ddc772fa", # Monitoring Contributor
        "cd570a14-e51a-42ad-bac8-bafd67325302", # Azure Connected Machine Resource Administrator
        "b24988ac-6180-42a0-ab88-20f7382dd24c"  # Contributor
    )

    Write-Host "Setting role assignment to policy assignment's Managed Identity..."

    # Set role assignment to policy assignment's Managed Identity
    $permissions | Foreach-Object -Parallel {
        try {
            New-AzRoleAssignment -ObjectId $using:policyAssignment.Identity.PrincipalId -RoleDefinitionId $_ -Scope "/subscriptions/$using:SubscriptionId"
        }
        catch {
            Write-Host "Failed to assign role $_ to policy assignment's Managed Identity on subscription level."
            throw $_.Exception.Message
        }
    }

    # If the workspace is different from the subscription, assign roles to the policy assignment's Managed Identity on workspace level
    if($WorkspaceResourceId -and ((Get-SubscriptionIdFromWorkspaceResourceId -WorkspaceResourceId $WorkspaceResourceId) -ne $SubscriptionId)) {
        $permissions | Foreach-Object -Parallel {
            try {
                New-AzRoleAssignment -ObjectId $using:policyAssignment.Identity.PrincipalId -RoleDefinitionId $_ -Scope $using:WorkspaceResourceId
            }
            catch {
                Write-Host "Failed to assign role $_ to policy assignment's Managed Identity on workspace level."
                throw $_.Exception.Message
            }
        }
    }

    # Create and run remediation step
    Write-Host "Creating and running remediation steps..."
    $remediationSuccess = $true
    $exceptionMessage = ""
    $policyDefinitionReferenceIds | Foreach-Object -Parallel {
        try {
            $remediationParams = @{
                "PolicyAssignmentId" = $using:policyAssignment.PolicyAssignmentId
                "Name" = "Remediation-$_"
                "Scope" = "/subscriptions/$using:SubscriptionId"
                "ResourceDiscoveryMode" = "ReEvaluateCompliance"
                "PolicyDefinitionReferenceId" = $_
            }
        
            # Run remediation step
            Start-AzPolicyRemediation @remediationParams
        }
        catch {
            Write-Host "Failed to create and run remediation step for policy assignment $policyAssignmentName. Exception: $($_.Exception.Message)"
            $remediationSuccess = $false
            $exceptionMessage = $_.Exception.Message
        }
    }

    if($remediationSuccess) {
        Write-Host "Remediation steps created and executed successfully."
    }
    else {
        throw $exceptionMessage
    }

    # Register SQL VMs for bulk registration / sql vm checkbox
    if ($bulkRegistration) {
        Write-Host "Registering SQL VMs for bulk registration..."
        try {
            $apiUrl = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Features/providers/Microsoft.SqlVirtualMachine/features/BulkRegistration/register?api-version=2021-07-01"
            $accessToken = Get-AzAccessToken
            
            Invoke-RestMethod -Uri $apiUrl -Method Post -Headers @{"Authorization" = "Bearer $($accessToken.Token)"}
        }
        catch {
            Write-Host "Failed to register SQL VMs for bulk registration. Exception: $($_.Exception.Message)"
            throw $_.Exception.Message
        }
    }
    else {
        Write-Host "SQL VMs will not be registered for bulk registration."
    }

    # Turn on pricing bundle
    Write-Host "Turning on the pricing bundle..."
    Select-AzSubscription -SubscriptionId $SubscriptionId
    Set-AzSecurityPricing -Name SqlServerVirtualMachines -PricingTier Standard
}
catch {
    Write-Host "Failed to enable SQL ATP on-premises in scale. Exception: $($_.Exception.Message)"
}