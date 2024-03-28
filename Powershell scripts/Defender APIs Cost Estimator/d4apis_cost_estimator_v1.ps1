# Ensure strict mode is enabled for catching common issues
Set-StrictMode -Version Latest

# Ensure you're logged in
try {
    $accountInfo = Connect-AzAccount
    if (-not $accountInfo) {
        throw "Failed to log in to Azure."
    }
} catch {
    Write-Error "Failed to log in to Azure. Please ensure you have the Az PowerShell module installed and internet access. Error: $_"
    exit
}

# Retrieve all subscriptions the user has access to
try {
    $subscriptions = Get-AzSubscription
    if (-not $subscriptions) {
        throw "No subscriptions found."
    }
} catch {
    Write-Error "Failed to retrieve subscriptions. Error: $_"
    exit
}

# Initialize a list to hold results for all subscriptions
$allSubscriptionsResults = @()

foreach ($sub in $subscriptions) {
    # Set the Azure context to the current subscription
    $context = Set-AzContext -SubscriptionId $sub.Id
    Write-Host "Processing Subscription: $($sub.Name) - $($sub.Id)"

    # Get all APIM services in the subscription
    try {
        $apimServices = Get-AzApiManagement
        if (-not $apimServices) {
            throw "No APIM services found."
        }
    } catch {
        Write-Error "Failed to retrieve APIM services. Please ensure you have APIM services deployed in your subscription. Error: $_"
        continue # Continue with the next subscription if this fails
    }

    # Define the time range for the last 30 days
    $startTime = (Get-Date).AddDays(-30).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $endTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    # Initialize a variable to hold the total requests for the current subscription
    $totalRequestsForSubscription = 0

    foreach ($apim in $apimServices) {
        Write-Host "APIM Service: $($apim.Name), Resource Group: $($apim.ResourceGroupName)"
        
        # Construct the resource ID for the APIM service using the correct subscription ID
        $resourceId = "/subscriptions/$($sub.Id)/resourceGroups/$($apim.ResourceGroupName)/providers/Microsoft.ApiManagement/service/$($apim.Name)"
        
        Write-Host "Retrieving 'Requests' metric for APIM Service: $($apim.Name)"
        try {
            $metrics = Get-AzMetric -ResourceId $resourceId -MetricName "Requests" -StartTime $startTime -EndTime $endTime -AggregationType Total
            if ($metrics -ne $null -and $metrics.Data -ne $null) {
                $serviceRequests = ($metrics.Data | Measure-Object Total -Sum).Sum
                Write-Host "`tTotal 'Requests' for the past 30 days: $serviceRequests"
                $totalRequestsForSubscription += $serviceRequests
            } else {
                Write-Host "`tNo data available for 'Requests' metric for the past 30 days."
            }
        } catch {
            Write-Host "`tError retrieving 'Requests' metric: $_"
        }
    }

    Write-Host "Total 'Requests' for the subscription over the past 30 days: $totalRequestsForSubscription"

    # Calculate costs for each plan taking the limit into consideration
    # Assuming plan details remain the same, and calculation logic applies per subscription
    $plans = @(
        @{ Name = "P1"; Fixed = 200; Overage = 0.00020; Limit = 1000000 },
        @{ Name = "P2"; Fixed = 700; Overage = 0.00014; Limit = 5000000 },
        @{ Name = "P3"; Fixed = 5000; Overage = 0.00010; Limit = 50000000 },
        @{ Name = "P4"; Fixed = 7000; Overage = 0.00007; Limit = 100000000 },
        @{ Name = "P5"; Fixed = 50000; Overage = 0.00005; Limit = 1000000000 }
    )
    $results = @()
    foreach ($plan in $plans) {
        if ($totalRequestsForSubscription -lt $plan.Limit) {
            $totalCost = $plan.Fixed
        } else {
            $totalOverage = $totalRequestsForSubscription - $plan.Limit
            $totalCost = $plan.Fixed + ($totalOverage * $plan.Overage)
        }
        $results += [PSCustomObject]@{
            Plan = $plan.Name
            TotalCost = $totalCost
        }
    }
    # Find the plan with the lowest cost
    $recommendedPlan = $results | Sort-Object TotalCost | Select-Object -First 1

    # Compile the subscription results
    $subscriptionResult = [PSCustomObject]@{
        SubscriptionID = $sub.Id
        SubscriptionName = $sub.Name
        TotalRequests = $totalRequestsForSubscription
        RecommendedPlan = $recommendedPlan.Plan
        RecommendedPlanCost = $recommendedPlan.TotalCost
    }

    # Add this subscription's results to the list
    $allSubscriptionsResults += $subscriptionResult
}

# Now, you can output or export $allSubscriptionsResults as needed
# Example: Export to CSV
$outputPath = "AllSubscriptionsPlanRecommendation.csv"
$allSubscriptionsResults | Export-Csv -Path $outputPath -NoTypeInformation -Force
Write-Host "Plan recommendations for all subscriptions exported to $outputPath successfully."