#Requires -Version 7.0
#Requires -Modules Az.Accounts
<#
.SYNOPSIS
Estimates Microsoft Defender for Storage and on-upload malware scanning costs without changing Azure resources.
.DESCRIPTION
Projects sampled Blob/File transactions and upload-related Blob ingress to 30 days.
The ingress estimate uses the same 1,073,741,824-byte GB conversion as the workbook.
Numeric byte and GB fields are retained alongside an automatically scaled upload-volume display.
.PARAMETER MalwareScanningCapGB
Modeled monthly scanning limit in GB per storage account. Use -1 for an uncapped estimate.
This scenario input does not discover configured caps or change Azure settings.
.OUTPUTS
Account records with numeric costs and volumes, a readable upload-volume field, and metric completeness.
.NOTES
Microsoft Defender for Storage - Price Estimation, version 4.2.
#>
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string[]]$SubscriptionIds,
    [ValidateRange(1, 30)]
    [int]$SampleDays = 7,
    [ValidateRange(1, 32)]
    [int]$ThrottleLimit = 10,
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = 'CostEstimation.csv',
    [ValidateScript({ $_ -ge 0 })]
    [decimal]$CostPerStorageAccount = 10,
    [ValidateScript({ $_ -ge 0 })]
    [decimal]$PricePer1MOverageTransactions = 0.1492,
    [ValidateScript({ $_ -ge 0 })]
    [decimal]$MalwareScanningPricePerGB = 0.15,
    [ValidateScript({ $_ -ge -1 })]
    [long]$MalwareScanningCapGB = -1
)

function Format-StorageDataSize {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [ValidateScript({ $_ -ge 0 })]
        [Nullable[decimal]]$Bytes
    )

    $units = @('B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB')
    $size = [decimal]$Bytes
    $unitIndex = 0
    while ($size -ge 1024 -and $unitIndex -lt ($units.Count - 1)) {
        $size /= [decimal]1024
        $unitIndex++
    }
    $displayValue = [math]::Round($size, 2)
    if ($displayValue -ge 1024 -and $unitIndex -lt ($units.Count - 1)) {
        $displayValue = [math]::Round($displayValue / [decimal]1024, 2)
        $unitIndex++
    }
    return '{0} {1}' -f $displayValue.ToString('0.##', [cultureinfo]::InvariantCulture), $units[$unitIndex]
}

function Invoke-StorageEstimationGet {
    param([string]$Path, $Context)

    if ($Path -match '^https?://') {
        $uri = [uri]$Path
        $resourceManager = [uri]$Context.Environment.ResourceManagerUrl
        if ($uri.Scheme -ne 'https' -or $uri.Authority -ne $resourceManager.Authority) {
            throw "Refusing a pagination URL outside the current Azure Resource Manager endpoint: $Path"
        }
        $Path = $uri.PathAndQuery
    }

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        $response = Invoke-AzRestMethod -Method GET -Path $Path -DefaultProfile $Context -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            return $response.Content | ConvertFrom-Json -Depth 100 -ErrorAction Stop
        }
        if ($response.StatusCode -in @(429, 500, 502, 503, 504) -and $attempt -lt 3) {
            Start-Sleep -Seconds ([math]::Pow(2, $attempt))
            continue
        }
        throw "Azure returned HTTP $($response.StatusCode) for $Path. No complete estimate was exported."
    }
}

function Get-StorageAccountCostEstimate {
    param($Account, $Context, $Configuration)

    function Get-MetricTotal {
        param([string]$Service, [string]$MetricName, [string[]]$ApiNames, $MetricContext)

        $timespan = [uri]::EscapeDataString(
            "$($Configuration.StartTimeUtc.ToString('o'))/$($Configuration.EndTimeUtc.ToString('o'))"
        )
        $namespace = [uri]::EscapeDataString("microsoft.storage/storageaccounts/$($Service.ToLowerInvariant())")
        $path = "$($Account.id)/$Service/default/providers/Microsoft.Insights/metrics" +
            "?api-version=2023-10-01&timespan=$timespan&interval=FULL" +
            "&metricnames=$MetricName&aggregation=Total&metricnamespace=$namespace"
        if ($ApiNames.Count -gt 0) {
            $filter = ($ApiNames | ForEach-Object { "ApiName eq '$_'" }) -join ' or '
            $path += '&validatedimensions=false&$filter=' + [uri]::EscapeDataString($filter)
        }

        $response = Invoke-StorageEstimationGet -Path $path -Context $MetricContext
        $metrics = @($response.value | Where-Object { $_.name.value -eq $MetricName })
        if ($metrics.Count -ne 1) {
            throw "Expected one $MetricName metric for $($Account.id)/$Service."
        }
        $metric = $metrics[0]
        if ($metric.errorCode -and $metric.errorCode -ne 'Success') {
            throw "Metric $MetricName failed for $($Account.id)/${Service}: $($metric.errorCode)"
        }

        $hasData = $false
        $hasMissingData = $false
        $total = [decimal]0
        foreach ($series in $metric.timeseries) {
            if ($null -eq $series.data -or @($series.data).Count -eq 0) {
                $hasMissingData = $true
            }
            foreach ($point in $series.data) {
                if ($null -ne $point.total) {
                    if ($point.total -lt 0) {
                        throw "Metric $MetricName contains a negative total for $($Account.id)."
                    }
                    $total += [decimal]$point.total
                    $hasData = $true
                } else {
                    $hasMissingData = $true
                }
            }
        }
        if (-not $hasData -or $hasMissingData) {
            Write-Warning "Missing or incomplete $MetricName data for $($Account.id)/$Service; the affected estimate is unknown, not zero."
            return $null
        }
        return $total
    }

    $hasBlob = -not [string]::IsNullOrWhiteSpace($Account.properties.primaryEndpoints.blob)
    $hasFile = -not [string]::IsNullOrWhiteSpace($Account.properties.primaryEndpoints.file)
    if (-not $hasBlob -and -not $hasFile) {
        throw "Storage account $($Account.id) has neither a Blob nor a File service endpoint."
    }

    $sampleTransactions = [decimal]0
    $hasTransactionData = $true
    foreach ($service in @('blobServices', 'fileServices')) {
        if (($service -eq 'blobServices' -and -not $hasBlob) -or
            ($service -eq 'fileServices' -and -not $hasFile)) {
            continue
        }
        $transactions = Get-MetricTotal -Service $service -MetricName Transactions -MetricContext $Context
        if ($null -eq $transactions) {
            $hasTransactionData = $false
        } else {
            $sampleTransactions += $transactions
        }
    }

    $scale = [decimal]30 / $Configuration.SampleDays
    $monthlyTransactions = $null
    $overageTransactions = $null
    $overageCost = $null
    $storageCost = $null
    $oldEstimateCost = $null
    if ($hasTransactionData) {
        $monthlyTransactions = $sampleTransactions * $scale
        $overageTransactions = [math]::Max($monthlyTransactions - [decimal]73000000, [decimal]0)
        $overageCost = $overageTransactions / 1000000 * $Configuration.PricePer1MOverageTransactions
        $storageCost = $Configuration.CostPerStorageAccount + $overageCost
        $oldEstimateCost = $monthlyTransactions / 10000 * [decimal]0.02
    }

    $monthlyIngressBytes = [decimal]0
    $monthlyIngressGB = [decimal]0
    $billableGB = [decimal]0
    $malwareCost = [decimal]0
    if ($hasBlob) {
        $uploadApis = @(
            'PutBlob', 'CopyBlob', 'PutBlock', 'PutBlockList', 'PutBlockFromURL',
            'AppendFile', 'FlushFile', 'CreatePathFile'
        )
        $ingress = Get-MetricTotal -Service blobServices -MetricName Ingress -ApiNames $uploadApis -MetricContext $Context
        if ($null -eq $ingress) {
            $monthlyIngressBytes = $null
            $monthlyIngressGB = $null
            $billableGB = $null
            $malwareCost = $null
        } else {
            $monthlyIngressBytes = $ingress * $scale
            $monthlyIngressGB = $monthlyIngressBytes / [decimal]1073741824
            $billableGB = $monthlyIngressGB
            if ($Configuration.MalwareScanningCapGB -ge 0) {
                $billableGB = [math]::Min($billableGB, [decimal]$Configuration.MalwareScanningCapGB)
            }
            $malwareCost = $billableGB * $Configuration.MalwareScanningPricePerGB
        }
    }

    $totalCost = $null
    $status = 'Incomplete'
    if ($null -ne $storageCost -and $null -ne $malwareCost) {
        $totalCost = $storageCost + $malwareCost
        $status = 'Complete'
    }
    [pscustomobject]@{
        SubscriptionId = ($Account.id -split '/')[2]
        StorageAccountName = $Account.name
        StorageAccountCost = $storageCost
        StorageAccountTransactions = $monthlyTransactions
        OldEstimateCost = $oldEstimateCost
        OverageCost = $overageCost
        OverageTransactions = $overageTransactions
        StorageAccountId = $Account.id
        SampleDays = $Configuration.SampleDays
        EstimatedMonthlyIngressGB = $monthlyIngressGB
        MalwareScanningBillableGB = $billableGB
        MalwareScanningCost = $malwareCost
        EstimatedMonthlyCost = $totalCost
        MetricsStatus = $status
        EstimatedMonthlyUploadedBytes = $monthlyIngressBytes
        EstimatedMonthlyUploaded = if ($null -eq $monthlyIngressBytes) {
            $null
        } else {
            Format-StorageDataSize -Bytes $monthlyIngressBytes
        }
    }
}

if ($MyInvocation.InvocationName -eq '.') {
    return
}

$ErrorActionPreference = 'Stop'
$originalContext = Get-AzContext -ErrorAction Stop
if ($null -eq $originalContext -or [string]::IsNullOrWhiteSpace($originalContext.Tenant.Id)) {
    throw 'Sign in first with Connect-AzAccount -TenantId <tenant-id>, then run this script again.'
}
$subscriptions = @(Get-AzSubscription -TenantId $originalContext.Tenant.Id -ErrorAction Stop |
    Where-Object { $_.State -eq 'Enabled' })
if ($PSBoundParameters.ContainsKey('SubscriptionIds')) {
    $requested = @($SubscriptionIds -split ',' | ForEach-Object {
        $id = [guid]::Empty
        if (-not [guid]::TryParse($_.Trim(), [ref]$id)) {
            throw "Invalid subscription ID: $_"
        }
        $id.ToString()
    } | Select-Object -Unique)
    foreach ($id in $requested) {
        if ($id -notin $subscriptions.Id) {
            throw "Subscription $id is not enabled or accessible in the signed-in tenant."
        }
    }
    $subscriptions = @($subscriptions | Where-Object { $_.Id -in $requested })
}
if ($subscriptions.Count -eq 0) {
    throw 'No enabled subscriptions were found in the signed-in tenant.'
}

$end = [datetime]::UtcNow
$configuration = [pscustomobject]@{
    StartTimeUtc = $end.AddDays(-$SampleDays)
    EndTimeUtc = $end
    SampleDays = $SampleDays
    CostPerStorageAccount = $CostPerStorageAccount
    PricePer1MOverageTransactions = $PricePer1MOverageTransactions
    MalwareScanningPricePerGB = $MalwareScanningPricePerGB
    MalwareScanningCapGB = $MalwareScanningCapGB
}
$capDescription = if ($MalwareScanningCapGB -lt 0) {
    'Uncapped'
} else {
    $MalwareScanningCapGB.ToString([cultureinfo]::InvariantCulture)
}
Write-Information 'Microsoft Defender for Storage - Price Estimation' -InformationAction Continue
Write-Information "Version 4.2. Modeled scanning cap (GB/month per storage account): $capDescription." -InformationAction Continue
$results = [System.Collections.Generic.List[object]]::new()
try {
    foreach ($subscription in $subscriptions) {
        $context = Set-AzContext -SubscriptionId $subscription.Id -Scope Process -ErrorAction Stop
        $accounts = [System.Collections.Generic.List[object]]::new()
        $visitedPages = [System.Collections.Generic.HashSet[string]]::new()
        $nextPath = "/subscriptions/$($subscription.Id)/providers/Microsoft.Storage/storageAccounts?api-version=2023-05-01"
        while ($nextPath) {
            if (-not $visitedPages.Add($nextPath)) {
                throw "Repeated storage-account pagination URL for subscription $($subscription.Id)."
            }
            $page = Invoke-StorageEstimationGet -Path $nextPath -Context $context
            if ($null -eq $page.value) {
                throw "The storage-account list response has no value array for subscription $($subscription.Id)."
            }
            foreach ($account in $page.value) {
                $accounts.Add($account)
            }
            $nextPath = $page.nextLink
        }

        Write-Information "Estimating $($accounts.Count) accounts in subscription $($subscription.Id)." -InformationAction Continue
        if ($ThrottleLimit -eq 1) {
            $estimates = @($accounts | ForEach-Object {
                Get-StorageAccountCostEstimate -Account $_ -Context $context -Configuration $configuration
            })
        } else {
            $sizeDefinition = ${function:Format-StorageDataSize}.ToString()
            $requestDefinition = ${function:Invoke-StorageEstimationGet}.ToString()
            $estimateDefinition = ${function:Get-StorageAccountCostEstimate}.ToString()
            $estimates = @($accounts | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
                Set-Item -Path Function:\Format-StorageDataSize -Value (
                    [scriptblock]::Create($using:sizeDefinition)
                )
                Set-Item -Path Function:\Invoke-StorageEstimationGet -Value (
                    [scriptblock]::Create($using:requestDefinition)
                )
                $estimate = [scriptblock]::Create($using:estimateDefinition)
                & $estimate -Account $_ -Context $using:context -Configuration $using:configuration
            })
        }
        if ($estimates.Count -ne $accounts.Count) {
            throw "Not all storage accounts were estimated for subscription $($subscription.Id)."
        }
        $results.AddRange([object[]]$estimates)
    }
} finally {
    $null = Set-AzContext -Context $originalContext -Scope Process -ErrorAction Stop
}

if ($results.Count -eq 0) {
    throw 'No storage accounts were found in the selected subscriptions; no CSV was written.'
}
$ordered = @($results | Sort-Object SubscriptionId, StorageAccountName)
$ordered | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8 -ErrorAction Stop
$incomplete = @($ordered | Where-Object { $_.MetricsStatus -ne 'Complete' })
$total = [decimal]0
foreach ($row in $ordered) {
    if ($null -ne $row.StorageAccountCost) {
        $total += $row.StorageAccountCost
    }
    if ($null -ne $row.MalwareScanningCost) {
        $total += $row.MalwareScanningCost
    }
}
$total = [math]::Round($total, 2)
if ($incomplete.Count -gt 0) {
    Write-Warning "$($incomplete.Count) accounts have missing metrics. The known-cost subtotal is $total; a complete scoped total is unavailable."
} else {
    Write-Information "Estimated monthly cost: $total. Exported $($ordered.Count) accounts to $OutputPath." -InformationAction Continue
}
$ordered
