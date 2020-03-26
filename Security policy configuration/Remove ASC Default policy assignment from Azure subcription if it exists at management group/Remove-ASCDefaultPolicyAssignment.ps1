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
  Az.Resources

.Known Issues
    
  

#>


#comment the below line out if using cloud shell

$checkcloudshell = Get-ChildItem -Path ~/clouddrive

$outfilepath = "C:\users\subs.txt"

#comment out the below line if using local powershell (will detect in later release)
$outfilepath = "~/clouddrive/asc_pol_removed.txt"

$subascassignmentname = "ASC Default"

# gets all management groups from authorized login 
$azuremgmts = Get-AzManagementGroup

#loop through each management group
foreach ($azuremgmt in $azuremgmts){
    
    # Matching to ensure the Management Group is not Root and does have a ASC Policy assigned
    $mgmtscope = "/providers/Microsoft.Management/managementgroups/" + $azuremgmt.name
    $mgmtpolicycheck = Get-AzPolicyAssignment -Scope $mgmtscope
    if ($azuremgmt.DisplayName -notmatch "Tenant Root Group" -and $mgmtpolicycheck.Properties.policyDefinitionId -match "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8" ){

        $managementGroupName = $azuremgmt.Name
        $azmgmt = Get-AzManagementGroup -GroupName $managementGroupName -Expand
    
        # get the assigned subscriptions to the managaement group
        $azmgmtsubs = $azmgmt.Children

        # run through all subscriptions under Management group
        $azmgmtsubs | ForEach-Object -ThrottleLimit 10 -Parallel {

            # Matching to ensure the subscription is not "Access to Azure Active Directory" those subscriptions are non billable\deploayble into
            if ($_.DisplayName -notmatch "Access to Azure Active Directory"){

                # Get policy Assignments from each subscription
                
                Write-Host $_.Type
                Write-Host $_.Id
                Write-Host $_.Name
                Write-Host $_.DisplayName

                $policyassignsub = Get-AzPolicyAssignment -Scope $_.Id

                # Matching condition of policy assignment resourcename and subid not being null, mgmt assignments do not have SubscriptionId in object
                if ($policyassignsub.ResourceName -contains "SecurityCenterBuiltIn" -and $policyassignsub.SubscriptionId -ne $null ) {
    
                    ## Used below for Testing ensure no false positives in above if matching
                    #Write-Host $policyassignsub.Name
                    #Write-Host $policyassignsub.ResourceId[0] 
    
                    ## Remove the following policy assignemnt from subscription.
                    Remove-AzPolicyAssignment -Id $policyassignsub.ResourceId[0]
                    $policyassignsub.Name | out-file $outfilepath -append

                }

            }

        }    

    }

}