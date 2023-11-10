param (
    [parameter(Mandatory=$true)]
    [Object]$RecoveryPlanContext
)

# Set the below Properties as variables in automation account.
$VaultSubscriptionIdVariable = "VaultSubscriptionId"
$VaultResourceGroupVariable = "VaultResourceGroup"
$VaultNameVariable = "VaultName"
$ChangePitVariable = "ChangePit"

# Runbook name for the schedule runbook.
$RunbookName = "RansomwareDetector"
$SchedulerDays = 15
$IntervalInHours = 1
$SchedulerName = "RansomwareDetector" + (Get-Random)

<#
.SYNOPSIS
    Assigns the Azure policy.
#>
function Set-Policies-On-Subscription {
    Param
    (
    [Parameter(Mandatory = $true)] [string] $definitionId,
    [Parameter(Mandatory = $true)] [string] $displayName,
    [Parameter(Mandatory = $true)] [string] $description
    )
    Write-Host ('Prams 1st = {0}  2nd = {1} 3rd = {2}' -f $definitionId, $displayName, $description);
    
    $definition = Get-AzPolicySetDefinition -Id $definitionId
    $paramSet = @{
        Name = $(New-Guid).Guid.substring(0,23) 
        DisplayName = $displayName
        Description = $description
        PolicySetDefinition = $definition
        IdentityType = 'SystemAssigned' 
        Location = 'centralus'
        Scope = $scope
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
        Write-Host ('Creating {0} role assignment for remediation on: {1}' -f $role, $scope)
        New-AzRoleAssignment -Scope $scope -ObjectId $assignment.Identity.PrincipalId -RoleDefinitionId $role -ErrorAction SilentlyContinue | Out-Null
    }

    # Create Remediation Tasks
    Write-Host 'Creating Remediation Tasks'
    ForEach ($PolicyDefinition in $definition.Properties.PolicyDefinitions){
        Start-AzPolicyRemediation -Name $PolicyDefinition.policyDefinitionReferenceId -PolicyAssignmentId $assignment.PolicyAssignmentId -PolicyDefinitionReferenceId $PolicyDefinition.policyDefinitionReferenceId -ResourceDiscoveryMode ReEvaluateCompliance | Out-Null
    }
}   


# Check for required modules
$requiredModules = 'Az.Accounts', 'Az.Resources', 'Az.Security', 'Az.PolicyInsights', 'Az.RecoveryServices' 
$availableModules = Get-Module -ListAvailable -Name $requiredModules
$modulesToInstall = $requiredModules | where-object {$_ -notin $availableModules.Name}
ForEach ($module in $modulesToInstall){
    Write-Host "Installing Missing PowerShell Module: $module" -ForegroundColor Yellow
    Install-Module $module -force
}

# Recovery plan context from ASR recovery plan failover operation.
$RecoveryPlanContext
Write-Output "checking RecoveryPlanContext"

$RecoveryPlanContextObj = ""
try
{
    $RecoveryPlanContextObj = $RecoveryPlanContext | ConvertFrom-Json
}
catch {
    $RecoveryPlanContextObj = $RecoveryPlanContext
    Write-Error -Message $_.Exception
}

Write-Output "getting VM map object"
$VMMapColl = $RecoveryPlanContextObj.VmMap
Write-Output $VMMapColl
Write-Output "after getting VM map object"

$SubscriptionId = ""
$ResourceGroupName = ""
$VMCollection = @()

if($VMMapColl -ne $null)
{
    $VMinfo = $VMMapColl | Get-Member | Where-Object MemberType -EQ NoteProperty | select -ExpandProperty Name
    #$vmMap = $RecoveryPlanContextObj.VmMap
    Write-Output "VMinfo: $VMinfo"

    foreach($VMID in $VMinfo)
    {
        $VM = $VMMapColl.$VMID
        Write-Output $VM
                
        if( !(($VM -eq $Null) -Or ($VM.ResourceGroupName -eq $Null) -Or ($VM.RoleName -eq $Null))) 
        {
            $VM | Add-Member NoteProperty RecoveryPlanName $RecoveryPlanContextObj.RecoveryPlanName
            $VM | Add-Member NoteProperty FailoverType $RecoveryPlanContextObj.FailoverType
            $VM | Add-Member NoteProperty FailoverDirection $RecoveryPlanContextObj.FailoverDirection
            $VM | Add-Member NoteProperty GroupId $RecoveryPlanContextObj.GroupId
            $VM | Add-Member NoteProperty VMId $VMID
            $VM | Add-Member NoteProperty VmRg $VM.ResourceGroupName
            $VM | Add-Member NoteProperty VmName $VM.RoleName

            $VMCollection += $VM
            $SubscriptionId = $VM.SubscriptionId
            $ResourceGroupName = $VM.ResourceGroupName
        }
    }
}
else
{
     Write-Output "VMMapColl Variable is Null"
}

$CollectionCount = $VMCollection.Count
Write-Output "Collection Count: $CollectionCount" 

#Returning Collection
Write-Output $VMCollection

if ($SubscriptionId -eq "")
{
    Write-Output "SubscriptionId not found."
    exit
}

Write-Output "SubscriptionId : $SubscriptionId"

try
{
    # Login to Azure using the managed system identity using in Automation account.
    Write-Output "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

# set the Azure subscription context.
Get-AzContext
$currentSub = Set-AzContext -Subscription $SubscriptionId
$scope = "/subscriptions/$($currentSub.Subscription.Id)"

$AutomationResource = Get-AzResource -ResourceType Microsoft.Automation/AutomationAccounts
$AutomationInformation = $null
foreach ($Automation in $AutomationResource)
{
    $Job = Get-AzAutomationJob -ResourceGroupName $Automation.ResourceGroupName -AutomationAccountName $Automation.Name -Id $PSPrivateMetadata.JobId.Guid -ErrorAction SilentlyContinue
    if (!([string]::IsNullOrEmpty($Job)))
    {
        $AutomationInformation = @{}
        $AutomationInformation.Add("SubscriptionId",$Automation.SubscriptionId)
        $AutomationInformation.Add("Location",$Automation.Location)
        $AutomationInformation.Add("ResourceGroupName",$Job.ResourceGroupName)
        $AutomationInformation.Add("AutomationAccountName",$Job.AutomationAccountName)
        $AutomationInformation.Add("RunbookName",$Job.RunbookName)
        $AutomationInformation.Add("JobId",$Job.JobId.Guid)
        $AutomationInformation
        break;
    }
}

if ($AutomationInformation -eq $null)
{
    Write-Output "Automation account not found."
    exit
}

# Get the Recovery services vault Id from the Automation account variable.
$SubVariable = Get-AzAutomationVariable -AutomationAccountName $AutomationInformation.AutomationAccountName -ResourceGroupName $AutomationInformation.ResourceGroupName -Name $VaultSubscriptionIdVariable
    
$VaultSubscriptionId = $SubVariable.value

$RgVariable = Get-AzAutomationVariable -AutomationAccountName $AutomationInformation.AutomationAccountName -ResourceGroupName $AutomationInformation.ResourceGroupName -Name $VaultResourceGroupVariable
    
$VaultResourceGroup = $RgVariable.value

$VaultVariable = Get-AzAutomationVariable -AutomationAccountName $AutomationInformation.AutomationAccountName -ResourceGroupName $AutomationInformation.ResourceGroupName -Name $VaultNameVariable
    
$VaultName = $VaultVariable.value

$CpVariable = Get-AzAutomationVariable -AutomationAccountName $AutomationInformation.AutomationAccountName -ResourceGroupName $AutomationInformation.ResourceGroupName -Name $ChangePitVariable
    
$ChangePit = $CpVariable.value

if (($VaultName -eq $null) -or ($VaultName -eq "") -or ($VaultSubscriptionId -eq $null) -or ($VaultSubscriptionId -eq "") -or ($VaultResourceGroup -eq $null) -or ($VaultResourceGroup -eq "") -or ($ChangePit -eq $null) -or ($ChangePit -eq ""))
{
    Write-Output "Either VaultSubscriptionId, VaultResourceGroup or VaultName variables not found."
    exit
}

$VaultId = "/Subscriptions/$VaultSubscriptionId/resourceGroups/$VaultResourceGroup/providers/Microsoft.RecoveryServices/vaults/$VaultName"

$VaultId

# Getting the RansomwareDetector runbook details.
$Runbook = Get-AzAutomationRunbook -AutomationAccountName $AutomationInformation.AutomationAccountName -ResourceGroupName $AutomationInformation.ResourceGroupName -Name $RunbookName

$Runbook

# Creating a scheduler.
$StartTime = (Get-Date).AddMinutes(10) # start after 10min, minimum time required to start.
$EndTime = $StartTime.AddDays($SchedulerDays) # Number of days to keep the scheduler.
$Schedule = New-AzAutomationSchedule -AutomationAccountName $AutomationInformation.AutomationAccountName -ResourceGroupName $AutomationInformation.ResourceGroupName -Name $SchedulerName -StartTime $StartTime -ExpiryTime $EndTime -HourInterval $IntervalInHours
$Schedule

Start-Sleep -Seconds 10
$params = @{"RecoveryPlanContext" = $RecoveryPlanContext;"VaultId" = $VaultId;"ChangePit" = $ChangePit}

# Registering the runbook to scheduler.
$JobSchedule = Register-AzAutomationScheduledRunbook -AutomationAccountName $AutomationInformation.AutomationAccountName -ResourceGroupName $AutomationInformation.ResourceGroupName -RunbookName $RunbookName -ScheduleName $SchedulerName -Parameters $params
$JobSchedule

# Running the policies needed at the Subscription level. We could run this at RG level if needed in future.
$currentSub = Set-AzContext -Subscription $subscriptionId
$scope = "/subscriptions/$($currentSub.Subscription.Id)"

# Enable MDC on the subscription
Write-Host "Enabling MDC on subscription: $subscriptionId" -ForegroundColor Yellow
Register-AzResourceProvider -ProviderNamespace 'Microsoft.Security' 

#Ensure Microsoft Security Benchmark is assigned
$benchmarkDefn = Get-AzPolicySetDefinition -Name "1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
if ($null -eq (Get-AzPolicyAssignment -Scope $scope -PolicyDefinitionId $benchmarkDefn.PolicySetDefinitionId) )
{
    Write-Host "Enabling Security benchmark on subscription: $subscriptionId" -ForegroundColor Yellow
    New-AzPolicyAssignment -Name 'Security Benchmark assignment' -PolicySetDefinition $benchmarkDefn 
}

#Enable Microsoft Defender for Cloud plans for server. This enables the P2 plan when used with "-SubPlan P2"
Write-Host 'Enabling MDC plan for servers' -ForegroundColor Yellow
Set-AzSecurityPricing -Name "virtualmachines" -PricingTier "Standard"

#If needed, update the workspace settings for the subscription
#Set-AzSecurityWorkspaceSetting -Name "default" -Scope $subscriptionId -WorkspaceId  "<path goes here>"

#Configure Auto-provisioning settings
Write-Host 'Enabling auto-provisioning settings' -ForegroundColor Yellow
Set-AzSecurityAutoProvisioningSetting -Name "default" -EnableAutoProvision

# This setting should enable the unified defender for endpoint integration for Windows & Linux
Write-Host 'Enabling unified defender for endpoint integration' -ForegroundColor Yellow
Set-AzSecuritySetting -SettingName WDATP -SettingKind DataExportSettings -Enabled $true

Write-Host 'Assigning the required policies ' -ForegroundColor Yellow
# Enable the MDE on the servers via policy
$mdePolicyDefn = Get-AzPolicySetDefinition -Name 'e20d08c5-6d64-656d-6465-ce9e37fd0ebc'
if ($null -eq (Get-AzPolicyAssignment -Scope $scope -PolicyDefinitionId $mdePolicyDefn.PolicySetDefinitionId) )
{
    Write-Host 'Assigning the policy to enable MDE' -ForegroundColor Yellow
    Set-Policies-On-Subscription $mdePolicyDefn.PolicySetDefinitionId 'Assignment for provisioning MDE' 'Default assignment in Defender for Cloud for provisioning MDE'
}

# Enable the Azure Monitor and Azure security agent via policy
$securityAgentDefn = Get-AzPolicySetDefinition -Name 'a15f3269-2e10-458c-87a4-d5989e678a73'
if($null -eq (Get-AzPolicyAssignment -Scope $scope -PolicyDefinitionId $securityAgentDefn.PolicySetDefinitionId) )
{
    Write-Host 'Assigning the policy to enable security agent' -ForegroundColor Yellow
    Set-Policies-On-Subscription $securityAgentDefn.PolicySetDefinitionId "Assignment for provisioning Security Agent" "Default assignment in Defender for Cloud for provisioning Sec Agent"
}

# Enable the AMA on the servers via policy
# This isn't needed since the earlier policy handles this as well.
#Set-Policies '/providers/Microsoft.Authorization/policySetDefinitions/362ab02d-c362-417e-a525-45805d58e21d'  'Default Defender for Cloud provisioning Azure Monitor agent' 'Default Defender for Cloud provisioning Azure Monitor agent'