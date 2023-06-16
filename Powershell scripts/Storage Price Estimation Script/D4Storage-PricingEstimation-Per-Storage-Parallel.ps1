#Requires -Version 7.0
# Declarations
$now = Get-Date
$lastMonth = $now.AddDays(-30)
$OverageBar = 73000000
$PricePer1MOverageTransactions = 0.1492
$CostPerStorageAccount = 10
$totalCost = 0
$subscriptionTotalCostArray =@()
if ($null -eq $(Get-AzContext)){Connect-AzAccount}
$Subscriptions = Get-AzSubscription
try{
    foreach($sub in $Subscriptions){
        $null = Set-AzContext -subscription $sub.id -ErrorAction Stop
        $StorageAccounts = Get-AzStorageAccount -ErrorAction Stop
        $threadSafeDict = [System.Collections.Concurrent.ConcurrentDictionary[string, int]]::New()
        Write-Verbose "Estimating Defender For Storage monthly price for $($StorageAccounts.Length) accounts in $($Sub.Name)"
        $StorageAccounts | ForEach-Object -ThrottleLimit 15 -Parallel{
            # Import-Module Az.Accounts
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
            $totalTransactionsPerSA += (($resp.Content | Convertfrom-json).responses.content.value.timeseries.data | measure-object -sum 'total').sum
            $null = $dict.TryAdd($_.Id, $totalTransactionsPerSA)
        }
        
        # Calculate the total number of transations in the subscription
        $totalTransactionsPerSub = ($threadSafeDict.Values | Measure-Object -Sum).Sum
        
        # Calculate the number of transactions above the ceiling
        $overageTransactionsPerSub = (($totalTransactionsPerSub - $overageBar) -ge 0) ? ($totalTransactionsPerSub - $overageBar) : 0
        
        # If the ceiling was exceeded, calculate the overage cost
        $overageCostPerSub = $(($overageTransactionsPerSub) / 1000000 * $PricePer1MOverageTransactions)
        $totalCostPerSub = $overageCostPerSub + ($CostPerStorageAccount * $StorageAccounts.Length)
        $totalCost += $totalCostPerSub
        
        $oldEstimate = ($totalTransactionsPerSub / 10000) * .02
        
        $subscriptionTotalCostArray += New-Object PSObject -Property @{
            SubscriptionId = $sub.Id
            NumberOfStorageAccounts = $StorageAccounts.Length
            SubScriptionBaseStorageCost = $storageAccounts.Length * $CostPerStorageAccount
            SubscriptionOverageCost = $overageTransactionsPerSub
            TotalCostForSub = $totalCostPerSub 
            OldPlanEstimate = $oldEstimate
        }
    }
}
catch{
    $subscriptionTotalCostArray | ConvertTo-Csv | Out-File PartialDefenderForStorageCostBySubscription.csv
    Write-Error "The script encountered an error, partial results were saved to a .csv file in the script directory"
}
$subscriptionTotalCostArray| ConvertTo-csv | out-file DefenderEstimatedCostBySubscription.csv
Write-Host "Total Defender for storage cost for $($subscriptions.Length) subscription: $("{0:C2}" -f $totalCost)"
