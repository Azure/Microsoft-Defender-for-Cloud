<#
  .DESCRIPTION
  This script will report on all integration settings for all subscriptins in Defender for Cloud and provide the current Defender for Servers Plan
  
  .PARAMETER TenantId
  The TenantId to gather all subscriptions under. If no TenantId is specified the current Tenant will be returned from Get-AzContext

  .EXAMPLE
  Get all subscription integration settings for the currently connected Tenant
  $settings = .\get-integration-report.ps1

  .EXAMPLE
  Get all subscription integration settings for a specific Tenant
  $settings = .\get-integration-report.ps1 -TenantId 'c94dffc7-2dd9-4750-a3de-a160ddd68c90'
 #>

 param(
    [Parameter(ValueFromPipeline = $true, Mandatory=$false)]
    [string]$TenantId
 )

#Get All Subscriptions
If($TenantId){
    $subscriptions = Get-AzSubscription -TenantId $TenantId | Where State -eq 'Enabled'
}else{    
    $subscriptions = Get-AzSubscription -TenantId (Get-AzContext).Tenant | Where State -eq 'Enabled'
}

$friendlysettings = @()

ForEach ($subscription in $subscriptions){
    $settings = ((Invoke-AzRestMethod -SubscriptionId $subscription.Id -ResourceProviderName 'Microsoft.Security' -ResourceType 'settings' -ApiVersion '2022-05-01' -Method Get).Content | ConvertFrom-Json).Value
    $defenderForServersPlan = (Invoke-AzRestMethod -SubscriptionId $subscription.Id -ResourceProviderName 'Microsoft.Security' -ResourceType 'pricings' -Name 'VirtualMachines' -ApiVersion '2022-03-01' -Method Get).Content | ConvertFrom-Json
    Write-Host ('Getting Settings for subscription {0}' -f $subscription.Name)
    if($settings){
        $friendlysettings += ([PSCustomObject]@{
            subscriptionName = $subscription.Name
            subscriptionId = $subscription.Id
            DefenderforServersPlan = $(if($defenderForServersPlan.properties.subPlan -eq $null){'notenabled'}else{$defenderForServersPlan.properties.subPlan})
            DefenderforCloudApps = ($settings | where name -eq 'MCAS').Properties.enabled
            DefenderforEndpoint = ($settings | where name -eq 'WDATP').Properties.enabled
            DefenderforEndpointExcludeLinux = ($settings | where name -eq 'WDATP_EXCLUDE_LINUX_PUBLIC_PREVIEW').Properties.enabled
            DefenderforEndpointUnifiedAgent = ($settings | where name -eq 'WDATP_UNIFIED_SOLUTION').Properties.enabled
            SentinelBiDirectionalAlertSync = ($settings | where name -eq 'Sentinel').Properties.enabled
            error = $null
        })
    }else{
        $friendlysettings += ([PSCustomObject]@{
            subscriptionName = $subscription.Name
            subscriptionId = $subscription.Id
            DefenderforServersPlan = 'no settings returned'
            DefenderforCloudApps = 'no settings returned'
            DefenderforEndpoint = 'no settings returned'
            DefenderforEndpointExcludeLinux = 'no settings returned'
            DefenderforEndpointUnifiedAgent = 'no settings returned'
            SentinelBiDirectionalAlertSync = 'no settings returned'
            error = ('No Settings Returned for Subscription: {0}, you may not have security reader rights assigned' -f $subscription.Name)
        })
    }
}

$friendlysettings