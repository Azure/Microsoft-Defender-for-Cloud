#Requires -Version 7.0
# Azure Raw Billable Data Script
# Outputs one row per subscription with billable values per plan
# Resource-based plans: count of resources
# Consumption-based plans: raw usage metrics
# DCSPM: broken down by resource category (Servers, Storage, Databases, Serverless)
#
# Prerequisites:
#   - PowerShell 7.0+
#   - Az PowerShell module (Install-Module -Name Az)
#   - Azure CLI (https://aka.ms/installazurecli) - required for Container Registry Images collection

Set-StrictMode -Version Latest

# ============================================================================
# PREREQUISITES CHECK
# ============================================================================
# Validate all Az submodules used by this script up front; without them the script would fail mid-run with a
# cryptic command-not-found error.
$requiredAzModules = @('Az.Accounts', 'Az.ResourceGraph', 'Az.Monitor')
# Force array (@(...)) so .Count is always defined - a bare Where-Object can return
# $null or a single scalar under Strict Mode, both of which lack the .Count property.
$missingAzModules = @($requiredAzModules | Where-Object { -not (Get-Module -ListAvailable -Name $_) })

if ($missingAzModules.Count -gt 0) {
    $moduleList = ($missingAzModules -join ', ')
    $installCmd = ($missingAzModules | ForEach-Object { "Install-Module -Name $_ -Scope CurrentUser -Force" }) -join '; '
    Write-Error "Missing required Az PowerShell module(s): $moduleList. Please install them and re-run the script. Example: $installCmd"
    exit
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Warning "Azure CLI is not installed. Container Registry Images collection will be skipped. Install from: https://aka.ms/installazurecli"
}

# ============================================================================
# AUTHENTICATION
# ============================================================================
$accountInfo = $null

try {
    $accountInfo = Get-AzContext
    if (-not $accountInfo) {
        $loginResult = Connect-AzAccount
        if (-not $loginResult) {
            throw "Failed to log in to Azure."
        }
        $accountInfo = $loginResult.Context
        if (-not $accountInfo) {
            throw "Failed to retrieve AzContext after login."
        }
    }
} catch {
    Write-Error "Failed to log in to Azure. Please ensure you have the Az PowerShell module installed and internet access. Error: $_"
    exit
}

# ============================================================================
# GET SUBSCRIPTIONS
# ============================================================================
try {
    Write-Host "Scanning for subscriptions (this may take a moment)..." -ForegroundColor Yellow
    $subscriptions = Get-AzSubscription -TenantId $accountInfo.Tenant.Id
    if (-not $subscriptions) {
        throw "No subscriptions found."
    }
    Write-Host "Found $($subscriptions.Count) subscriptions" -ForegroundColor Yellow
} catch {
    Write-Error "Failed to retrieve subscriptions. Error: $_"
    exit
}

# ============================================================================
# USER CONFIGURATION (all prompts upfront so you can set and walk away)
# ============================================================================
Write-Host "`n=== Configuration ===" -ForegroundColor Cyan
Write-Host "Please answer the following questions. Once done, the script will run unattended.`n" -ForegroundColor Yellow

$runAdditionalDataCollection = Read-Host "Do you want to run extended data collection for usage-based signals (Containers node count, API requests, CosmosDB RU/s, Malware Scanning GB, AI tokens, Container Registry Images)? This can take longer depending on the size of your environment. Selecting 'no' will skip all extended data collection. (y/n)"

$runAcrCollection = 'n'
if ($runAdditionalDataCollection -eq 'yes' -or $runAdditionalDataCollection -eq 'y') {
    $azCliAvailable = [bool](Get-Command az -ErrorAction SilentlyContinue)
    if ($azCliAvailable) {
        Write-Host ""
        Write-Host "NOTE: Container Registry Images collection requires:" -ForegroundColor Yellow
        Write-Host "  - 'AcrPull' role (or higher: AcrPush, Contributor, Owner) on each registry" -ForegroundColor Yellow
        Write-Host "  - Azure CLI must be installed and logged in" -ForegroundColor Yellow
        $runAcrCollection = Read-Host "`nDo you want to collect Container Registry Images? This requires AcrPull permissions on registries. (y/n)"
    } else {
        Write-Warning "Azure CLI not found. Container Registry Images collection will be skipped. Install from: https://aka.ms/installazurecli"
    }
}

Write-Host "`n=== Configuration complete. Running data collection... ===`n" -ForegroundColor Green

$environmentType = "Azure"

# Timing dictionary to track duration of each section
$sectionTimings = [ordered]@{}

# ============================================================================
# INITIALIZE RESULTS DICTIONARY (per subscription)
# ============================================================================
$subscriptionResults = @{}

foreach ($sub in $subscriptions) {
    $subscriptionResults[$sub.Id] = [ordered]@{
        SubscriptionID              = $sub.Id
        SubscriptionName            = $sub.Name
        EnvironmentType             = $environmentType
        # Resource-based plans
        Servers                     = 0   # VMs (excluding AKS nodes)
        Containers                  = 0   # Node count
        AppServices                 = 0
        KeyVaults                   = 0
        ARM                         = 1   # Always 1 per subscription
        StorageAccounts             = 0
        Databases                   = 0   # SQL Servers, SQL Server VMs, Open Source DBs
        # DCSPM breakdown
        DCSPM_Servers               = 0   # VMs, VMSS
        DCSPM_Storage               = 0   # Storage accounts
        DCSPM_Databases             = 0   # SQL, OpenSourceDBs
        DCSPM_Serverless            = 0   # Web Apps, Function Apps
        # Consumption-based plans
        API_Requests                = 0
        CosmosDB_RUs                = 0
        MalwareScanning_GB          = 0
        AI_Tokens                   = 0
        ContainerRegistry_Images    = 0
        Servers_All                 = 0   # All VMs including AKS nodes
    }
}

# ============================================================================
# HELPER FUNCTION: Execute ARG Query with Pagination
# ============================================================================
function Invoke-AzGraphQueryPaged {
    param (
        [string]$Query
    )
    
    $results = @()
    $pageSize = 1000
    $skipToken = $null

    # Drive the loop off SkipToken — ARG's authoritative "more results?" signal.
    # Two failure modes the old page-size-based termination had:
    #   1. First page returns exactly $pageSize rows with SkipToken=$null → loop
    #      never breaks (Count == pageSize) and re-runs the same query forever.
    #   2. ARG is allowed to return fewer than -First rows on a page while still
    #      setting SkipToken; breaking on partial pages silently drops results.
    do {
        try {
            if ($skipToken) {
                $pagedResults = Search-AzGraph -Query $Query -First $pageSize -SkipToken $skipToken -UseTenantScope
            } else {
                $pagedResults = Search-AzGraph -Query $Query -First $pageSize -UseTenantScope
            }

            if ($pagedResults -and $pagedResults.Data) {
                $results += $pagedResults.Data
            }
            $skipToken = if ($pagedResults) { $pagedResults.SkipToken } else { $null }
        } catch {
            Write-Warning "Query failed: $_"
            break
        }
    } while ($skipToken)

    return $results
}

# ============================================================================
# QUERY 1: Resource-Based Plans (Main ARG Query)
# Uses the same logic as the original script with mv-expand for multi-bundle resources
# ============================================================================
Write-Host "`n=== Collecting Resource-Based Plan Data ===" -ForegroundColor Cyan

$resourceQuery = @"
(securityresources
    | extend type = tolower(type)
    | where type == 'microsoft.security/assessments'
    | where name == '44d12760-2cf2-4e6d-8613-8451c11c1abc' 
    | extend bundleName = 'virtualmachines'
    | summarize resourcesCount = count() by subscriptionId, bundleName
)
| union 
(resources
    | extend type = tolower(type)
    | where type in ('microsoft.compute/virtualmachines', 'microsoft.classiccompute/virtualmachines', 'microsoft.hybridcompute/machines', 'microsoft.compute/virtualmachinescalesets', 'microsoft.sql/servers', 'microsoft.storage/storageaccounts', 'microsoft.documentdb/databaseaccounts', 'microsoft.keyvault/vaults', 'microsoft.web/serverfarms', 'microsoft.dbforpostgresql/servers', 'microsoft.dbforpostgresql/flexibleservers', 'microsoft.dbformysql/servers', 'microsoft.dbformysql/flexibleservers', 'microsoft.apimanagement/service', 'microsoft.sqlvirtualmachine/sqlvirtualmachines', 'microsoft.azurearcdata/sqlserverinstances', 'microsoft.cognitiveservices/accounts', 'microsoft.web/sites')
    | parse id with '/subscriptions/'subscriptionId'/'rest
    | extend bundleCount = 0, bundleName = pack_array('')
    | extend bundleCount = iff(type in ('microsoft.compute/virtualmachines','microsoft.classiccompute/virtualmachines'), 1 , bundleCount), bundleName = iff(type in ('microsoft.compute/virtualmachines','microsoft.classiccompute/virtualmachines'), pack_array('virtualmachines', 'cloudposture_servers'), bundleName)
    | extend bundleCount = iff(type == 'microsoft.hybridcompute/machines', 1 , bundleCount), bundleName = iff(type == 'microsoft.hybridcompute/machines', pack_array('virtualmachines'), bundleName)
    | extend bundleCount = iff(type == 'microsoft.compute/virtualmachinescalesets' and sku != '' and sku.capacity != '', toint(sku.capacity), bundleCount), bundleName = iff(type =~ 'microsoft.compute/virtualmachinescalesets' and sku != '' and sku.capacity != '', pack_array('virtualmachines', 'cloudposture_servers'), bundleName)
    | extend bundleCount = iff(type == 'microsoft.storage/storageaccounts', 1 , bundleCount), bundleName = iff(type == 'microsoft.storage/storageaccounts', pack_array('storageaccounts', 'cloudposture_storage'), bundleName)
    | extend bundleCount = iff(type == 'microsoft.keyvault/vaults', 1 , bundleCount), bundleName = iff(type == 'microsoft.keyvault/vaults', pack_array('keyvaults'), bundleName)
    | extend bundleCount = iff(type == 'microsoft.web/serverfarms' and isnotempty(sku) and tolower(sku.tier) != 'consumption', toint(properties.numberOfWorkers), bundleCount), bundleName = iff(type == 'microsoft.web/serverfarms' and isnotempty(sku) and tolower(sku.tier) != 'consumption', pack_array('appservices'), bundleName)
    | extend bundleCount = iff((type == 'microsoft.dbforpostgresql/servers' or type == 'microsoft.dbforpostgresql/flexibleservers' or type == 'microsoft.dbformysql/servers' or type == 'microsoft.dbformysql/flexibleservers') and sku.tier !contains('basic'), 1, bundleCount), bundleName = iff((type =~ 'microsoft.dbforpostgresql/servers' or type =~ 'microsoft.dbforpostgresql/flexibleservers' or type =~ 'microsoft.dbformysql/servers' or type =~ 'microsoft.dbformysql/flexibleservers') and sku.tier !contains('basic'), pack_array('opensourcerelationaldatabases', 'cloudposture_databases'), bundleName)
    | extend bundleCount = iff(type == 'microsoft.documentdb/databaseaccounts', 1 , bundleCount), bundleName = iff(type == 'microsoft.documentdb/databaseaccounts', pack_array('cosmosdbs', 'cloudposture_databases'), bundleName)
    | extend bundleCount = iff(type == 'microsoft.apimanagement/service', 1 , bundleCount), bundleName = iff(type == 'microsoft.apimanagement/service', pack_array('api'), bundleName)
    | extend bundleCount = iff(type == 'microsoft.sql/servers', 1 , bundleCount), bundleName = iff(type == 'microsoft.sql/servers', pack_array('sqlservers', 'cloudposture_databases'), bundleName)
    | extend bundleCount = iff(type == 'microsoft.sqlvirtualmachine/sqlvirtualmachines' or type == 'microsoft.azurearcdata/sqlserverinstances', 1 , bundleCount), bundleName = iff(type == 'microsoft.sqlvirtualmachine/sqlvirtualmachines' or type == 'microsoft.azurearcdata/sqlserverinstances', pack_array('sqlservervirtualmachines'), bundleName)
    | extend bundleCount = iff(type == 'microsoft.cognitiveservices/accounts' and kind in ('OpenAI', 'AIServices'), 1 , bundleCount), bundleName = iff(type == 'microsoft.cognitiveservices/accounts' and kind in ('OpenAI', 'AIServices'), pack_array('ai'), bundleName)
    | extend bundleCount = iff(type == 'microsoft.web/sites' and tolower(kind) in ('app', 'functionapp', 'functionapp,linux', 'app,linux', 'app,linux,container', 'functionapp,linux,container', 'app,container,windows', 'linux,container', 'app,migration', 'app,windows', 'functionapp,botapp', 'app,linux,aspiredashboard', 'app,container,xenon', 'app,botapp', 'app,linux,kubernetes', 'app,functionapp,windows', 'functionapp,linux,container,kubernetes', 'app,linux,container,kubernetes', 'app,xenon', 'functionapp,linux,kubernetes', 'app,functionapp'), 1 , bundleCount), bundleName = iff(type == 'microsoft.web/sites' and tolower(kind) in ('app', 'functionapp', 'functionapp,linux', 'app,linux', 'app,linux,container', 'functionapp,linux,container', 'app,container,windows', 'linux,container', 'app,migration', 'app,windows', 'functionapp,botapp', 'app,linux,aspiredashboard', 'app,container,xenon', 'app,botapp', 'app,linux,kubernetes', 'app,functionapp,windows', 'functionapp,linux,container,kubernetes', 'app,linux,container,kubernetes', 'app,xenon', 'functionapp,linux,kubernetes', 'app,functionapp'), pack_array('cloudposture_serverless'), bundleName)
    | mv-expand bundleName to typeof(string) limit 2000
    | summarize resourcesCount = sum(bundleCount) by bundleName, subscriptionId
    | where bundleName != ''
)
| summarize resourcesCount = sum(resourcesCount) by bundleName, subscriptionId
"@

$resourceResults = Invoke-AzGraphQueryPaged -Query $resourceQuery

foreach ($result in $resourceResults) {
    $subId = $result.subscriptionId
    $bundleName = $result.bundleName
    $count = $result.resourcesCount

    if ($subscriptionResults.ContainsKey($subId)) {
        switch ($bundleName) {
            'virtualmachines' { 
                $subscriptionResults[$subId].Servers_All += $count
            }
            'cloudposture_servers' { 
                $subscriptionResults[$subId].DCSPM_Servers += $count
            }
            'storageaccounts' {
                $subscriptionResults[$subId].StorageAccounts += $count
            }
            'cloudposture_storage' { 
                $subscriptionResults[$subId].DCSPM_Storage += $count
            }
            'cloudposture_databases' { 
                $subscriptionResults[$subId].DCSPM_Databases += $count
            }
            'cloudposture_serverless' { 
                $subscriptionResults[$subId].DCSPM_Serverless += $count
            }
            'keyvaults' { 
                $subscriptionResults[$subId].KeyVaults += $count
            }
            'appservices' { 
                $subscriptionResults[$subId].AppServices += $count
            }
            'opensourcerelationaldatabases' { 
                $subscriptionResults[$subId].Databases += $count
            }
            'cosmosdbs' { 
                # CosmosDB resource count (consumption data collected separately)
            }
            'sqlservers' { 
                $subscriptionResults[$subId].Databases += $count
            }
            'sqlservervirtualmachines' { 
                $subscriptionResults[$subId].Databases += $count
            }
            'api' {
                # API resource count (consumption data collected separately)
            }
            'ai' {
                # AI resource count (consumption data collected separately)
            }
        }
        Write-Host "  $($bundleName): $count (Subscription: $subId)"
    }
}

# ============================================================================
# QUERY 2: AKS Excludable VMs - Calculate Servers (excluding AKS nodes)
# Uses extension-based detection (Microsoft.AKS publisher) for accuracy
# ============================================================================
Write-Host "`n=== Calculating Servers (excluding AKS nodes) ===" -ForegroundColor Cyan

$aksExcludableQuery = @"
resources
| where type == 'microsoft.compute/virtualmachinescalesets'
| where isnotempty(sku)
| extend capacity = toint(sku.capacity)
| join kind=inner (
    resources
    | where type == 'microsoft.compute/virtualmachinescalesets/extensions'
    | where properties.publisher =~ 'Microsoft.AKS'
    | parse id with '/subscriptions/' extSubscriptionId '/resourceGroups/' resourceGroup '/providers/Microsoft.Compute/virtualMachineScaleSets/' vmssName '/extensions/' *
    | project extSubscriptionId, vmssName
    | distinct extSubscriptionId, vmssName
) on `$left.subscriptionId == `$right.extSubscriptionId, `$left.name == `$right.vmssName
| summarize serversCount = sum(capacity) by subscriptionId
"@

try {
    $aksResults = Invoke-AzGraphQueryPaged -Query $aksExcludableQuery
    $aksExcludedCount = 0
    $aksProcessedSubs = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($result in $aksResults) {
        $subId = $result.subscriptionId
        if ($subscriptionResults.ContainsKey($subId)) {
            $excludable = $result.serversCount
            $subscriptionResults[$subId].Servers = $subscriptionResults[$subId].Servers_All - $excludable
            $null = $aksProcessedSubs.Add($subId)
            $aksExcludedCount++
            Write-Host "  Servers: $($subscriptionResults[$subId].Servers) (excluding $excludable AKS nodes) (Subscription: $subId)"
        }
    }

    # For subscriptions without AKS results, Servers = Servers_All
    $noAksCount = 0
    foreach ($subId in $subscriptionResults.Keys) {
        if (-not $aksProcessedSubs.Contains($subId) -and $subscriptionResults[$subId].Servers_All -gt 0) {
            $subscriptionResults[$subId].Servers = $subscriptionResults[$subId].Servers_All
            $noAksCount++
        }
    }

    if ($aksExcludedCount -eq 0) {
        Write-Host "  No AKS node pools found to exclude across any subscription." -ForegroundColor Gray
    }
    Write-Host "  Summary: $aksExcludedCount subscriptions had AKS exclusions, $noAksCount subscriptions used total VM count as-is." -ForegroundColor Gray
} catch {
    Write-Error "Failed to retrieve AKS VM scale sets using Azure Resource Graph. Error: $_"
    # If query fails, set Servers = Servers_All for all subscriptions
    foreach ($subId in $subscriptionResults.Keys) {
        $subscriptionResults[$subId].Servers = $subscriptionResults[$subId].Servers_All
    }
}

# ============================================================================
# QUERY 3: Containers Node Count
# ============================================================================
Write-Host "`n=== Collecting Container Node Count ===" -ForegroundColor Cyan

$containersQuery = @"
resources
| where type == 'microsoft.containerservice/managedclusters' and isnotempty(sku) and tolower(sku.tier) != 'consumption'
| where tostring(properties.powerState.code) =~ 'Running'
| mv-expand properties.agentPoolProfiles
| project subscriptionId, nodeCount = toint(properties_agentPoolProfiles['count'])
| summarize totalNodeCount=sum(nodeCount) by subscriptionId
"@

try {
    $containersResults = Invoke-AzGraphQueryPaged -Query $containersQuery

    foreach ($result in $containersResults) {
        $subId = $result.subscriptionId
        if ($subscriptionResults.ContainsKey($subId)) {
            $subscriptionResults[$subId].Containers = $result.totalNodeCount
            Write-Host "  Container Nodes: $($result.totalNodeCount) (Subscription: $subId)"
        }
    }
} catch {
    Write-Error "Failed to retrieve container node count using Azure Resource Graph. Error: $_"
}

# ============================================================================
# OPTIONAL: Extended Data Collection (Containers, API, CosmosDB, Malware Scanning, AI, Container Registry Images)
# ============================================================================
if ($runAdditionalDataCollection -eq "yes" -or $runAdditionalDataCollection -eq "y") {

    # ========================================================================
    # Containers Plan - Enhanced node count using Azure Monitor metrics
    # The ARG query already provides a point-in-time node count.
    # This section uses Azure Monitor metrics to get the 30-day average,
    # which is more accurate for clusters using autoscaling.
    # ========================================================================
    # Total extended collection steps for overall progress.
    # Keep this in sync with the number of $extStepCurrent++ increments below.
    # The 6 steps are:
    #   1. Containers (Metrics-Based node count)
    #   2. API (Apim request units)
    #   3. CosmosDB (RU/s)
    #   4. Malware Scanning (Storage Ingress GB)
    #   5. AI (Tokens)
    #   6. Container Registry Images
    $EXTENDED_COLLECTION_STEP_COUNT = 6
    $extStepTotal = $EXTENDED_COLLECTION_STEP_COUNT
    $extStepCurrent = 0

    Write-Host "`n=== Collecting Container Node Count (Metrics-Based) ===" -ForegroundColor Cyan
    $swContainers = [System.Diagnostics.Stopwatch]::StartNew()
    $extStepCurrent++
    $subIndex = 0
    $subTotal = $subscriptions.Count

    foreach ($sub in $subscriptions) {
        $subIndex++
        Write-Progress -Id 0 -Activity "Extended Data Collection" -Status "Step $extStepCurrent of $extStepTotal : Containers (Metrics)" -PercentComplete (($extStepCurrent / $extStepTotal) * 100)
        Write-Progress -Id 1 -Activity "Containers (Metrics-Based)" -Status "Subscription $subIndex of ${subTotal}: $($sub.Name)" -PercentComplete (($subIndex / $subTotal) * 100)
        Write-Host "Processing Subscription: $($sub.Name) - $($sub.Id) for containers plan"

        $totalNodesForSubscription = 0
        $clustersCount = 0

        try {
            $aksClustersUri = "/subscriptions/$($sub.Id)/providers/Microsoft.ContainerService/managedClusters?api-version=2021-03-01"
            $response = Invoke-AzRestMethod -Method GET -Path $aksClustersUri -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                $responseJson = $response.Content | ConvertFrom-Json
                $aksClusters = if ($responseJson.PSObject.Properties['value']) { $responseJson.value } else { $null }
            } else {
                Write-Warning "Failed to retrieve AKS clusters. Status code: $($response.StatusCode)"
                continue
            }

            if (-not $aksClusters) {
                Write-Host "  No AKS clusters found in Subscription: $($sub.Name)"
                continue
            }
            $clustersCount = ($aksClusters | Measure-Object).Count
        } catch {
            Write-Warning "Failed to retrieve AKS clusters in Subscription: $($sub.Name). Error: $_"
            continue
        }

        $startTime = (Get-Date).AddDays(-30).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $endTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

        foreach ($aks in $aksClusters) {
            $resourceId = $aks.Id
            Write-Host "  AKS Cluster: $($aks.name)"

            try {
                # -ErrorAction Stop turns Get-AzMetric's non-terminating errors (e.g. HTTP 429/529
                # throttling) into terminating ones so the catch block actually fires instead of
                # dumping the full stack trace to the host.
                $metrics = Get-AzMetric -ResourceId $resourceId -MetricName "kube_node_status_condition" -StartTime $startTime -EndTime $endTime -AggregationType Average -TimeGrain 01:00:00 -MetricFilter "status eq 'true' and condition eq 'Ready'" -ErrorAction Stop -WarningAction SilentlyContinue
                if ($metrics -ne $null -and $metrics.Data -ne $null) {
                    $averageNodes = ($metrics.Data | Measure-Object Average -Average).Average
                    Write-Host "    Average ready nodes: $averageNodes"
                    $totalNodesForSubscription += $averageNodes
                } else {
                    Write-Host "    No data available for node count metric."
                }
            } catch {
                Write-Warning "    Error retrieving node count metric: $($_.Exception.Message)"
            }
        }

        Write-Host "  Total nodes for subscription: $totalNodesForSubscription"
        
        # Update with enhanced metric if available
        if ($totalNodesForSubscription -gt 0) {
            $subscriptionResults[$sub.Id].Containers = [math]::Round($totalNodesForSubscription)
        }
    }
    $swContainers.Stop()
    Write-Progress -Id 1 -Activity "Containers (Metrics-Based)" -Completed
    $sectionTimings['Containers (Node Count Metrics)'] = $swContainers.Elapsed
    Write-Host "  >> Containers metrics collection took: $($swContainers.Elapsed.ToString('hh\:mm\:ss\.ff'))" -ForegroundColor Yellow

    # ========================================================================
    # API Plan - Total Requests
    # ========================================================================
    Write-Host "`n=== Collecting API Requests ===" -ForegroundColor Cyan
    $swApi = [System.Diagnostics.Stopwatch]::StartNew()
    $extStepCurrent++
    $subIndex = 0

    foreach ($sub in $subscriptions) {
        $subIndex++
        Write-Progress -Id 0 -Activity "Extended Data Collection" -Status "Step $extStepCurrent of $extStepTotal : API Requests" -PercentComplete (($extStepCurrent / $extStepTotal) * 100)
        Write-Progress -Id 1 -Activity "API Requests" -Status "Subscription $subIndex of ${subTotal}: $($sub.Name)" -PercentComplete (($subIndex / $subTotal) * 100)
        Write-Host "Processing Subscription: $($sub.Name) - $($sub.Id) for API plan"

        try {
            $apimServicesUri = "/subscriptions/$($sub.Id)/providers/Microsoft.ApiManagement/service?api-version=2024-05-01"
            $response = Invoke-AzRestMethod -Method GET -Path $apimServicesUri -ErrorAction Stop
            # On 401/403 the response body is an error envelope, not the resource list;
            # without this guard ($responseJson.value) would yield $null and we'd silently
            # report "no APIM services" instead of a permission failure.
            if ($response.StatusCode -ge 400) {
                Write-Warning "Failed to list APIM services in Subscription: $($sub.Name) (Status: $($response.StatusCode)). Skipping."
                continue
            }
            $responseJson = $response.Content | ConvertFrom-Json
            $apimServices = if ($responseJson.PSObject.Properties['value']) { $responseJson.value } else { $null }

            if (-not $apimServices) {
                Write-Host "  No APIM services found in Subscription: $($sub.Name)"
                continue
            }
        } catch {
            Write-Warning "Failed to retrieve APIM services in Subscription: $($sub.Name). Error: $_"
            continue
        }

        $apimServicesCount = ($apimServices | Measure-Object).Count
        Write-Host "  Number of APIM services: $apimServicesCount"

        $startTime = (Get-Date).AddDays(-30).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $endTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

        $totalRequestsForSubscription = 0

        foreach ($apim in $apimServices) {
            $resourceId = $apim.Id
            Write-Host "  APIM Service: $($apim.name)"
            
            try {
                $metrics = Get-AzMetric -ResourceId $resourceId -MetricName "Requests" -StartTime $startTime -EndTime $endTime -AggregationType Total
                if ($metrics -ne $null -and $metrics.Data -ne $null) {
                    $serviceRequests = ($metrics.Data | Measure-Object Total -Sum).Sum
                    Write-Host "    Total Requests (30 days): $serviceRequests"
                    $totalRequestsForSubscription += $serviceRequests
                } else {
                    Write-Host "    No data available for Requests metric."
                }
            } catch {
                Write-Warning "    Error retrieving Requests metric: $_"
            }
        }

        Write-Host "  Total Requests for subscription: $totalRequestsForSubscription"
        $subscriptionResults[$sub.Id].API_Requests = $totalRequestsForSubscription
    }
    $swApi.Stop()
    Write-Progress -Id 1 -Activity "API Requests" -Completed
    $sectionTimings['API Requests'] = $swApi.Elapsed
    Write-Host "  >> API Requests collection took: $($swApi.Elapsed.ToString('hh\:mm\:ss\.ff'))" -ForegroundColor Yellow

    # ========================================================================
    # CosmosDB Plan - RU/s
    # ========================================================================
    Write-Host "`n=== Collecting CosmosDB RU/s ===" -ForegroundColor Cyan
    $swCosmos = [System.Diagnostics.Stopwatch]::StartNew()
    $extStepCurrent++
    $subIndex = 0

    foreach ($sub in $subscriptions) {
        $subIndex++
        Write-Progress -Id 0 -Activity "Extended Data Collection" -Status "Step $extStepCurrent of $extStepTotal : CosmosDB RU/s" -PercentComplete (($extStepCurrent / $extStepTotal) * 100)
        Write-Progress -Id 1 -Activity "CosmosDB RU/s" -Status "Subscription $subIndex of ${subTotal}: $($sub.Name)" -PercentComplete (($subIndex / $subTotal) * 100)
        Write-Host "Processing Subscription: $($sub.Name) - $($sub.Id) for Cosmos DB plan"

        $totalRUsForSubscription = 0
        $cosmosDBAccountsCount = 0

        try {
            $cosmosDBAccountsUri = "/subscriptions/$($sub.Id)/providers/Microsoft.DocumentDB/databaseAccounts?api-version=2021-04-15"
            $response = Invoke-AzRestMethod -Method GET -Path $cosmosDBAccountsUri -ErrorAction Stop
            # Guard against silent under-counting on 401/403 (see APIM section for rationale).
            if ($response.StatusCode -ge 400) {
                Write-Warning "Failed to list Cosmos DB accounts in Subscription: $($sub.Name) (Status: $($response.StatusCode)). Skipping."
                continue
            }
            $responseJson = $response.Content | ConvertFrom-Json
            $cosmosDBAccounts = if ($responseJson.PSObject.Properties['value']) { $responseJson.value } else { $null }

            if (-not $cosmosDBAccounts) {
                Write-Host "  No Cosmos DB accounts found in Subscription: $($sub.Name)"
                continue
            }
            $cosmosDBAccountsCount = ($cosmosDBAccounts | Measure-Object).Count
        } catch {
            Write-Warning "Failed to retrieve Cosmos DB accounts in Subscription: $($sub.Name). Error: $_"
            continue
        }

        $startTime = (Get-Date).AddDays(-30).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $endTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

        foreach ($cosmosDB in $cosmosDBAccounts) {
            $resourceId = $cosmosDB.Id
            Write-Host "  Cosmos DB Account: $($cosmosDB.name)"

            try {
                $isServerless = $cosmosDB.properties.capabilities | Where-Object { $_.name -eq "EnableServerless" } | ForEach-Object { $true }

                if ($isServerless -eq $true) {
                    # Serverless mode
                    $metrics = Get-AzMetric -ResourceId $resourceId -MetricName "TotalRequestUnits" -StartTime $startTime -EndTime $endTime -AggregationType Total
                    if ($metrics -ne $null -and $metrics.Data -ne $null) {
                        $accountRUs = ($metrics.Data | Measure-Object Total -Sum).Sum
                        # 0.00003125 is Microsoft's documented conversion factor that translates
                        # 30-day serverless RU consumption into the equivalent RU/s figure used
                        # by Defender for Cosmos pricing. See pricing page footnote
                        # "For Azure Cosmos DB Serverless accounts, the total RU is converted
                        # to provisioned throughput using a conversion factor of 0.00003125."
                        $accountRUs = $accountRUs * 0.00003125
                        Write-Host "    Equivalent RU/s (Serverless): $accountRUs"
                        $totalRUsForSubscription += $accountRUs
                    }
                } else {
                    # Cosmos bills the provisioned-throughput meter ("100 RU/s * 1 hour") once per
                    # replica region. The ARM throughputSettings response returns a single per-region
                    # value, and the ProvisionedThroughput metric is not split by Region dimension, so
                    # we accumulate the single-region RU/s here and multiply by the replica count at
                    # the end of the account block to match what Defender billing emits.
                    $provisionedAccountRUs = 0
                    $regionCount = if ($cosmosDB.properties.locations) { @($cosmosDB.properties.locations).Count } else { 1 }

                    $databasesUri = "$resourceId/sqlDatabases?api-version=2021-04-15"
                    $databasesResponse = Invoke-AzRestMethod -Method GET -Path $databasesUri -ErrorAction Stop
                    $databasesJson = $databasesResponse.Content | ConvertFrom-Json
                    $databases = if ($databasesJson.PSObject.Properties['value']) { $databasesJson.value } else { @() }

                    foreach ($database in $databases) {
                        $databaseId = $database.Id
                        try {
                            # Invoke-AzRestMethod -Path expects an ARM path (e.g. /subscriptions/...),
                            # not a full URL — it prepends the ARM endpoint itself. Use -Uri with the
                            # absolute URL so the request hits the right endpoint.
                            $throughputUri = "https://management.azure.com/$databaseId/throughputSettings/default?api-version=2023-03-01-preview"
                            $throughputResponse = Invoke-AzRestMethod -Method GET -Uri $throughputUri -ErrorAction Stop

                            $throughputSettings = $null
                            if ($throughputResponse.StatusCode -eq 200) {
                                $throughputSettings = $throughputResponse.Content | ConvertFrom-Json
                            }

                            if ($throughputSettings -ne $null -and $throughputSettings.properties -ne $null) {
                                if ($throughputSettings.properties.resource -ne $null -and $throughputSettings.properties.resource.PSObject.Properties.Match("autoscaleSettings").Count -gt 0) {
                                    # Autoscale: read the provisioned RU/s capacity directly. The public
                                    # ProvisionedThroughput metric is the same value the Defender billing
                                    # pipeline reads internally as OfferThroughput (Cosmos /offers resource,
                                    # property content.offerThroughput). For autoscale, it equals the RU/s
                                    # the offer was scaled to during that hour (min Tmax/10, max Tmax),
                                    # which is exactly what billing charges per hour. We then average the
                                    # hourly maxes over the period to get an RU/s figure aligned with the
                                    # other branches.
                                    # Docs: https://learn.microsoft.com/en-us/azure/cosmos-db/monitor-reference
                                    $dimFilter = "$(New-AzMetricFilter -Dimension DatabaseName -Operator eq -Value $database.name)"
                                    $metrics = Get-AzMetric -ResourceId $resourceId -MetricName "ProvisionedThroughput" -StartTime $startTime -EndTime $endTime -AggregationType Maximum -MetricFilter $dimFilter -TimeGrain 01:00:00
                                    if ($metrics -ne $null -and $metrics.Data -ne $null) {
                                        $avgHourlyMax = ($metrics.Data | Measure-Object Maximum -Average).Average
                                        Write-Host "    Avg hourly max RU/s (Database autoscale): $avgHourlyMax"
                                        $provisionedAccountRUs += $avgHourlyMax
                                    }
                                } elseif ($throughputSettings.properties.resource -ne $null -and $throughputSettings.properties.resource.throughput -ne $null) {
                                    # Provisioned throughput is already RU/s capacity; emit as-is.
                                    $throughput = $throughputSettings.properties.resource.throughput
                                    Write-Host "    Provisioned RU/s for database: $throughput"
                                    $provisionedAccountRUs += $throughput
                                }
                            } elseif ($throughputResponse.StatusCode -eq 404) {
                                # Iterate over containers if database throughputSettings are not defined
                                $containersUri = "$databaseId/containers?api-version=2021-04-15"
                                $containersResponse = Invoke-AzRestMethod -Method GET -Path $containersUri -ErrorAction Stop
                                $containersJson = $containersResponse.Content | ConvertFrom-Json
                                $containers = if ($containersJson.PSObject.Properties['value']) { $containersJson.value } else { @() }

                                foreach ($container in $containers) {
                                    $containerId = $container.Id
                                    try {
                                        $resourceUri = "$containerId/throughputSettings/default"
                                        $response = Invoke-AzRestMethod -Method GET -Uri "https://management.azure.com$($resourceUri)?api-version=2023-03-01-preview"
                                        if ($response.StatusCode -eq 200) {
                                            $result = $response.Content | ConvertFrom-Json
                                        } elseif ($response.StatusCode -eq 404) {
                                            # 404 is expected for serverless containers (no throughput settings) - skip silently
                                            continue
                                        } else {
                                            Write-Warning "    Failed to retrieve throughput for container: $containerId (Status: $($response.StatusCode))"
                                            continue
                                        }

                                        if ($null -ne $result.properties.resource -and $result.properties.resource.PSObject.Properties.Match("autoscaleSettings").Count -gt 0) {
                                            # Average hourly max RU/s of the provisioned capacity (mirrors
                                            # the internal OfferThroughput metric billing uses). See the
                                            # database-autoscale comment above for details.
                                            $dimFilter = "$(New-AzMetricFilter -Dimension DatabaseName -Operator eq -Value $database.name) and $(New-AzMetricFilter -Dimension CollectionName -Operator eq -Value $container.name)"
                                            $metrics = Get-AzMetric -ResourceId $resourceId -MetricName "ProvisionedThroughput" -StartTime $startTime -EndTime $endTime -AggregationType Maximum -MetricFilter $dimFilter -TimeGrain 01:00:00
                                            if ($metrics -ne $null -and $metrics.Data -ne $null) {
                                                $avgHourlyMax = ($metrics.Data | Measure-Object Maximum -Average).Average
                                                Write-Host "    Avg hourly max RU/s (Container autoscale): $avgHourlyMax"
                                                $provisionedAccountRUs += $avgHourlyMax
                                            }
                                        } elseif ($result.properties.resource -ne $null -and $result.properties.resource.throughput -ne $null) {
                                            $throughput = $result.properties.resource.throughput
                                            Write-Host "    Provisioned RU/s for container: $throughput"
                                            $provisionedAccountRUs += $throughput
                                        }
                                    } catch {
                                        Write-Warning "    Error retrieving throughput for container: $_"
                                    }
                                }
                            }
                        } catch {
                            Write-Warning "    Error retrieving throughput settings for database: $_"
                        }
                    }

                    if ($regionCount -gt 1) {
                        Write-Host "    Multiplying provisioned RU/s by $regionCount replica regions: $provisionedAccountRUs -> $($provisionedAccountRUs * $regionCount)"
                    }
                    $totalRUsForSubscription += $provisionedAccountRUs * $regionCount
                }
            } catch {
                Write-Warning "  Error retrieving metrics for Cosmos DB Account: $_"
            }
        }

        # All branches contribute in RU/s; sum across the subscription with no global divide.
        $totalRUsPerSec = [math]::Round($totalRUsForSubscription)
        Write-Host "  Total RU/s for subscription: $totalRUsPerSec"
        $subscriptionResults[$sub.Id].CosmosDB_RUs = $totalRUsPerSec
    }
    $swCosmos.Stop()
    Write-Progress -Id 1 -Activity "CosmosDB RU/s" -Completed
    $sectionTimings['CosmosDB RU/s'] = $swCosmos.Elapsed
    Write-Host "  >> CosmosDB collection took: $($swCosmos.Elapsed.ToString('hh\:mm\:ss\.ff'))" -ForegroundColor Yellow

    # ========================================================================
    # Malware Scanning - Storage Ingress (GB)
    # ========================================================================
    Write-Host "`n=== Collecting Malware Scanning Data (Storage Ingress) ===" -ForegroundColor Cyan
    $swMalware = [System.Diagnostics.Stopwatch]::StartNew()
    $extStepCurrent++
    $subIndex = 0

    foreach ($sub in $subscriptions) {
        $subIndex++
        Write-Progress -Id 0 -Activity "Extended Data Collection" -Status "Step $extStepCurrent of $extStepTotal : Malware Scanning" -PercentComplete (($extStepCurrent / $extStepTotal) * 100)
        Write-Progress -Id 1 -Activity "Malware Scanning (Ingress)" -Status "Subscription $subIndex of ${subTotal}: $($sub.Name)" -PercentComplete (($subIndex / $subTotal) * 100)
      try {
        Write-Host "Processing Subscription: $($sub.Name) - $($sub.Id) for Malware Scanning"
        $storageAccountsUri = "/subscriptions/$($sub.Id)/providers/Microsoft.Storage/storageAccounts?api-version=2021-04-01"

        $response = Invoke-AzRestMethod -Method GET -Path $storageAccountsUri -ErrorAction Stop

        $responseJson = $response.Content | ConvertFrom-Json
        $StorageAccounts = if ($responseJson.PSObject.Properties['value']) { $responseJson.value } else { $null }

        if (-not $StorageAccounts) {
            Write-Host "  No Storage Accounts found in Subscription: $($sub.Name)"
            continue
        }
     
        $threadSafeDict = [System.Collections.Concurrent.ConcurrentDictionary[string, [Int64]]]::New()

        $storageAccountsCount = ($StorageAccounts | Measure-Object).Count
        Write-Host "  Estimating Ingress metric for $($storageAccountsCount) accounts"

        $now = Get-Date
        $lastMonth = $now.AddMonths(-1)

        $StorageAccounts | ForEach-Object -ThrottleLimit 15 -Parallel {
            Write-Host "  Processing Storage Account: $($_.name)"
            $totalIngressPerSA = 0
            $now = $USING:now
            $lastMonth = $USING:lastMonth
            $dict = $USING:threadSafeDict
            $body = "{
                'requests':[{
                    'httpMethod':'GET',
                    'relativeUrl': '$($_.id)/blobServices/default/providers/microsoft.Insights/metrics?timespan=$($lastMonth.ToString('u'))/$($now.ToString('u'))&interval=FULL&metricnames=Ingress&aggregation=total&metricNamespace=microsoft.storage%2Fstorageaccounts%2Fblobservices&validatedimensions=false&api-version=2019-07-01'
                }]
            }"
            $resp = Invoke-AzRestMethod -Method POST -Path '/batch?api-version=2015-11-01' -Payload $body
            $totalIngressPerSA += (($resp.Content | ConvertFrom-Json).responses.content.value.timeseries.data | Measure-Object -Property 'total' -Sum).Sum
            $null = $dict.TryAdd($_.Id, $totalIngressPerSA)
        }

        $totalIngressPerSA = $threadSafeDict.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        $totalIngressPerSA_GB = $totalIngressPerSA / 1GB

        Write-Host "  Total Ingress: $([math]::Round($totalIngressPerSA_GB, 2)) GB"
        $subscriptionResults[$sub.Id].MalwareScanning_GB = [math]::Round($totalIngressPerSA_GB, 2)
      } catch {
        Write-Warning "Failed to collect Malware Scanning data for Subscription: $($sub.Name). Error: $_"
      }
    }
    $swMalware.Stop()
    Write-Progress -Id 1 -Activity "Malware Scanning (Ingress)" -Completed
    $sectionTimings['Malware Scanning (Ingress)'] = $swMalware.Elapsed
    Write-Host "  >> Malware Scanning collection took: $($swMalware.Elapsed.ToString('hh\:mm\:ss\.ff'))" -ForegroundColor Yellow

    # ========================================================================
    # AI Plan - Token Transactions
    # ========================================================================
    Write-Host "`n=== Collecting AI Token Transactions ===" -ForegroundColor Cyan
    $swAi = [System.Diagnostics.Stopwatch]::StartNew()
    $extStepCurrent++
    $subIndex = 0

    foreach ($sub in $subscriptions) {
        $subIndex++
        Write-Progress -Id 0 -Activity "Extended Data Collection" -Status "Step $extStepCurrent of $extStepTotal : AI Tokens" -PercentComplete (($extStepCurrent / $extStepTotal) * 100)
        Write-Progress -Id 1 -Activity "AI Token Transactions" -Status "Subscription $subIndex of ${subTotal}: $($sub.Name)" -PercentComplete (($subIndex / $subTotal) * 100)
      try {
        Write-Host "Processing Subscription: $($sub.Name) - $($sub.Id) for Defender for AI"
        $openAiUri = "/subscriptions/$($sub.Id)/providers/Microsoft.CognitiveServices/accounts?api-version=2023-05-01"

        $response = Invoke-AzRestMethod -Method GET -Path $openAiUri -ErrorAction Stop
        # Guard against silent under-counting on 401/403 (see APIM section for rationale).
        if ($response.StatusCode -ge 400) {
            Write-Warning "Failed to list Cognitive Services accounts in Subscription: $($sub.Name) (Status: $($response.StatusCode)). Skipping."
            continue
        }

        $openAiResources = ($response.Content | ConvertFrom-Json).value | Where-Object {
            $_.kind -in @("OpenAI", "AIServices")
        }

        if (-not $openAiResources) {
            Write-Host "  No Azure OpenAI resources found in Subscription: $($sub.Name)"
            continue
        }

        $threadSafeDict = [System.Collections.Concurrent.ConcurrentDictionary[string, [Int64]]]::New()

        $openAiResourcesCount = ($openAiResources | Measure-Object).Count
        Write-Host "  Estimating token usage for $($openAiResourcesCount) Azure OpenAI resources"

        $now = Get-Date
        $lastMonth = $now.AddMonths(-1)

        $openAiResources | ForEach-Object -ThrottleLimit 15 -Parallel {
            Write-Host "  Processing OpenAI Resource: $($_.name)"
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

        Write-Host "  Total Tokens: $tokens"
        $subscriptionResults[$sub.Id].AI_Tokens = $tokens
      } catch {
        Write-Warning "Failed to collect AI data for Subscription: $($sub.Name). Error: $_"
      }
    }
    $swAi.Stop()
    Write-Progress -Id 1 -Activity "AI Token Transactions" -Completed
    $sectionTimings['AI Tokens'] = $swAi.Elapsed
    Write-Host "  >> AI Tokens collection took: $($swAi.Elapsed.ToString('hh\:mm\:ss\.ff'))" -ForegroundColor Yellow

    # ========================================================================
    # Container Registry Images - Distinct Digests (requires Azure CLI)
    # ========================================================================
    Write-Host "`n=== Collecting Container Registry Images ===" -ForegroundColor Cyan
    $swImages = [System.Diagnostics.Stopwatch]::StartNew()
    $extStepCurrent++
    Write-Progress -Id 0 -Activity "Extended Data Collection" -Status "Step $extStepCurrent of $extStepTotal : Container Registry Images" -PercentComplete (($extStepCurrent / $extStepTotal) * 100)

    if (($runAcrCollection -eq "yes" -or $runAcrCollection -eq "y") -and $azCliAvailable) {
        # Ensure Azure CLI is logged in with the same account
        try {
            $azAccount = az account show 2>$null | ConvertFrom-Json
            if (-not $azAccount) {
                Write-Host "Logging into Azure CLI..." -ForegroundColor Yellow
                az login --tenant $accountInfo.Tenant.Id 2>$null | Out-Null
            }
        } catch {
            Write-Host "Logging into Azure CLI..." -ForegroundColor Yellow
            az login --tenant $accountInfo.Tenant.Id 2>$null | Out-Null
        }

        # Timing variables
        $acrTotalStartTime = Get-Date
        $acrSubscriptionTimes = @{}
        $acrTotalImages = 0
        $acrSubscriptionsProcessed = 0

        # First, collect all registries from all subscriptions in parallel
        Write-Host "`nPhase 1: Discovering Container Registries across all subscriptions..." -ForegroundColor Cyan
        $allRegistries = [System.Collections.Concurrent.ConcurrentBag[object]]::new()

        $subscriptions | ForEach-Object -ThrottleLimit 10 -Parallel {
            $sub = $_
            $registriesBag = $using:allRegistries
            
            try {
                $acrUri = "/subscriptions/$($sub.Id)/providers/Microsoft.ContainerRegistry/registries?api-version=2023-01-01-preview"
                $response = Invoke-AzRestMethod -Method GET -Path $acrUri -ErrorAction Stop
                $registries = ($response.Content | ConvertFrom-Json).value

                if ($registries) {
                    foreach ($acr in $registries) {
                        $null = $registriesBag.Add(@{
                            SubscriptionId = $sub.Id
                            SubscriptionName = $sub.Name
                            RegistryName = $acr.name
                            LoginServer = $acr.properties.loginServer
                        })
                    }
                }
            } catch {
                Write-Warning "Failed to retrieve Container Registries from Subscription: $($sub.Name). Error: $_"
            }
        }

        $totalRegistries = $allRegistries.Count
        Write-Host "  Found $totalRegistries Container Registries across all subscriptions" -ForegroundColor Green

        # Phase 2: Process registries in parallel to count images
        if ($totalRegistries -gt 0) {
            Write-Host "`nPhase 2: Counting images in registries (parallel processing)..." -ForegroundColor Cyan
            
            $imageResults = [System.Collections.Concurrent.ConcurrentDictionary[string, [System.Collections.Concurrent.ConcurrentBag[object]]]]::new()
            $registryTimes = [System.Collections.Concurrent.ConcurrentDictionary[string, double]]::new()
            $registriesProcessedCounter = [ref]0

            $allRegistries | ForEach-Object -ThrottleLimit 8 -Parallel {
                $registry = $_
                $results = $using:imageResults
                $times = $using:registryTimes
                $processedRef = $using:registriesProcessedCounter
                $total = $using:totalRegistries
                $registryStartTime = Get-Date
                
                $subId = $registry.SubscriptionId
                $acrName = $registry.RegistryName
                
                $current = [System.Threading.Interlocked]::Increment($processedRef)
                Write-Host "  [$current/$total] Processing registry: $acrName ..." -ForegroundColor DarkCyan

                # Ensure subscription bag exists
                $null = $results.TryAdd($subId, [System.Collections.Concurrent.ConcurrentBag[object]]::new())

                try {
                    $repos = az acr repository list --name $acrName --output json 2>$null | ConvertFrom-Json
                    $totalManifests = 0
                    
                    if ($repos) {
                        $repoCount = ($repos | Measure-Object).Count
                        $repoIndex = 0
                        foreach ($repo in $repos) {
                            $repoIndex++
                            if ($repoIndex % 10 -eq 0 -or $repoIndex -eq $repoCount) {
                                Write-Host "    [$current/$total] $acrName - repo $repoIndex of $repoCount" -ForegroundColor DarkGray
                            }
                            $repoInfo = az acr repository show --name $acrName --repository $repo --output json 2>$null | ConvertFrom-Json
                            if ($repoInfo -and $repoInfo.manifestCount) {
                                $totalManifests += $repoInfo.manifestCount
                            }
                        }
                    }
                    
                    $results[$subId].Add(@{
                        RegistryName = $acrName
                        ImageCount = $totalManifests
                    })
                    
                    Write-Host "  [$current/$total] Registry: $acrName - Distinct images: $totalManifests" -ForegroundColor Green
                } catch {
                    Write-Warning "    Error processing Container Registry $acrName. Error: $_"
                    $results[$subId].Add(@{
                        RegistryName = $acrName
                        ImageCount = 0
                        Error = $_.ToString()
                    })
                }
                
                $registryEndTime = Get-Date
                $null = $times.TryAdd("$subId|$acrName", ($registryEndTime - $registryStartTime).TotalSeconds)
            }

            # Aggregate results per subscription
            Write-Host "`n--- Subscription Summary ---" -ForegroundColor Cyan
            foreach ($sub in $subscriptions) {
                if ($imageResults.ContainsKey($sub.Id)) {
                    $subResults = $imageResults[$sub.Id]
                    $subTotalImages = ($subResults | ForEach-Object { $_.ImageCount } | Measure-Object -Sum).Sum
                    
                    # Calculate time for this subscription's registries
                    $subRegistryTimes = $registryTimes.Keys | Where-Object { $_.StartsWith("$($sub.Id)|") } | ForEach-Object { $registryTimes[$_] }
                    $subTotalTime = ($subRegistryTimes | Measure-Object -Sum).Sum
                    
                    if ($subTotalImages -gt 0 -or $subResults.Count -gt 0) {
                        $acrSubscriptionsProcessed++
                        $acrSubscriptionTimes[$sub.Id] = $subTotalTime
                        $subscriptionResults[$sub.Id].ContainerRegistry_Images = $subTotalImages
                        $acrTotalImages += $subTotalImages
                        
                        Write-Host "  $($sub.Name): $subTotalImages images in $($subResults.Count) registries (Time: $([math]::Round($subTotalTime, 2))s)"
                    }
                }
            }
        }

        # Final timing summary
        $acrTotalEndTime = Get-Date
        $acrTotalDuration = ($acrTotalEndTime - $acrTotalStartTime).TotalSeconds
        $acrAvgTimePerSub = if ($acrSubscriptionsProcessed -gt 0) { $acrTotalDuration / $acrSubscriptionsProcessed } else { 0 }

        Write-Host "`n--- Container Registry Images Timing Summary ---" -ForegroundColor Green
        Write-Host "  Total registries scanned: $totalRegistries" -ForegroundColor White
        Write-Host "  Total images counted: $acrTotalImages" -ForegroundColor White
        Write-Host "  Subscriptions with registries: $acrSubscriptionsProcessed" -ForegroundColor White
        Write-Host "  Total scan time: $([math]::Round($acrTotalDuration, 2)) seconds" -ForegroundColor White
        Write-Host "  Average time per subscription: $([math]::Round($acrAvgTimePerSub, 2)) seconds" -ForegroundColor White
    }
    $swImages.Stop()
    $sectionTimings['Container Registry Images'] = $swImages.Elapsed
    Write-Host "  >> Container Registry Images collection took: $($swImages.Elapsed.ToString('hh\:mm\:ss\.ff'))" -ForegroundColor Yellow

    # ========================================================================
    # TIMING SUMMARY
    # ========================================================================
    Write-Progress -Id 1 -Activity "Extended Data Collection" -Completed
    Write-Progress -Id 0 -Activity "Extended Data Collection" -Completed
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "  CONSUMPTION DATA COLLECTION TIMING SUMMARY" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    $totalElapsed = [TimeSpan]::Zero
    foreach ($section in $sectionTimings.Keys) {
        $elapsed = $sectionTimings[$section]
        $totalElapsed += $elapsed
        Write-Host ("  {0,-35} {1}" -f $section, $elapsed.ToString('hh\:mm\:ss\.ff')) -ForegroundColor White
    }
    Write-Host "  ----------------------------------------" -ForegroundColor Magenta
    Write-Host ("  {0,-35} {1}" -f "TOTAL", $totalElapsed.ToString('hh\:mm\:ss\.ff')) -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Magenta
}

# ============================================================================
# EXPORT RESULTS
# ============================================================================
$outputData = $subscriptionResults.Values | ForEach-Object { [PSCustomObject]$_ }
$outputPath = "AzureRawBillableData_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$outputData | Export-Csv -Path $outputPath -NoTypeInformation -Force

Write-Host "`nResults exported to: $outputPath" -ForegroundColor Green
