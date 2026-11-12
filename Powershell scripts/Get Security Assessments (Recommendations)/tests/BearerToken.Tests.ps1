param(
  [string]$ScriptDirectory = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
. (Join-Path $ScriptDirectory 'Get-SecAssessment.ps1')
. (Join-Path $ScriptDirectory 'Get-SecSubAssessment.ps1')

# Both files only define functions. All external operations are stubbed here.
function Get-AzAccessToken {
  [CmdletBinding()]
  param()
  [pscustomobject]@{ Token = $script:tokenValue }
}
function Search-AzGraph {
  param($Query, $Subscription)
  [pscustomobject]@{ id = '/offline/resource' }
}
function Invoke-RestMethod {
  param([Alias('Header')]$Headers, $Method, $Uri)
  $script:calls++
  if ($Headers.Authorization -cne "Bearer $script:expectedToken") {
    $script:badHeader = $Headers.Authorization
  }
  if ($Method -ne 'GET') { throw 'Expected a GET request.' }
  $item = [pscustomobject]@{
    properties = [pscustomobject]@{
      status = [pscustomobject]@{ code = 'Unhealthy' }
      additionalData = [pscustomobject]@{ subAssessmentsLink = '/offline/subAssessments' }
    }
  }
  if ($Uri -like '*/subAssessments?*') {
    [pscustomobject]@{ value = @($item) }
  } else { $item }
}

$script:expectedToken = 'eyJhbGciOiJub25lIn0.eyJzdWIiOiJvZmZsaW5lIn0.offline'
$failures = 0
foreach ($kind in @('SecureString', 'String')) {
  $script:tokenValue = if ($kind -eq 'SecureString') {
    ConvertTo-SecureString $script:expectedToken -AsPlainText -Force
  } else { $script:expectedToken }
  foreach ($helper in @('assessment', 'subassessment', 'assessment with subassessment')) {
    $script:calls = 0
    $script:badHeader = $null
    try {
      $result = @(switch ($helper) {
        'assessment' {
          Get-SecAssessment -AssessmentId ([guid]::Empty) -ResourceId '/offline/resource'
        }
        'subassessment' { Get-SecSubAssessment -SubAssessmentLink '/offline/subAssessments' }
        'assessment with subassessment' {
          Get-SecAssessment -AssessmentId ([guid]::Empty) -ResourceId '/offline/resource' -SubAssessment
        }
      })
      $expectedCalls = if ($helper -eq 'assessment with subassessment') { 2 } else { 1 }
      if ($script:badHeader) { throw "Incorrect bearer header: $script:badHeader" }
      if ($script:calls -ne $expectedCalls -or $result.Count -ne 1) {
        throw "Expected $expectedCalls request(s) and one result; got $script:calls request(s), $($result.Count) result(s)."
      }
      Write-Host "PASS: $kind $helper"
    } catch {
      $failures++
      Write-Host "FAIL: $kind $helper; $($_.Exception.Message)"
    }
  }
}
if ($failures) { throw "$failures bearer-token regression case(s) failed." }
