param(
    [string]$ScriptPath = (Join-Path $PSScriptRoot '../EnableDefenderForSqlOnMachines.ps1')
)

$ErrorActionPreference = 'Stop'
$source = Get-Content -Raw $ScriptPath
$match = [regex]::Match($source, '(?s)# Create and run remediation step.*?(?=    # Register SQL VMs)')
if (-not $match.Success) { throw 'Could not find the remediation block.' }
$remediationBlock = [scriptblock]::Create($match.Value)

# Only the remediation block runs. Its sole external command is provided to
# parallel runspaces by this temporary module; no Az modules are loaded.
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
$moduleDir = New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'OfflineRemediation')
@'
function Start-AzPolicyRemediation {
    [CmdletBinding()]
    param($PolicyAssignmentId, $Name, $Scope, $ResourceDiscoveryMode, $PolicyDefinitionReferenceId)
    if ($PolicyDefinitionReferenceId -like 'error-*') {
        Write-Error "offline failure for $PolicyDefinitionReferenceId"
        return
    }
    if ($PolicyDefinitionReferenceId -like 'fail-*') {
        throw "offline failure for $PolicyDefinitionReferenceId"
    }
    [pscustomobject]@{ Name = $Name }
}
Export-ModuleMember -Function Start-AzPolicyRemediation
'@ | Set-Content (Join-Path $moduleDir 'OfflineRemediation.psm1')
$originalModulePath = $env:PSModulePath
$originalDefaults = $PSDefaultParameterValues
$failures = 0
try {
    $env:PSModulePath = $fixtureRoot + [IO.Path]::PathSeparator + (Join-Path $PSHOME 'Modules')
    $PSDefaultParameterValues = @{ 'ForEach-Object:ThrottleLimit' = 2 }
    foreach ($case in @(
        @{ Name = 'all succeed'; Ids = @('ok-first', 'ok-last'); FailIds = @() },
        @{ Name = 'one fails'; Ids = @('ok-first', 'fail-one', 'ok-last'); FailIds = @('fail-one') },
        @{ Name = 'all fail'; Ids = @('fail-one', 'fail-two'); FailIds = @('fail-one', 'fail-two') },
        @{ Name = 'nonterminating error'; Ids = @('ok-first', 'error-one'); FailIds = @('error-one') }
    )) {
        $policyDefinitionReferenceIds = $case.Ids
        $policyAssignment = @{ PolicyAssignmentId = '/offline/assignment' }
        $policyAssignmentName = 'offline assignment'
        $SubscriptionId = 'offline-subscription'
        $caught = $null
        $records = @(& {
            try { & $remediationBlock } catch { $script:caught = $_.Exception.Message }
        } *>&1)
        $text = $records | Out-String
        $reportedSuccess = $text -match 'Remediation steps created.*successfully'
        $ok = if ($case.FailIds.Count -eq 0) {
            $reportedSuccess -and -not $caught
        } else {
            (-not $reportedSuccess) -and $caught
        }
        foreach ($id in $case.FailIds) {
            $ok = $ok -and $caught -like "*offline failure for $id*"
        }
        $created = @($records | Where-Object { $_.Name -like 'Remediation-ok-*' }).Count
        $ok = $ok -and $created -eq ($case.Ids.Count - $case.FailIds.Count)
        if ($ok) {
            Write-Host "PASS: $($case.Name)"
        } else {
            $failures++
            Write-Host "FAIL: $($case.Name); success message=$reportedSuccess; caught=$caught"
        }
    }
} finally {
    $env:PSModulePath = $originalModulePath
    $PSDefaultParameterValues = $originalDefaults
    Remove-Item -Recurse -Force $fixtureRoot
}
if ($failures) { throw "$failures remediation regression case(s) failed." }
