<#
  .DESCRIPTION
  This script will update Defender for Cloud's integrations settings on a subscription and enable Defender for Servers P1 or P2 if desired.

  .PARAMETER subscriptionId
  The id of the subscription to update settings for

  .PARAMETER DefenderforServersPlan
  The Defender for Servers Plan to Enable. Accepted values are P1, P2, Disabled, or Current. By default the current plan is used.

  .PARAMETER DefenderforCloudApps
  Enable the Defender for Cloud Apps Integration. Default is set to true.

  .PARAMETER DefenderforEndpoint
  Enable the Defender for Endpoint Integration. Default is set to true.

  .PARAMETER DefenderforEndpointExcludeLinux
  Exclude Linux Endpoints from Defender for Endpoint. Default is set to false. *Note this setting is only available for subscriptions where the legacy preview may still be enabled.

  .PARAMETER DefenderforEndpointUnifiedAgent
  Enable the Defender for Endpoint Unified Agent. Default is set to true.

  .PARAMETER SentinelBiDirectionalAlertSync
  Enable the Sentinel Bi-Directional Alert Sync. Default is set to true.

  .EXAMPLE
  Enable with all reccomended settings: Defender for Servers current plan, Defender for Endpoint Integration, Defender for Cloud Apss Integration, Unified Agent, Include Linux Servers
  .\enable-integration-settings.ps1 -subscriptionId 'c94dffc7-2dd9-4750-a3de-a160ddd68c90'

  .EXAMPLE
  Enable with all reccomended settings on multiple subscriptions
  Get-AzSubscription | % {.\enable-integration-settings.ps1 -subscriptionId $_.id}

  .EXAMPLE
  Enable with all reccomended settings and Defender for Servers P1
  .\enable-integration-settings.ps1 -subscriptionId 'c94dffc7-2dd9-4750-a3de-a160ddd68c90' -DefenderforServersPlan 'P1'
#>

param(
    [Parameter(ValueFromPipeline = $true, Mandatory=$true)]
    [string]$subscriptionId,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("P1", "P2", "Disabled", "Current")]
    [string]$DefenderforServersPlan = 'Current',

    [Parameter(Mandatory = $false)]
    [boolean]$DefenderforCloudApps = $true,

    [Parameter(Mandatory = $false)]
    [boolean]$DefenderforEndpoint = $true,
    
    [Parameter(Mandatory = $false)]
    [boolean]$DefenderforEndpointExcludeLinux = $false,

    [Parameter(Mandatory = $false)]
    [boolean]$DefenderforEndpointUnifiedAgent = $true,

    [Parameter(Mandatory = $false)]
    [boolean]$SentinelBiDirectionalAlertSync = $true
)

$subscription = Get-AzSubscription -SubscriptionId $subscriptionId

Write-Host ('Updating Settings for subscription {0}' -f $subscription.Name)

#Set Defender for Endpoint Integration
$payload = (@{
    kind = 'DataExportSettings'
    properties = @{
        enabled = $DefenderforEndpoint
    }
}) | ConvertTo-Json

$results = Invoke-AzRestMethod -SubscriptionId $subscription.Id -ResourceProviderName 'Microsoft.Security' -ResourceType 'settings' -Name 'WDATP' -ApiVersion '2022-05-01' -Method PUT -Payload $payload
Write-Host ('Configured Defender for Endpoint Integration on Subscription: {0}; Enabled: {1}' -f $subscription.Name, ($results.Content | ConvertFrom-Json).properties.enabled)

#Set Defender for Endpoint Linux Agent
$payload = (@{
    kind = 'DataExportSettings'
    properties = @{
        enabled = $DefenderforEndpointExcludeLinux
    }
}) | ConvertTo-Json

$results = Invoke-AzRestMethod -SubscriptionId $subscription.Id -ResourceProviderName 'Microsoft.Security' -ResourceType 'settings' -Name 'WDATP_EXCLUDE_LINUX_PUBLIC_PREVIEW' -ApiVersion '2022-05-01' -Method PUT -Payload $payload
Write-Host ('Configured Exclude Linux Servers from Defender for Endpoint on Subscription: {0}; Enabled: {1}' -f $subscription.Name, ($results.Content | ConvertFrom-Json).properties.enabled)

#Set Defender for Endpoint Unified Agent
$payload = (@{
    kind = 'DataExportSettings'
    properties = @{
        enabled = $DefenderforEndpointUnifiedAgent
    }
}) | ConvertTo-Json

$results = Invoke-AzRestMethod -SubscriptionId $subscription.Id -ResourceProviderName 'Microsoft.Security' -ResourceType 'settings' -Name 'WDATP_UNIFIED_SOLUTION' -ApiVersion '2022-05-01' -Method PUT -Payload $payload
Write-Host ('Configured Defender for Endpoint Unified Agent on Subscription: {0}; Enabled: {1}' -f $subscription.Name, ($results.Content | ConvertFrom-Json).properties.enabled)

#Set Defender for Cloud Apps Integration
$payload = (@{
    kind = 'DataExportSettings'
    properties = @{
        enabled = $DefenderforCloudApps
    }
}) | ConvertTo-Json

$results = Invoke-AzRestMethod -SubscriptionId $subscription.Id -ResourceProviderName 'Microsoft.Security' -ResourceType 'settings' -Name 'MCAS' -ApiVersion '2022-05-01' -Method PUT -Payload $payload
Write-Host ('Configured Defender for Cloud Apps Integration on Subscription: {0}; Enabled: {1}' -f $subscription.Name, ($results.Content | ConvertFrom-Json).properties.enabled)

#Set Defender For Servers Plan
$payload = (@{
    properties = @{
        pricingTier = $(If($DefenderforServersPlan -like 'Disabled'){'Free'}else{'Standard'})
        subPlan = $(If($DefenderforServersPlan -like 'Disabled'){$null}
        elseif ($DefenderforServersPlan -like 'Current') {
            $currentPlan = (Invoke-AzRestMethod -SubscriptionId $subscription.Id -ResourceProviderName 'Microsoft.Security' -ResourceType 'pricings' -Name 'VirtualMachines' -ApiVersion '2022-03-01' -Method Get).Content | ConvertFrom-Json
            If ($currentPlan.properties.subPlan){$currentPlan.properties.subPlan}
            else{$null}
        }
        else{$DefenderforServersPlan})
    }
}) | ConvertTo-Json

$results = Invoke-AzRestMethod -SubscriptionId $subscription.Id -ResourceProviderName 'Microsoft.Security' -ResourceType 'pricings' -Name 'VirtualMachines' -ApiVersion '2022-03-01' -Method PUT -Payload $payload
Write-Host ('Configured Defender for Servers Plan on Subscription: {0}; Plan: {1}' -f $subscription.Name, ($results.Content | ConvertFrom-Json).properties.subPlan)

#Set Sentinel Bi-directional Alert Sync
$payload = (@{
    kind = 'AlertSyncSettings'
    properties = @{
        enabled = $SentinelBiDirectionalAlertSync
    }
}) | ConvertTo-Json

$results = Invoke-AzRestMethod -SubscriptionId $subscription.Id -ResourceProviderName 'Microsoft.Security' -ResourceType 'settings' -Name 'Sentinel' -ApiVersion '2022-05-01' -Method PUT -Payload $payload
Write-Host ('Configured Sentinel Bi-Directional Alert Sync on Subscription: {0}; Enabled: {1}' -f $subscription.Name, ($results.Content | ConvertFrom-Json).properties.enabled)
