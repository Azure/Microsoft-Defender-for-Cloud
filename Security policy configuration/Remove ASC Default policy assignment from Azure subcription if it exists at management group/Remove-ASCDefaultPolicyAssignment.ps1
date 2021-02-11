<#

.Synopsis

  Can be used when there are dual levels of ASC policies assignments at Management group and subscription level. If you want ASC policy to be inherited correctly at the management group, 
  this script Removes ASC Default policy assignment at subscription level by doing the following steps

  1. Seeking all of your management groups and a match for a ASC Default definition in policy assignment at Management Group Level.
  2. Seeking all subscrptions within your managemnt group, Looking for the following policy assignment name 'ASC Default' applied at subscription level.
  3. If a match is found remove the policy assignment.


More information mentioned here : https://docs.microsoft.com/en-us/azure/governance/management-groups/overview


.Requirements

  PowerShell 7
  Az.Resources >=2.4.0 (Included with Az >= 5.0.0)

.Known Issues
    
#>


#comment the below line out if using cloud shell
#$checkcloudshell = Get-ChildItem -Path ~/clouddrive

$outfilepath = ".\PoliciesRemoved_$(Get-Date -Format yyyyMMdd_HHmmss).txt"

#comment out the below line if using local powershell (will detect in later release)
#$outfilepath = "~/clouddrive/asc_pol_removed.txt"

#Management Group ID to scan
$managementGroupId = 'mg1'

#When set to true, script will only report which subscriptions have ASC policies assignments at both the Management Group and Subscription Level.
#Set to $false to remove ASC policies assignments at the Subscription Level when assignment is already at the Management Group Level
$reportOnly = $true

######################################################################
Function Process-AzManagementGroupChildren {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]
        $ManagementGroupId
    )
    $ManagementGroup = Get-AzManagementGroup -GroupId $ManagementGroupId -Expand -WarningAction SilentlyContinue

    Write-Output "`nManagement Group: $($ManagementGroup.DisplayName) ($($ManagementGroup.Name))"
    $mgmtpolicycheck = Get-AzPolicyAssignment -Scope $ManagementGroup.Id
    # Matching to ensure the Management Group has the ASC Policy assigned
    if ($mgmtpolicycheck.Properties.policyDefinitionId -match "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8" ) {
        # run through all subscriptions under Management group
        $childSubscriptions = $ManagementGroup.Children | ? { $_.Type -eq '/subscriptions' }
        foreach ($childSubscription in $childSubscriptions) {
            # Matching to ensure the subscription is not "Access to Azure Active Directory" those subscriptions are non billable\deploayble into
            if ($childSubscription.DisplayName -notmatch "Access to Azure Active Directory") {
                # Get policy Assignments from each subscription
                # Matching condition of policy assignment resourcename and subid not being null, mgmt assignments do not have SubscriptionId in object
                foreach ($policyassignsub in (Get-AzPolicyAssignment -Scope $childSubscription.Id)) {
                    if ($policyassignsub.ResourceName -contains "SecurityCenterBuiltIn" -and $policyassignsub.SubscriptionId -ne $null ) {
                        Write-Output "`tSubscription: $($childSubscription.DisplayName) ($($childSubscription.Name))"
                        if ($reportOnly -eq $false) {
                            Write-Output "`t   Removing Policy Assignment:"
                            Remove-AzPolicyAssignment -Id $policyassignsub.ResourceId
                            Write-Output "Subscription: $($childSubscription.DisplayName) ($($childSubscription.Name))" | Out-File -FilePath $outfilepath -Append
                            Write-Output "`tPolicy Name: $($policyassignsub.Name)" | Out-File -FilePath $outfilepath -Append
                            Write-Output "`tPolicy Assignment ID: $($policyassignsub.PolicyAssignmentId)" | Out-File -FilePath $outfilepath -Append
                            Write-Output "`tPolicy Definition ID: $($policyassignsub.Properties.PolicyDefinitionId)" | Out-File -FilePath $outfilepath -Append
                        }
                    
                        Write-Output "`t`tPolicy Name: $($policyassignsub.Name)"
                        Write-Output "`t`tPolicy Assignment ID: $($policyassignsub.PolicyAssignmentId)"
                        Write-Output "`t`tPolicy Definition ID: $($policyassignsub.Properties.PolicyDefinitionId)"
                    }
                }
            }
        }
    }

    #Recurse through child Management Groups
    $childManagementGroups = $ManagementGroup.Children | ? { $_.Type -eq '/providers/Microsoft.Management/managementGroups' }
    foreach ($childManagementGroup in $childManagementGroups) {
        Process-AzManagementGroupChildren -ManagementGroupId $childManagementGroup.Name
    }
}

Process-AzManagementGroupChildren -ManagementGroupId $managementGroupId
