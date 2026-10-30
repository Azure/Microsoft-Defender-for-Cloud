#requires -Version 7.2
Set-StrictMode -Version Latest

function Get-D4ApiPricing {
    <#
    .SYNOPSIS
    Loads and validates the complete five-plan pricing reference.
    #>
    [CmdletBinding()]
    param([string]$Path = (Join-Path $PSScriptRoot 'pricing.json'))

    $pricing = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -AsHashtable
    foreach ($field in @('currency', 'verifiedOn', 'source', 'basis', 'plans')) {
        if (-not $pricing.ContainsKey($field) -or -not $pricing[$field]) {
            throw "Pricing file is missing '$field'."
        }
    }
    if ($pricing.plans.Count -ne 5 -or $pricing.currency -notmatch '^[A-Z]{3}$') {
        throw 'Pricing must specify a currency and exactly five plans, P1 through P5.'
    }
    $previousLimit = 0
    for ($index = 0; $index -lt 5; $index++) {
        $plan = $pricing.plans[$index]
        if ($plan.name -ne "P$($index + 1)") {
            throw 'Pricing plans must be ordered P1 through P5, without duplicates.'
        }
        foreach ($field in @('monthlyFee', 'includedCalls', 'overagePerCall')) {
            if (-not $plan.ContainsKey($field) -or $null -eq $plan[$field] -or
                $plan[$field] -is [string] -or $plan[$field] -is [bool] -or $plan[$field] -lt 0) {
                throw "Invalid '$field' for $($plan.name)."
            }
        }
        if ($plan.includedCalls -le $previousLimit -or $plan.includedCalls % 1 -ne 0) {
            throw 'Included-call allowances must be positive, integral and strictly increasing.'
        }
        $previousLimit = $plan.includedCalls
    }
    return $pricing
}

function Get-D4ApiPlanCost {
    <#
    .SYNOPSIS
    Calculates each plan's fixed fee and request overage for a traffic scenario.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateRange(0, [long]::MaxValue)][long]$Calls,
        [Parameter(Mandatory)][object[]]$Plans
    )

    foreach ($plan in $Plans) {
        $overage = [Math]::Max([long]0, $Calls - [long]$plan.includedCalls)
        [pscustomobject][ordered]@{
            Plan = $plan.name
            Requests = $Calls
            MonthlyFee = [decimal]$plan.monthlyFee
            IncludedCalls = [long]$plan.includedCalls
            OverageCalls = $overage
            OveragePerCall = [decimal]$plan.overagePerCall
            EstimatedMonthlyCost = [Math]::Round(
                ([decimal]$plan.monthlyFee + [decimal]$overage * [decimal]$plan.overagePerCall), 2)
        }
    }
}

function ConvertTo-D4ApiKey {
    <#
    .SYNOPSIS
    Decodes a final API identifier segment and removes its revision suffix.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)

    $name = [Uri]::UnescapeDataString($Value.Trim().TrimEnd('/').Split('/')[-1])
    return ($name -replace '(?i);rev=[^;]+$', '').ToLowerInvariant()
}

function Invoke-D4ApiGet {
    <#
    .SYNOPSIS
    Performs a bounded, authenticated read of Azure commercial Resource Manager.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if ($Path -notmatch '^/subscriptions/' -and $Path -notmatch '^https://management\.azure\.com/') {
        throw 'Only subscription-scoped Azure commercial Resource Manager GET requests are allowed.'
    }
    for ($attempt = 0; $attempt -lt 4; $attempt++) {
        $status = 0
        $requestError = $null
        try {
            $arguments = @{ Method = 'GET'; ErrorAction = 'Stop' }
            if ($Path.StartsWith('https://', [StringComparison]::OrdinalIgnoreCase)) {
                $arguments.Uri = $Path
            } else {
                $arguments.Path = $Path
            }
            $response = Invoke-AzRestMethod @arguments
            $status = [int]$response.StatusCode
        } catch {
            $requestError = $_
            if ($_.Exception.PSObject.Properties['Response'] -and $_.Exception.Response -and
                $_.Exception.Response.PSObject.Properties['StatusCode']) {
                $status = [int]$_.Exception.Response.StatusCode
            }
        }
        if ($status -eq 200) {
            return ($response.Content | ConvertFrom-Json -AsHashtable -ErrorAction Stop)
        }
        if ($status -in @(408, 429, 500, 502, 503, 504) -and $attempt -lt 3) {
            Write-Warning "ARM GET returned HTTP $status; retrying (attempt $($attempt + 2) of 4)."
            Start-Sleep -Seconds ([Math]::Pow(2, $attempt))
            continue
        }
        if ($requestError) {
            throw $requestError
        }
        throw "ARM GET failed with HTTP $status for $Path"
    }
}

function Get-D4ApiPagedResource {
    <#
    .SYNOPSIS
    Returns a complete ARM resource list only after every page succeeds.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $items = [Collections.Generic.List[object]]::new()
    $visited = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    do {
        if (-not $visited.Add($Path)) {
            throw 'ARM pagination returned a repeated nextLink; inventory is incomplete.'
        }
        $page = Invoke-D4ApiGet -Path $Path
        if (-not $page.ContainsKey('value') -or $null -eq $page.value -or $page.value -isnot [array]) {
            throw 'ARM list response did not contain a value array; inventory is incomplete.'
        }
        foreach ($item in $page.value) {
            $items.Add($item)
        }
        $Path = [string]$page['nextLink']
    } while ($Path)
    return $items.ToArray()
}

function Get-D4ApiEligibility {
    <#
    .SYNOPSIS
    Classifies an API against the documented tier, region and REST scope.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Service,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Api
    )

    $sku = [string]$Service.sku.name
    $properties = $Api.properties
    $apiType = [string]$properties['type']
    if (-not $apiType) {
        # The APIM REST contract omits type for ordinary HTTP APIs, including its list sample.
        $apiType = 'http'
    }
    $status = 'Eligible'
    $reason = 'REST API on the managed gateway; workspace and self-hosted traffic are out of scope.'
    $regions = @(
        'southeastasia', 'eastasia', 'australiaeast', 'australiasoutheast', 'australiacentral',
        'australiacentral2', 'brazilsouth', 'brazilsoutheast', 'canadacentral', 'canadaeast',
        'westeurope', 'northeurope', 'francecentral', 'francesouth', 'germanywestcentral',
        'germanynorth', 'centralindia', 'southindia', 'westindia', 'italynorth', 'japaneast',
        'japanwest', 'koreacentral', 'koreasouth', 'norwayeast', 'norwaywest', 'southafricanorth',
        'southafricawest', 'swedencentral', 'swedensouth', 'switzerlandnorth', 'switzerlandwest',
        'uaecentral', 'uaenorth', 'uksouth', 'ukwest', 'eastus', 'eastus2', 'westus', 'westus2',
        'westus3', 'centralus', 'northcentralus', 'southcentralus', 'westcentralus',
        'eastus2euap', 'centraluseuap'
    )
    $locations = @([string]$Service.location)
    foreach ($additional in @($Service.properties['additionalLocations'])) {
        if ($additional) {
            $locations += [string]$additional.location
        }
    }
    if ($sku -eq 'Consumption') {
        $status = 'Not eligible'
        $reason = 'The Consumption tier is not supported by Defender for APIs.'
    } elseif ($apiType -in @('soap', 'graphql', 'websocket', 'odata', 'mcp')) {
        $status = 'Not eligible'
        $reason = "API type '$apiType' is outside the documented REST API scope."
    } elseif ($properties.Contains('isOnline') -and $properties.isOnline -eq $false) {
        $status = 'Not eligible'
        $reason = 'The API revision is offline.'
    } elseif ($sku -notin @('Developer', 'Basic', 'Standard', 'Premium')) {
        $status = 'Review'
        $reason = "Tier '$sku' is not in the verified support list; do not assume v2 tier support."
    } elseif ($apiType -ne 'http') {
        $status = 'Review'
        $reason = "API type '$apiType' needs support verification."
    } elseif (@($locations | Where-Object { ($_ -replace '\s', '').ToLowerInvariant() -notin $regions }).Count) {
        $status = 'Review'
        $reason = 'A primary or secondary region is outside the verified support list.'
    }
    return [pscustomobject]@{ Status = $status; Reason = $reason; ApiType = $apiType }
}

function ConvertFrom-D4ApiMetric {
    <#
    .SYNOPSIS
    Validates request samples and combines revision series by logical API.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Response,
        [switch]$SplitByApi,
        [int]$SeriesLimit = 10000
    )

    $metrics = @($Response['value'] | Where-Object { $_.name.value -eq 'Requests' })
    if ($metrics.Count -ne 1) {
        throw 'The metrics response did not contain exactly one Requests metric.'
    }
    $metric = $metrics[0]
    if ($metric['errorCode'] -and $metric.errorCode -ne 'Success') {
        throw "Requests metric failed: $($metric.errorCode)."
    }
    $series = @($metric['timeseries'])
    $byApi = @{}
    $total = [decimal]0
    $hasData = $false
    $partial = $false
    foreach ($item in $series) {
        if (-not $item) { continue }
        $points = @($item['data'])
        $knownPoints = @($points | Where-Object { $null -ne $_ -and $null -ne $_['total'] })
        $known = $knownPoints.Count -gt 0 -and $knownPoints.Count -eq $points.Count
        $calls = [decimal]0
        foreach ($point in $knownPoints) {
            $value = [decimal]$point.total
            if ($value -lt 0 -or $value % 1 -ne 0 -or $value -gt [long]::MaxValue) {
                throw 'Requests must be a nonnegative integral call count.'
            }
            $calls += $value
        }
        $total += $calls
        $hasData = $hasData -or $known
        $partial = $partial -or (-not $known)
        if ($SplitByApi) {
            $dimensions = @($item['metadatavalues'] | Where-Object { $_.name.value -eq 'ApiId' })
            if ($dimensions.Count -ne 1) {
                throw 'A split metric series is missing its ApiId dimension.'
            }
            $key = ConvertTo-D4ApiKey -Value ([string]$dimensions[0].value)
            if (-not $byApi.ContainsKey($key)) {
                $byApi[$key] = @{ Requests = [decimal]0; Known = $true }
            }
            $byApi[$key].Requests += $calls
            $byApi[$key].Known = $byApi[$key].Known -and $known
        }
    }
    $status = if ($SplitByApi -and $series.Count -ge $SeriesLimit) { 'Truncated' }
        elseif ($partial) { 'Incomplete' } elseif ($hasData) { 'Observed' } else { 'No data' }
    return [pscustomobject]@{
        Status = $status
        Requests = $(if ($hasData -and -not $partial) { [long]$total } else { $null })
        ByApi = $byApi
    }
}

function Get-D4ApiUsage {
    <#
    .SYNOPSIS
    Reads reconciled API traffic only when no self-hosted gateways are registered.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ServiceId,
        [Parameter(Mandatory)][datetime]$StartTime,
        [Parameter(Mandatory)][datetime]$EndTime
    )

    $gateways = @(Get-D4ApiPagedResource -Path "$ServiceId/gateways?api-version=2024-05-01")
    if ($gateways.Count -gt 0) {
        Write-Warning 'Registered self-hosted gateways can contribute Requests metrics. Managed-gateway traffic cannot be isolated; metric-based recommendations are withheld.'
        return [pscustomobject]@{
            Status = 'Managed gateway scope unverified'
            Requests = $null
            ByApi = @{}
        }
    }

    $timespan = [Uri]::EscapeDataString(
        "$($StartTime.ToUniversalTime().ToString('o'))/$($EndTime.ToUniversalTime().ToString('o'))")
    $path = "$ServiceId/providers/Microsoft.Insights/metrics?api-version=2023-10-01" +
        "&metricnamespace=Microsoft.ApiManagement%2Fservice&metricnames=Requests&aggregation=Total" +
        "&interval=FULL&timespan=$timespan"
    $aggregateResponse = Invoke-D4ApiGet -Path $path
    $filter = [Uri]::EscapeDataString("ApiId eq '*'")
    $splitResponse = Invoke-D4ApiGet -Path "$path&`$filter=$filter&top=10000"
    foreach ($response in @($aggregateResponse, $splitResponse)) {
        $window = ([string]$response['timespan']).Split('/')
        if ($window.Count -ne 2 -or [datetimeoffset]$window[0] -ne [datetimeoffset]$StartTime -or
            [datetimeoffset]$window[1] -ne [datetimeoffset]$EndTime) {
            throw 'The metrics response does not cover the requested 30-day window.'
        }
    }
    $aggregate = ConvertFrom-D4ApiMetric -Response $aggregateResponse
    $split = ConvertFrom-D4ApiMetric -Response $splitResponse -SplitByApi
    if ($aggregate.Status -eq 'Observed' -and $split.Status -eq 'Observed' -and
        $aggregate.Requests -ne $split.Requests) {
        throw 'Split ApiId traffic does not reconcile to the service Requests total; estimates are withheld.'
    }
    return [pscustomobject]@{
        Status = $(if ($aggregate.Status -ne 'Observed') { $aggregate.Status } else { $split.Status })
        Requests = $aggregate.Requests
        ByApi = $split.ByApi
    }
}

function Get-D4ApiSubscriptionEstimate {
    <#
    .SYNOPSIS
    Models rollout and current-coverage costs without treating missing data as zero.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SubscriptionID,
        [Parameter(Mandatory)][string]$SubscriptionName,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Apis,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Services,
        [Parameter(Mandatory)][object[]]$Plans,
        [bool]$InventoryComplete,
        [bool]$OnboardingComplete,
        [ValidateSet('Enabled', 'Disabled', 'Unknown')][string]$DefenderStatus,
        [AllowEmptyString()][string]$CurrentPlan
    )

    $eligible = @($Apis | Where-Object Eligibility -EQ 'Eligible')
    $review = @($Apis | Where-Object Eligibility -EQ 'Review')
    $onboarded = @($Apis | Where-Object OnboardingStatus -EQ 'Onboarded')
    $missingEligible = @($eligible | Where-Object UsageStatus -NE 'Observed')
    $missingOnboarded = @($onboarded | Where-Object UsageStatus -NE 'Observed')
    $uncertainOnboarding = @($Apis | Where-Object { $_.OnboardingStatus -notin @('Onboarded', 'Not onboarded') })
    $onboardingVerified = $OnboardingComplete -and $uncertainOnboarding.Count -eq 0
    $costs = [Collections.Generic.List[object]]::new()
    $eligibleRequests = $null
    $onboardedRequests = $null
    $recommended = $null
    $currentRecommended = $null
    $currentCost = $null
    $savings = $null
    $estimateStatus = if (-not $InventoryComplete) { 'Incomplete inventory' }
        elseif ($review.Count) { 'Review eligibility' }
        elseif (-not $eligible.Count) { 'No eligible APIs' }
        elseif ($missingEligible.Count) { 'Incomplete telemetry' }
        else { 'Modeled - current configuration' }
    if ($estimateStatus -eq 'Modeled - current configuration') {
        $eligibleRequests = [long](($eligible | Measure-Object Requests30Days -Sum).Sum)
        $rolloutCosts = @(Get-D4ApiPlanCost -Calls $eligibleRequests -Plans $Plans)
        $recommended = $rolloutCosts | Sort-Object EstimatedMonthlyCost, Plan | Select-Object -First 1
        $configuredRolloutCost = $rolloutCosts | Where-Object Plan -EQ $CurrentPlan | Select-Object -First 1
        if ($DefenderStatus -eq 'Enabled' -and $configuredRolloutCost -and
            $configuredRolloutCost.EstimatedMonthlyCost -eq $recommended.EstimatedMonthlyCost) {
            $recommended = $configuredRolloutCost
        }
        foreach ($cost in $rolloutCosts) {
            $row = [ordered]@{
                SubscriptionID = $SubscriptionID; SubscriptionName = $SubscriptionName
                CoverageScope = 'All eligible APIs'; IsRecommended = ($cost.Plan -eq $recommended.Plan)
                IsCurrentPlan = ($DefenderStatus -eq 'Enabled' -and $cost.Plan -eq $CurrentPlan)
            }
            foreach ($property in $cost.PSObject.Properties) { $row[$property.Name] = $property.Value }
            $costs.Add([pscustomobject]$row)
        }
    }
    $optimizationStatus = if ($DefenderStatus -eq 'Disabled') { 'Disabled - rollout estimate only' }
        elseif ($DefenderStatus -eq 'Unknown') { 'Unknown subscription plan status' }
        elseif (-not $InventoryComplete) { 'Incomplete inventory' }
        elseif (-not $onboardingVerified) { 'Incomplete onboarding inventory' }
        elseif (@($onboarded | Where-Object Eligibility -NE 'Eligible').Count) { 'Review onboarded API eligibility' }
        elseif ($CurrentPlan -notin @($Plans | ForEach-Object { $_.name })) { 'Unknown configured subplan' }
        elseif ($missingOnboarded.Count) { 'Incomplete onboarded-API telemetry' }
        else { 'Ready' }
    if ($optimizationStatus -eq 'Ready') {
        $onboardedRequests = if ($onboarded.Count) {
            [long](($onboarded | Measure-Object Requests30Days -Sum).Sum)
        } else { [long]0 }
        $currentCosts = @(Get-D4ApiPlanCost -Calls $onboardedRequests -Plans $Plans)
        $currentCost = $currentCosts | Where-Object Plan -EQ $CurrentPlan | Select-Object -First 1
        $currentRecommended = $currentCosts | Sort-Object EstimatedMonthlyCost, Plan | Select-Object -First 1
        if ($currentCost.EstimatedMonthlyCost -eq $currentRecommended.EstimatedMonthlyCost) {
            $currentRecommended = $currentCost
        }
        $savings = $currentCost.EstimatedMonthlyCost - $currentRecommended.EstimatedMonthlyCost
        $optimizationStatus = if (-not $onboarded.Count) { 'Enabled with no onboarded APIs - review coverage' }
            elseif ($savings -eq 0) { 'Best fit for modeled traffic' }
            else { "Review $($currentRecommended.Plan) for modeled traffic" }
        foreach ($cost in $currentCosts) {
            $row = [ordered]@{
                SubscriptionID = $SubscriptionID; SubscriptionName = $SubscriptionName
                CoverageScope = 'Currently onboarded APIs'
                IsRecommended = ($cost.Plan -eq $currentRecommended.Plan); IsCurrentPlan = ($cost.Plan -eq $CurrentPlan)
            }
            foreach ($property in $cost.PSObject.Properties) { $row[$property.Name] = $property.Value }
            $costs.Add([pscustomobject]$row)
        }
    }
    $summary = [pscustomobject][ordered]@{
        SubscriptionID = $SubscriptionID
        SubscriptionName = $SubscriptionName
        DefenderForApisStatus = $DefenderStatus
        CurrentPlan = $CurrentPlan
        InventoryStatus = $(if ($InventoryComplete) { 'Complete' } else { 'Incomplete' })
        APIMServices = $Services.Count
        DiscoveredApis = $Apis.Count
        EligibleApis = $eligible.Count
        IneligibleApis = @($Apis | Where-Object Eligibility -EQ 'Not eligible').Count
        ReviewApis = $review.Count
        OnboardedApis = $(if ($onboardingVerified) { $onboarded.Count } else { $null })
        UnprotectedEligibleApis = $(if ($onboardingVerified -and $DefenderStatus -ne 'Unknown') {
            @($eligible | Where-Object { $_.ProtectionStatus -ne 'Onboarded - plan enabled' }).Count
        } else { $null })
        MissingUsageApis = $missingEligible.Count
        TotalRequests = $eligibleRequests
        RecommendedPlan = $(if ($recommended) { $recommended.Plan } else { $null })
        RecommendedPlanCost = $(if ($recommended) { $recommended.EstimatedMonthlyCost } else { $null })
        EstimateStatus = $estimateStatus
        OnboardedRequests = $onboardedRequests
        CurrentScopeRecommendedPlan = $(if ($currentRecommended) { $currentRecommended.Plan } else { $null })
        CurrentScopeRecommendedCost = $(if ($currentRecommended) { $currentRecommended.EstimatedMonthlyCost } else { $null })
        CurrentPlanEstimatedCost = $(if ($currentCost) { $currentCost.EstimatedMonthlyCost } else { $null })
        EstimatedMonthlySavings = $savings
        OptimizationStatus = $optimizationStatus
    }
    return [pscustomobject]@{ Summary = $summary; PlanCosts = $costs.ToArray() }
}

function Get-D4ApiSubscriptionReport {
    <#
    .SYNOPSIS
    Collects read-only subscription configuration, API inventory and quality evidence.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SubscriptionID,
        [Parameter(Mandatory)][string]$SubscriptionName,
        [Parameter(Mandatory)][object[]]$Plans,
        [Parameter(Mandatory)][datetime]$StartTime,
        [Parameter(Mandatory)][datetime]$EndTime
    )

    $issues = [Collections.Generic.List[object]]::new()
    $apis = [Collections.Generic.List[object]]::new()
    $services = [Collections.Generic.List[object]]::new()
    $addIssue = {
        param($stage, $resourceId, $message, $severity = 'Error')
        Write-Warning "$SubscriptionName / $stage : $message"
        $issues.Add([pscustomobject]@{
            SubscriptionID = $SubscriptionID; SubscriptionName = $SubscriptionName
            Severity = $severity; Stage = $stage; ResourceId = $resourceId; Message = $message
        })
    }
    $status = 'Unknown'
    $currentPlan = ''
    try {
        $pricing = Invoke-D4ApiGet -Path "/subscriptions/$SubscriptionID/providers/Microsoft.Security/pricings/Api?api-version=2024-01-01"
        $tier = [string]$pricing.properties['pricingTier']
        if ($tier -notin @('Free', 'Standard')) { throw "Unrecognized pricing tier '$tier'." }
        $status = if ($tier -eq 'Standard') { 'Enabled' } else { 'Disabled' }
        $currentPlan = [string]$pricing.properties['subPlan']
        if ($status -eq 'Enabled' -and $currentPlan -notin @($Plans | ForEach-Object { $_.name })) {
            & $addIssue 'Subscription plan' "/subscriptions/$SubscriptionID" "Configured subplan '$currentPlan' is not recognized; current-plan estimates are withheld." 'Warning'
        }
    } catch { & $addIssue 'Subscription plan' "/subscriptions/$SubscriptionID" $_.Exception.Message }

    $onboardingComplete = $true
    $collections = @{}
    try {
        $onboarding = @(Get-D4ApiPagedResource -Path "/subscriptions/$SubscriptionID/providers/Microsoft.Security/apiCollections?api-version=2023-11-15")
        foreach ($collection in $onboarding) {
            $serviceId = [string]$collection.properties['discoveredVia']
            if (-not $serviceId) {
                $serviceId = [string]($collection.id -replace '(?i)/providers/Microsoft.Security/apiCollections/.*$', '')
            }
            if ($serviceId -notmatch "(?i)^/subscriptions/$([regex]::Escape($SubscriptionID))/resourceGroups/[^/]+/providers/Microsoft.ApiManagement/service/[^/]+$") {
                throw 'An onboarded collection could not be mapped to an APIM service in this subscription.'
            }
            $key = "$serviceId/apis/$(ConvertTo-D4ApiKey -Value $collection.name)".ToLowerInvariant()
            $collections[$key] = [string]$collection.properties['provisioningState']
        }
    } catch {
        $onboardingComplete = $false
        & $addIssue 'Onboarding inventory' "/subscriptions/$SubscriptionID" $_.Exception.Message
    }

    $inventoryComplete = $true
    $instances = @()
    try {
        $instances = @(Get-D4ApiPagedResource -Path "/subscriptions/$SubscriptionID/providers/Microsoft.ApiManagement/service?api-version=2024-05-01")
    } catch {
        $inventoryComplete = $false
        & $addIssue 'APIM inventory' "/subscriptions/$SubscriptionID" $_.Exception.Message
    }
    foreach ($service in $instances) {
        $serviceRow = [pscustomobject][ordered]@{
            SubscriptionID = $SubscriptionID; SubscriptionName = $SubscriptionName
            ServiceId = $service.id; ServiceName = $service.name
            ResourceGroup = $service.id.Split('/')[4]; Location = $service.location
            Sku = $service.sku.name; InventoryStatus = 'Complete'; ApiCollections = $null
            UsageStatus = 'Not queried'; AllServiceRequests30Days = $null
        }
        $services.Add($serviceRow)
        $serviceApis = @()
        try {
            $rawApis = @(Get-D4ApiPagedResource -Path "$($service.id)/apis?api-version=2024-05-01")
            # Revisions share onboarding and an entitlement; retain one logical API collection.
            $groups = $rawApis | Group-Object { ConvertTo-D4ApiKey -Value $_.name }
            $serviceApis = @($groups | ForEach-Object {
                $_.Group | Sort-Object { $_.properties['isCurrent'] -eq $true } -Descending | Select-Object -First 1
            })
            $serviceRow.ApiCollections = $serviceApis.Count
        } catch {
            $inventoryComplete = $false
            $serviceRow.InventoryStatus = 'Incomplete'
            & $addIssue 'API inventory' $service.id $_.Exception.Message
            continue
        }
        $usage = $null
        $potentiallyEligible = @($serviceApis | Where-Object {
            (Get-D4ApiEligibility -Service $service -Api $_).Status -ne 'Not eligible'
        })
        if ($potentiallyEligible.Count) {
            try {
                $usage = Get-D4ApiUsage -ServiceId $service.id -StartTime $StartTime -EndTime $EndTime
                $serviceRow.UsageStatus = $usage.Status
                $serviceRow.AllServiceRequests30Days = $usage.Requests
                if ($usage.Status -ne 'Observed') {
                    & $addIssue 'Metrics' $service.id "Requests telemetry is '$($usage.Status)'; affected recommendations are withheld." 'Warning'
                }
            } catch {
                $serviceRow.UsageStatus = 'Error'
                & $addIssue 'Metrics' $service.id $_.Exception.Message
            }
        }
        foreach ($api in $serviceApis) {
            $key = ConvertTo-D4ApiKey -Value $api.name
            $apiId = "$($service.id)/apis/$key"
            $eligibility = Get-D4ApiEligibility -Service $service -Api $api
            $onboarded = if (-not $onboardingComplete) { 'Unknown' }
                elseif (-not $collections.ContainsKey($apiId.ToLowerInvariant())) { 'Not onboarded' }
                elseif ($collections[$apiId.ToLowerInvariant()] -eq 'Succeeded') { 'Onboarded' }
                elseif ([string]::IsNullOrWhiteSpace($collections[$apiId.ToLowerInvariant()])) {
                    'Unknown - provisioning state not returned'
                }
                else { "Review provisioning: $($collections[$apiId.ToLowerInvariant()])" }
            $usageStatus = $serviceRow.UsageStatus
            $requests = $null
            if ($usage -and $usage.Status -eq 'Observed') {
                if ($usage.ByApi.ContainsKey($key) -and $usage.ByApi[$key].Known) {
                    $usageStatus = 'Observed'
                    $requests = [long]$usage.ByApi[$key].Requests
                } else { $usageStatus = 'No data' }
            }
            $protection = if ($status -eq 'Disabled') { 'Subscription plan disabled' }
                elseif ($status -eq 'Unknown') { 'Unknown subscription plan status' }
                elseif ($onboarded -eq 'Onboarded') { 'Onboarded - plan enabled' }
                else { $onboarded }
            $apis.Add([pscustomobject][ordered]@{
                SubscriptionID = $SubscriptionID; SubscriptionName = $SubscriptionName
                ServiceId = $service.id; ServiceName = $service.name
                ResourceGroup = $serviceRow.ResourceGroup; Location = $service.location; Sku = $service.sku.name
                ApiId = $apiId; ApiName = $key; DisplayName = $api.properties['displayName']
                ApiType = $eligibility.ApiType; Eligibility = $eligibility.Status; EligibilityReason = $eligibility.Reason
                OnboardingStatus = $onboarded; ProtectionStatus = $protection
                Requests30Days = $requests; UsageStatus = $usageStatus
            })
        }
    }
    $discoveredIds = @{}
    foreach ($api in $apis) { $discoveredIds[$api.ApiId.ToLowerInvariant()] = $true }
    $unmatched = @($collections.Keys | Where-Object { -not $discoveredIds.ContainsKey($_) })
    if ($onboardingComplete -and $unmatched.Count) {
        $onboardingComplete = $false
        & $addIssue 'Onboarding reconciliation' "/subscriptions/$SubscriptionID" 'An onboarded collection is absent from the API inventory; current-scope estimates are withheld.'
    }
    foreach ($api in $apis) {
        if ($api.Eligibility -eq 'Review' -or ($api.Eligibility -eq 'Eligible' -and $api.UsageStatus -ne 'Observed') -or
            $api.OnboardingStatus -notin @('Onboarded', 'Not onboarded')) {
            & $addIssue 'API data quality' $api.ApiId "$($api.Eligibility): $($api.EligibilityReason) Onboarding: $($api.OnboardingStatus). Usage: $($api.UsageStatus)." 'Warning'
        }
    }
    $estimate = Get-D4ApiSubscriptionEstimate -SubscriptionID $SubscriptionID -SubscriptionName $SubscriptionName `
        -Apis $apis.ToArray() -Services $services.ToArray() -Plans $Plans -InventoryComplete $inventoryComplete `
        -OnboardingComplete $onboardingComplete -DefenderStatus $status -CurrentPlan $currentPlan
    return [pscustomobject]@{
        Summary = $estimate.Summary; Apis = $apis.ToArray(); Services = $services.ToArray()
        PlanCosts = $estimate.PlanCosts; Issues = $issues.ToArray()
    }
}

Export-ModuleMember -Function Get-D4ApiPricing, Get-D4ApiPlanCost, ConvertTo-D4ApiKey,
    Invoke-D4ApiGet, Get-D4ApiPagedResource, Get-D4ApiEligibility, ConvertFrom-D4ApiMetric,
    Get-D4ApiUsage, Get-D4ApiSubscriptionEstimate, Get-D4ApiSubscriptionReport
