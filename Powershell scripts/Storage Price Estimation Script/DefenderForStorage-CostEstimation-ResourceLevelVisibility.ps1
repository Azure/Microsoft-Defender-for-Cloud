#Requires -Version 7.0
param(
    [string]$SubscriptionIds
)

# Declarations
$now = Get-Date
$lastMonth = $now.AddDays(-30)
$OverageBar = 73000000
$PricePer1MOverageTransactions = 0.1492
$CostPerStorageAccount = 10
$totalCost = 0
$subscriptionTotalCostArray = @()

if ($null -eq $(Get-AzContext)){Connect-AzAccount}


$subscriptions = $SubscriptionIds -split ',' | ForEach-Object { $_.Trim() }
if ([string]::IsNullOrWhiteSpace($SubscriptionIds)) {
    $subscriptions = Get-AzSubscription | ForEach-Object { $_.Id }
}

try {
    foreach($subId in $subscriptions){
        $null = Set-AzContext -SubscriptionId $subId -ErrorAction Stop
        $StorageAccounts = Get-AzStorageAccount -ErrorAction Stop
        $threadSafeDict = [System.Collections.Concurrent.ConcurrentDictionary[string, int]]::New()

        Write-Host "Estimating Defender For Storage monthly price for $($StorageAccounts.Length) accounts in $($subId)"

        $StorageAccounts | ForEach-Object -ThrottleLimit 15 -Parallel {
            $totalTransactionsPerSA = 0
            $now = $USING:now
            $lastMonth = $USING:lastMonth
            $dict = $USING:threadSafeDict
            $body = "{
                'requests':[
                    {
                        'httpMethod':'GET',
                        'relativeUrl': '$($_.id)/blobServices/default/providers/microsoft.Insights/metrics?timespan=$($lastMonth.ToString('u'))/$($now.ToString('u'))&interval=FULL&metricnames=Transactions&aggregation=total&metricNamespace=microsoft.storage%2Fstorageaccounts%2Fblobservices&validatedimensions=false&api-version=2019-07-01'
                    },
                    {
                        'httpMethod':'GET',
                        'relativeUrl':'$($_.id)/fileServices/default/providers/microsoft.Insights/metrics?timespan=$($lastMonth.ToString('u'))/$($now.ToString('u'))&interval=FULL&metricnames=Transactions&aggregation=total&metricNamespace=microsoft.storage%2Fstorageaccounts%2Ffileservices&validatedimensions=false&api-version=2019-07-01'
                    }
                ]
            }"
            $resp = Invoke-AzRestMethod -Method POST -Path '/batch?api-version=2015-11-01' -Payload $body
            $totalTransactionsPerSA += (($resp.Content | Convertfrom-json).responses.content.value.timeseries.data | Measure-Object -Property 'total' -Sum).Sum
            $null = $dict.TryAdd($_.Id, $totalTransactionsPerSA)
        }

        $storageAccountDetails = $StorageAccounts | ForEach-Object {
            $totalTransactionsPerSA = $threadSafeDict[$_.Id]
            $overageTransactionsPerSA = [Math]::Max($totalTransactionsPerSA - $OverageBar, 0)
            $overageCostPerSA = ($overageTransactionsPerSA / 1000000) * $PricePer1MOverageTransactions
            $storageAccountCost = $CostPerStorageAccount + $overageCostPerSA
            $oldEstimateCostPerSA = ($totalTransactionsPerSA / 10000) * 0.02
            $totalCost += $storageAccountCost

            [PSCustomObject]@{
                SubscriptionId = $subId
                StorageAccountName = $_.StorageAccountName
                StorageAccountCost = [Math]::Round($storageAccountCost, 2)  # Round to 2 decimal places
                StorageAccountTransactions = $totalTransactionsPerSA
                OldEstimateCost = [Math]::Round($oldEstimateCostPerSA, 2)  # Round to 2 decimal places
                OverageCost = $overageCostPerSA
                OverageTransactions = $overageTransactionsPerSA
            }
        }

        $subscriptionTotalCostArray += $storageAccountDetails
    }
}
catch {
    Write-Error "The script encountered an error: $_"
}

$output = @()
$output += """Total Defender for storage cost for $($subscriptions.Length) subscription: $("{0:C2}" -f $totalCost)"""
$output += $subscriptionTotalCostArray | ConvertTo-Csv -NoTypeInformation
$output += $overageCostPerSub
$output += $totalTransactionsPerSub

$output | Out-File -FilePath "CostEstimation.csv"
