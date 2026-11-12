param(
    [string]$ScriptPath = (Join-Path $PSScriptRoot '../Add-AMASecurityEventDCR.ps1')
)

$ErrorActionPreference = 'Stop'
$subscription = '00000000-0000-0000-0000-000000000000'
$workspace = "/subscriptions/$subscription/resourceGroups/offline/providers/Microsoft.OperationalInsights/workspaces/offline"

# Stub every Az command in the script, including the unused sign-in branches.
function Get-AzContext { [pscustomobject]@{ Subscription = $subscription } }
function Get-AzSubscription { [pscustomobject]@{ Id = $subscription } }
function Connect-AzAccount { throw 'Unexpected sign-in attempt.' }
function Disconnect-AzAccount { throw 'Unexpected sign-out attempt.' }
function Invoke-AzRestMethod {
    param($Method, $Uri, $Payload)
    $global:offlineDcrCalls.Add($Method)
    switch ($Method) {
        'GET' { @{ StatusCode = 200; Content = '{"properties":{"customerId":"offline-workspace"}}' } }
        'PUT' {
            $global:offlineDcrPayload = $Payload
            @{ StatusCode = 201; Content = '{}' }
        }
        default { throw "Unexpected method: $Method" }
    }
}

$quoted = 'Security!*[System[Provider[@Name="Microsoft-Windows-Security-Auditing"]]]'
$backslash = "Security!*[EventData[Data[@Name='ObjectName']='C:\Windows\System32']]"
$plain = 'Security!*[System[(EventID=4624)]]'
$failures = 0
foreach ($case in @(
    @{ Name = 'quoted provider'; Filter = 'Custom'; Queries = @($quoted) },
    @{ Name = 'backslash path'; Filter = 'Custom'; Queries = @($backslash) },
    @{ Name = 'multiple escaped queries'; Filter = 'Custom'; Queries = @($quoted, $backslash, $plain) },
    @{ Name = 'single plain query'; Filter = 'Custom'; Queries = @($plain) },
    @{ Name = 'multiple plain queries'; Filter = 'Custom'; Queries = @($plain, 'Security!*') },
    @{ Name = 'AllEvents'; Filter = 'AllEvents'; Count = 3 },
    @{ Name = 'Common'; Filter = 'Common'; Count = 12 },
    @{ Name = 'Minimal'; Filter = 'Minimal'; Count = 5 },
    @{ Name = 'default'; Count = 3 }
)) {
    $global:offlineDcrPayload = $null
    $global:offlineDcrCalls = [System.Collections.Generic.List[string]]::new()
    try {
        $parameters = @{
            DcrName = 'offline'; ResourceGroup = 'offline'; SubscriptionId = $subscription
            Region = 'eastus'; LogAnalyticsWorkspaceARMId = $workspace
        }
        if ($case.Filter) { $parameters.EventFilter = $case.Filter }
        if ($case.Queries) { $parameters.CustomEventFilter = $case.Queries }
        & $ScriptPath @parameters | Out-Null
        if (($global:offlineDcrCalls -join ',') -ne 'GET,PUT') { throw 'Expected one GET and one PUT.' }
        $body = $global:offlineDcrPayload | ConvertFrom-Json
        $queries = $body.properties.dataSources.windowsEventLogs[0].xPathQueries
        if ($queries -isnot [array]) { throw 'xPathQueries must remain a JSON array.' }
        if ($case.Queries) {
            if ($queries.Count -ne $case.Queries.Count) { throw 'Query count changed.' }
            for ($i = 0; $i -lt $queries.Count; $i++) {
                if ($queries[$i] -cne $case.Queries[$i]) { throw "Query $i changed during serialization." }
            }
        } else {
            if ($queries.Count -ne $case.Count) { throw 'Preset query count changed.' }
            if ($case.Count -eq 3 -and ($queries -join '|') -cne 'Security!*|Microsoft-Windows-AppLocker/EXE and DLL!*|Microsoft-Windows-AppLocker/MSI and Script!*') {
                throw 'AllEvents queries changed.'
            }
            if ($case.Count -ne 3 -and $queries[-1] -cne 'Microsoft-Windows-AppLocker/MSI and Script!*[System[(EventID=8005) or (EventID=8006) or (EventID=8007)]]') {
                throw 'Preset AppLocker query changed.'
            }
        }
        $destination = $body.properties.destinations.logAnalytics[0]
        if ($destination.workspaceResourceId -cne $workspace -or $destination.workspaceId -cne 'offline-workspace' -or $body.location -cne 'eastus') {
            throw 'DCR destination or region changed.'
        }
        Write-Host "PASS: $($case.Name)"
    } catch {
        $failures++
        Write-Host "FAIL: $($case.Name); $($_.Exception.Message)"
    }
}
if ($failures) { throw "$failures DCR regression case(s) failed." }
