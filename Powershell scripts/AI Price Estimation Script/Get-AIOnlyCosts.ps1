#Requires -Version 7.0
# Ensure strict mode is enabled for catching common issues
Set-StrictMode -Version Latest

# Ensure you're logged in
$accountInfo = $null
try {
    $accountInfo = Get-AzContext
    if (-not $accountInfo) {
        $accountInfo = Connect-AzAccount
        if (-not $accountInfo) {
            throw "Failed to log in to Azure."
        }
    }
} catch {
    Write-Error "Failed to log in to Azure. Please ensure you have the Az PowerShell module installed and internet access. Error: $_"
    exit
}

$environmentType = "Azure"
$allSubscriptionsResults = @()

# Retrieve all subscriptions the user has access to
try {
    $subscriptions = Get-AzSubscription -TenantId $accountInfo.Tenant.Id
    if (-not $subscriptions) {
         throw "No subscriptions found."
    }
} catch {
    Write-Error "Failed to retrieve subscriptions. Error: $_"
    exit
}

# Calculate metrics for Defender for AI
foreach ($sub in $subscriptions) {
    Write-Host "Processing Subscription: $($sub.Name) - $($sub.Id) for Defender for AI"
    $openAiUri = "/subscriptions/$($sub.Id)/providers/Microsoft.CognitiveServices/accounts?api-version=2023-05-01"

    $response = Invoke-AzRestMethod -Method GET -Path $openAiUri -ErrorAction Stop

    $openAiResources = ($response.Content | ConvertFrom-Json).value | Where-Object {
        $_.kind -in @("OpenAI", "AzureAIServices")
    }

    if (-not $openAiResources) {
        Write-Host "No Azure OpenAI resources found in Subscription: $($sub.Name)"
        continue
    }

    $threadSafeDict = [System.Collections.Concurrent.ConcurrentDictionary[string, [Int64]]]::New()

    $openAiResourcesCount = ($openAiResources | Measure-Object).Count
    Write-Host "Estimating token usage for $($openAiResourcesCount) Azure OpenAI resources in $($sub.Name)"

    $now = Get-Date
    $lastMonth = $now.AddMonths(-1)

    $openAiResources | ForEach-Object -ThrottleLimit 15 -Parallel {
        Write-Host "Processing OpenAI Resource: $($_.id)"
        $totalTokens = 0
        $now = $USING:now
        $lastMonth = $USING:lastMonth
        $dict = $USING:threadSafeDict
        $body = "{
            'requests':[{
                'httpMethod':'GET',
                'relativeUrl': '$($_.id)/providers/microsoft.Insights/metrics?timespan=$($lastMonth.ToString('u'))/$($now.ToString('u'))&interval=FULL&metricnames=TokenTransaction&aggregation=total&metricNamespace=microsoft.cognitiveservices%2Faccounts&validatedimensions=false&api-version=2019-07-01'
            }]
        }"
        $resp = Invoke-AzRestMethod -Method POST -Path '/batch?api-version=2015-11-01' -Payload $body
        $totalTokens += (($resp.Content | ConvertFrom-Json).responses.content.value.timeseries.data | Measure-Object -Property 'total' -Sum).Sum
        $null = $dict.TryAdd($_.Id, $totalTokens)
    }

    $tokens = $threadSafeDict.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum

    # Compile the subscription results
    $subscriptionResult = [PSCustomObject]@{
        SubscriptionID = $sub.Id
        SubscriptionName = $sub.Name
        ResourcesCount = $openAiResourcesCount
        BillableUnits = $tokens
        PlanName = "ai"
        EnvironmentType = $environmentType
    }

    # Add this subscription's results to the list
    $allSubscriptionsResults += $subscriptionResult
}

$outputPath = "AzureMDCResourcesEstimation_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$allSubscriptionsResults | Export-Csv -Path $outputPath -NoTypeInformation -Force
Write-Host "Plan recommendations for all subscriptions exported to $outputPath successfully."