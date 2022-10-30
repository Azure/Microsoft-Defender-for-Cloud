$OverageBar = 73000000
$PricePer1MOverageTransactions = 0.1492
$CostPerStorageAccount = 10

if ($null -eq $(Get-AzContext)) {Connect-AzAccount}
$subscriptions = Get-AzSubscription
$subscriptionTotalCostArray =@()
$totalCost = 0
try{
    foreach ($subscriptionId in $subscriptions.Id)
    {
        $subscriptionOverageCost = 0
        Set-AzContext -Subscription $SubscriptionId -ErrorAction Stop
        $storageAccounts = Get-AzStorageAccount -ErrorAction Stop
        $startDate = (get-date (get-date).AddMonths(-1) -UFormat "%F")
        $endDate = Get-Date -UFormat "%F"
    
        Write-Host "Estimating the Microsoft Defender For Storage per-storage-account plan monthly cost for $($storageAccounts.Length) accounts"
        foreach ($storage in $storageAccounts){
            $metric = Get-AzMetric `
                -ResourceId $($storage.Id) `
                -MetricName Transactions `
                -AggregationType "Total" `
                -StartTime $startDate `
                -EndTime $endDate `
                -TimeGrain $(New-TimeSpan -Days 1) `
                -WarningAction SilentlyContinue `
                -ErrorAction Stop
    
            $totalTransactions = ($metric.Data.Total | Measure-Object -sum).Sum
            $overageTransactions = (($totalTransactions - $OverageBar) -ge 0) ? ($totalTransactions - $OverageBar) : 0
            $overageCost = $(($overageTransactions) / 1000000 * $PricePer1MOverageTransactions)
            $totalCost += $overageCost
            $subscriptionOverageCost += $overageCost
        }

        $subscriptionCostObject = New-Object PSObject -property @{
            subscriptionOverageCost = $subscriptionOverageCost;
            subscriptionBaseStorageCost = $storageAccounts.Length * $CostPerStorageAccount;
            numberOfStorageAccounts = $storageAccounts.Length;
            subscriptionId = $subscriptionId
        }
        $subscriptionTotalCostArray += $subscriptionCostObject
    
        $totalCost += $CostPerStorageAccount * $storageAccounts.Length
    }
}
catch
{
    $subscriptionTotalCostArray| ConvertTo-csv | out-file DefenderEstimatedCostBySubscription.csv
    Write-Error "The script encountered an error, partiall results were saved to a .csv file in the script directory"
    throw $PSItem
}

$subscriptionTotalCostArray| ConvertTo-csv | out-file DefenderEstimatedCostBySubscription.csv
Write-Host "Total Microsoft Defender for storage cost for $($subscriptions.Length) subscriptions in the per-storage-account pricing plan: $("{0:C2}" -f $totalCost)"