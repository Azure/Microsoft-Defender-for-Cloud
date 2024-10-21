[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string[]]$SubscriptionIds,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputPath,

    [Parameter(Mandatory=$false)]
    [string[]]$StorageAccountNames
)

function Get-AzDefenderStorageSubscriptionPlan {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId
    )
    
    $pathUrl = "/subscriptions/$SubscriptionId/providers/Microsoft.Security/pricings/StorageAccounts?api-version=2022-03-01"
    $response = Invoke-AzRestMethod -Method GET -Path $pathUrl
    $content = $response.Content | ConvertFrom-Json
    return $content.properties.subPlan ?? "None"
}

function Get-AzDefenderStorageEffectivePlan {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId
    )
    
    $v2PathUrl = "$ResourceId/providers/Microsoft.Security/defenderForStorageSettings/current?api-version=2022-12-01-preview"
    $v1PathUrl = "$ResourceId/providers/Microsoft.Security/advancedThreatProtectionSettings/current?api-version=2017-08-01-preview"

    $v2Response = Invoke-AzRestMethod -Method GET -Path $v2PathUrl
    $v1Response = Invoke-AzRestMethod -Method GET -Path $v1PathUrl

    $v2Content = $v2Response.Content | ConvertFrom-Json
    $v1Enabled = ($v1Response.Content | ConvertFrom-Json).properties.isEnabled

    if ($v2Content.properties.isEnabled) { 
        return @{
            EffectivePlan = "New Defender for Storage Per-Storage Account Plan (v2)"
            SensitiveDataThreatDetection = $v2Content.properties.sensitiveDataDiscovery.isEnabled
            OnUploadMalwareScanning = $v2Content.properties.malwareScanning.onUpload.isEnabled
            OnUploadMalwareScanningCap = if ($v2Content.properties.malwareScanning.onUpload.isEnabled) { $v2Content.properties.malwareScanning.onUpload.capGBPerMonth } else { $null }
        }
    }
    elseif ($v1Enabled) { 
        $subPlan = Get-AzDefenderStorageSubscriptionPlan -SubscriptionId $SubscriptionId
        if ($subPlan -eq 'PerStorageAccount') {
            return @{ EffectivePlan = "Classic Per-Storage Account Plan (v1.5)" }
        } elseif ($subPlan -eq 'None') {
            return @{ EffectivePlan = "Classic Per-Transaction Plan (v1)" }
        } else {
            return @{ EffectivePlan = $subPlan }
        }
    }
    else { 
        return @{ EffectivePlan = "None" }
    }
}

# Main script execution
try {
    $results = @()

    foreach ($subscriptionId in $SubscriptionIds) {
        try {
            $context = Set-AzContext -SubscriptionId $subscriptionId -ErrorAction Stop
            Write-Host "Analyzing subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"

            $subscriptionPlan = Get-AzDefenderStorageSubscriptionPlan -SubscriptionId $subscriptionId
            
            if ($StorageAccountNames) {
                $storageAccounts = Get-AzStorageAccount | Where-Object { $_.StorageAccountName -in $StorageAccountNames }
            } else {
                $storageAccounts = Get-AzStorageAccount
            }
            
            Write-Host "Found $($storageAccounts.Count) storage accounts to analyze."

            foreach ($storageAccount in $storageAccounts) {
                $effectivePlanInfo = Get-AzDefenderStorageEffectivePlan -ResourceId $storageAccount.Id -SubscriptionId $subscriptionId

                $result = [PSCustomObject]@{
                    SubscriptionName = $context.Subscription.Name
                    SubscriptionId = $subscriptionId
                    ResourceGroupName = $storageAccount.ResourceGroupName
                    StorageAccountName = $storageAccount.StorageAccountName
                    SubscriptionPlan = $subscriptionPlan
                    EffectivePlanOnResource = $effectivePlanInfo.EffectivePlan
                    SensitiveDataThreatDetection = if ($effectivePlanInfo.EffectivePlan -eq "New Defender for Storage Per-Storage Account Plan (v2)") { $effectivePlanInfo.SensitiveDataThreatDetection } else { $null }
                    OnUploadMalwareScanning = if ($effectivePlanInfo.EffectivePlan -eq "New Defender for Storage Per-Storage Account Plan (v2)") { $effectivePlanInfo.OnUploadMalwareScanning } else { $null }
                    OnUploadMalwareScanningCap = if ($effectivePlanInfo.EffectivePlan -eq "New Defender for Storage Per-Storage Account Plan (v2)") { $effectivePlanInfo.OnUploadMalwareScanningCap } else { $null }
                }

                $results += $result
            }
        }
        catch {
            Write-Warning "Error processing subscription $subscriptionId : $_"
        }
    }

    # Export results to CSV
    $results | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "Analysis complete. Results exported to $OutputPath"
}
catch {
    Write-Error "An error occurred: $_"
}