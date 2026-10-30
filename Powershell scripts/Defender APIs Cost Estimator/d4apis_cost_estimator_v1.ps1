#requires -Version 7.2
<#
.SYNOPSIS
Collects standalone Defender for APIs coverage and 30-day cost reports.
.DESCRIPTION
Read-only Azure commercial cloud collector. The historical filename is retained.
The companion module and pricing JSON are required. This optional reporting tool
is independent of the live workbook. Missing inventory or metrics never become
zero-cost recommendations.
.EXAMPLE
.\d4apis_cost_estimator_v1.ps1 -SubscriptionId '00000000-0000-0000-0000-000000000000' -OutputDirectory .\ApiEstimate
#>
[CmdletBinding()]
param(
    [guid[]]$SubscriptionId,
    [string]$OutputDirectory = (Join-Path (Get-Location).Path 'DefenderForApisEstimate'),
    [string]$PricingPath = (Join-Path $PSScriptRoot 'pricing.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'DefenderForApisCostEstimator.psm1') -Force
$pricing = Get-D4ApiPricing -Path $PricingPath
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    throw 'Az.Accounts is required. Install-Module Az.Accounts -Scope CurrentUser, then rerun the collector.'
}
Import-Module Az.Accounts
$originalContext = Get-AzContext
$summaries = [Collections.Generic.List[object]]::new()
$apis = [Collections.Generic.List[object]]::new()
$services = [Collections.Generic.List[object]]::new()
$costs = [Collections.Generic.List[object]]::new()
$issues = [Collections.Generic.List[object]]::new()
$now = [datetime]::UtcNow
$endTime = $now.AddTicks(-($now.Ticks % [TimeSpan]::TicksPerMinute))
$startTime = $endTime.AddDays(-30)

try {
    if (-not $originalContext) { $null = Connect-AzAccount -ErrorAction Stop }
    $context = Get-AzContext
    if ($context.Environment.Name -ne 'AzureCloud') {
        throw 'Defender for APIs support and this estimator are limited to the Azure commercial cloud.'
    }
    $subscriptions = @(if ($SubscriptionId) {
        $SubscriptionId | Select-Object -Unique | ForEach-Object {
            Get-AzSubscription -SubscriptionId $_.ToString() -ErrorAction Stop
        }
    } else {
        Get-AzSubscription -ErrorAction Stop | Where-Object State -EQ 'Enabled'
    })
    if (-not $subscriptions.Count) { throw 'No enabled subscriptions were found in the signed-in tenant.' }
    foreach ($subscription in $subscriptions) {
        Write-Information "Collecting $($subscription.Name) ($($subscription.Id))" -InformationAction Continue
        try {
            $null = Set-AzContext -SubscriptionId $subscription.Id -TenantId $subscription.TenantId -Scope Process -ErrorAction Stop
        } catch {
            Write-Warning "Could not select subscription '$($subscription.Id)': $($_.Exception.Message)"
            $issues.Add([pscustomobject]@{
                SubscriptionID = $subscription.Id; SubscriptionName = $subscription.Name
                Severity = 'Error'; Stage = 'Subscription context'; ResourceId = "/subscriptions/$($subscription.Id)"
                Message = $_.Exception.Message
            })
            $unavailable = Get-D4ApiSubscriptionEstimate -SubscriptionID $subscription.Id -SubscriptionName $subscription.Name `
                -Apis @() -Services @() -Plans $pricing.plans -InventoryComplete $false `
                -OnboardingComplete $false -DefenderStatus Unknown -CurrentPlan ''
            $summaries.Add($unavailable.Summary)
            continue
        }
        $result = Get-D4ApiSubscriptionReport -SubscriptionID $subscription.Id -SubscriptionName $subscription.Name `
            -Plans $pricing.plans -StartTime $startTime -EndTime $endTime
        $summaries.Add($result.Summary)
        foreach ($api in $result.Apis) { $apis.Add($api) }
        foreach ($service in $result.Services) { $services.Add($service) }
        foreach ($cost in $result.PlanCosts) { $costs.Add($cost) }
        foreach ($issue in $result.Issues) { $issues.Add($issue) }
    }
} finally {
    if ($originalContext) {
        $null = Set-AzContext -Context $originalContext -Scope Process -ErrorAction Stop
    }
}

$report = [ordered]@{
    SchemaVersion = '1.0'
    GeneratedAtUtc = [datetime]::UtcNow.ToString('o')
    WindowStartUtc = $startTime.ToString('o')
    WindowEndUtc = $endTime.ToString('o')
    ReportStatus = $(if ($issues.Count) { 'Review data quality' } else { 'Collected' })
    Pricing = $pricing
    Subscriptions = $summaries.ToArray()
    Apis = $apis.ToArray()
    Services = $services.ToArray()
    PlanCosts = $costs.ToArray()
    Issues = $issues.ToArray()
}
$null = New-Item -ItemType Directory -Path $OutputDirectory -Force
ConvertTo-Json -InputObject $report -Depth 50 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'DefenderForApisReport.json') -Encoding utf8
$exports = @{
    'AllSubscriptionsPlanRecommendation.csv' = $report.Subscriptions
    'DefenderForApis-ApiInventory.csv' = $report.Apis
    'DefenderForApis-ServiceInventory.csv' = $report.Services
    'DefenderForApis-PlanComparisons.csv' = $report.PlanCosts
    'DefenderForApis-Issues.csv' = $report.Issues
}
foreach ($file in $exports.Keys) {
    $exports[$file] | ForEach-Object {
        $row = [ordered]@{}
        foreach ($property in $_.PSObject.Properties) {
            $value = $property.Value
            if ($value -is [string] -and $value -match '^[\s\p{C}]*[=+\-@\uFF1D\uFF0B\uFF0D\uFF20]') {
                # Prefix CSV-only text before any whitespace/control characters; preserve raw JSON evidence.
                $value = "'" + $value
            }
            $row[$property.Name] = $value
        }
        [pscustomobject]$row
    } | Export-Csv -LiteralPath (Join-Path $OutputDirectory $file) -NoTypeInformation -Encoding utf8
}
Write-Information "Standalone JSON and CSV reports exported to '$OutputDirectory'." -InformationAction Continue
if (@($issues | Where-Object Severity -EQ 'Error').Count) {
    throw "Collection encountered errors. Partial evidence was exported to '$OutputDirectory'; review DefenderForApis-Issues.csv. Affected recommendations are withheld."
}
if ($issues.Count) {
    Write-Warning "Some estimates need review. Check '$(Join-Path $OutputDirectory 'DefenderForApis-Issues.csv')' before using costs."
}
