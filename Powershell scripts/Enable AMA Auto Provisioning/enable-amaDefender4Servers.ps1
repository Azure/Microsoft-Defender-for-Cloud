<#
  .DESCRIPTION
  This script will enable auto provisioning of the Azure Monitor Agent for Defender for Servers

  .PARAMETER subscriptionId
  The id of the subscription to enable Defender for Servers AMA on.
	
  .PARAMETER workspaceResourceId
  The full workspace resource ID for using a custom workspace. This paramater is optional, if not specified the default workspace will be used. 

  .PARAMETER managementGroupName
  The Management Group Name to enable Defender for Servers AMA on. Note, the Tenant Root Group management group name is acutally a GUID and not "Tenant Root Group"

  .EXAMPLE
  Enable Auto-provisioning configuration for AMA with the default workspace
  .\enable-amaDefender4Servers.ps1 -subscriptionId 'ada06e68-4678-4210-443a-c6cacebf41c5'
	
  .EXAMPLE
  Enable Auto-provisioning configuration for AMA with a custom workspace
  .\enable-amaDefender4Servers.ps1 -subscriptionId 'ada06e68-4678-4210-443a-c6cacebf41c5' -workspaceResourceId '/subscriptions/11c61180-d5dc-4a02-b2da-1f06b8245691/resourcegroups/sentinel-prd/providers/microsoft.operationalinsights/workspaces/sentinel-prd'

 .EXAMPLE
  Enable Auto-provisioning configuration for AMA with the default workspace on a management group
  .\enable-amaDefender4Servers.ps1 -managementGroupName 'Finance'
#>

param(
    [Parameter(ValueFromPipeline = $true, Mandatory=$true, ParameterSetName = 'sub')]
    [string]$subscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$workspaceResourceId,

    [Parameter(Mandatory = $false, ParameterSetName = 'mg')]
    [string]$managementGroupName
)

# Check for required modules
$requiredModules = 'Az.Accounts', 'Az.Resources', 'Az.Security', 'Az.PolicyInsights'
$availableModules = Get-Module -ListAvailable -Name $requiredModules
$modulesToInstall = $requiredModules | where-object {$_ -notin $availableModules.Name}
ForEach ($module in $modulesToInstall){
    Write-Host "Installing Missing PowerShell Module: $module" -ForegroundColor Yellow
    Install-Module $module -force
}

If(!(Get-AzContext)){
    Write-Host 'Connecting to Azure Subscription' -ForegroundColor Yellow
    Connect-AzAccount -Subscription $subscriptionId -WarningAction SilentlyContinue | Out-Null
}

If ($managementGroupName){
    # Get all child managment groups and subscriptions
    $mg = Get-AzManagementGroup -GroupName $managementGroupName -Recurse -Expand -WarningAction SilentlyContinue
    $mgSubs = Get-AzManagementGroupSubscription -GroupName $managementGroupName -WarningAction SilentlyContinue
    ForEach ($childMG in ($mg.Children | where Type -eq 'Microsoft.Management/managementGroups')){
        $mgSubs += Get-AzManagementGroupSubscription -GroupName $childMG.Name -WarningAction SilentlyContinue
    }

    # Disable Existing Legacy Log Analytics Auto Provisioning Settings
    ForEach ($mgSub in $mgSubs){
        $currentSub = Set-AzContext -Subscription $mgSub.DisplayName
        Write-Host ('Disabling Existing Legacy Log Analytics Auto Provisioning Settings on Subscription:', $currentSub.Subscription.Name)
        Set-AzSecurityAutoProvisioningSetting -Name "default" | Out-Null
    }

    # Policy Assignment Scope
    $scope = $mg.Id

}else{
    # Set Current Subscription
    $currentSub = Set-AzContext -Subscription $subscriptionId

    # Disable Existing Legacy Log Analytics Auto Provisioning Settings
    Write-Host ('Disabling Existing Legacy Log Analytics Auto Provisioning Settings on Subscription:', $currentSub.Subscription.Name)
    Set-AzSecurityAutoProvisioningSetting -Name "default" | Out-Null

    # Policy Assignment Scope
    $scope = "/subscriptions/$($currentSub.Subscription.Id)"
}

# Policy Description
$description = 'This policy assignment was automatically created by Azure Security Center for agent installation as configured in Security Center auto provisioning.'

If ($workspaceResourceId){
    $definition = Get-AzPolicySetDefinition -Id '/providers/Microsoft.Authorization/policySetDefinitions/500ab3a2-f1bd-4a5a-8e47-3e09d9a294c3'
    $displayName = 'Custom Defender for Cloud provisioning Azure Monitor agent'
    $paramSet = @{
        Name = $(New-Guid).Guid.substring(0,23) 
        DisplayName = $displayName
        Description = $description
        PolicySetDefinition = $definition
        IdentityType = 'SystemAssigned' 
        Location = 'centralus'
        Scope = $scope
        PolicyParameterObject = @{
            userWorkspaceResourceId = $workspaceResourceId
            workspaceRegion = (Get-AzResource -ResourceId $workspaceResourceId).Location
        }
    }
}Else{
    $definition = Get-AzPolicySetDefinition -Id '/providers/Microsoft.Authorization/policySetDefinitions/362ab02d-c362-417e-a525-45805d58e21d'
    $displayName = 'Default Defender for Cloud provisioning Azure Monitor agent'
    $paramSet = @{
        Name = $(New-Guid).Guid.substring(0,23) 
        DisplayName = $displayName
        Description = $description
        PolicySetDefinition = $definition
        IdentityType = 'SystemAssigned' 
        Location = 'centralus'
        Scope = $scope
    }
}

# Create the Policy Assignment
Write-Host ('Creating policy assignment {0} on {1}' -f $paramSet.DisplayName,  $paramSet.Scope)
$assignment = New-AzPolicyAssignment @paramSet -WarningAction SilentlyContinue

# Create Role Assignments for the system managed identity
$roles = @()
ForEach ($PolicyDefinition in $definition.Properties.PolicyDefinitions){
    $roles += ((Get-AzPolicyDefinition -Id $PolicyDefinition.policyDefinitionId).properties.policyRule.then.details.roleDefinitionIds -split "/")[-1]
}

ForEach ($role in ($roles | Get-Unique)){
    Write-Host ('Creating {0} role assignment for remmedition on: {1}' -f $role, $scope)
    New-AzRoleAssignment -Scope $scope -ObjectId $assignment.Identity.PrincipalId -RoleDefinitionId $role -ErrorAction SilentlyContinue | Out-Null
}

# Create Remmediation Tasks
Write-Host 'Creating Remmediation Tasks'
ForEach ($PolicyDefinition in $definition.Properties.PolicyDefinitions){
    Start-AzPolicyRemediation -Name $PolicyDefinition.policyDefinitionReferenceId -PolicyAssignmentId $assignment.PolicyAssignmentId -PolicyDefinitionReferenceId $PolicyDefinition.policyDefinitionReferenceId -ParallelDeploymentCount 30 -ResourceDiscoveryMode ReEvaluateCompliance | Out-Null
}
