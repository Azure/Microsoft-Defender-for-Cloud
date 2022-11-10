<#
.SYNOPSIS
Dismiss all alerts for subscription, based on filter (default is to dismiss all)

.PARAMETER SubscriptionId
Subscription Id

Example usage:
dismissAllAlerts.ps1 -SubscriptionId 4D4F988C-D81F-4BF6-862D-5DB94A067DB5
#>

Param(
  [Parameter(Mandatory)] [string]
  $SubscriptionId
)

$updatedToken = $null;
$pageNumber = 0

function Main() {
  Login-AzAccount
  Set-AzContext -SubscriptionId $SubscriptionId 
  
  $url = "https://management.azure.com/subscriptions/$($SubscriptionId)/providers/Microsoft.Security/alerts/?api-version=2021-01-01"

  while ($url)
  {
    $pageNumber++
    Write-Host (Get-Date).ToString() "Page Number:" $pageNumber
    Write-Host (Get-Date).ToString() "  " $url

    $headers = Get-Headers
    $results = Invoke-RestMethod -Method "Get" -Uri $url -Headers $headers
	
    foreach ($alert in $results.value) {
	  Dismiss-Alert $alert
    }
	
    $url = $results.nextLink
  }
}

function Get-Headers() {
  
  if ($null -eq $updatedToken)
  {
	$updatedToken = Get-AzAccessToken  
  }
  
  $tokenExpiry = $updatedToken.ExpiresOn.ToUnixTimeMilliseconds()
  $currentTime = [int][double]::Parse((Get-Date -UFormat %s))
  
  if ($currentTime > $tokenExpiry)
  {
	$updatedToken = Get-AzAccessToken  
  }
  
  return @{
    Authorization="Bearer $($updatedToken.Token)"
  }
}

function Dismiss-Alert($alert) {
  if (Should-BeDismissed($alert))
  {
    $dismissUrl = "https://management.azure.com/$($alert.id)/dismiss?api-version=2021-01-01"
    Write-Host (Get-Date).ToString() "  " $dismissUrl
    $headers = Get-Headers
    $retryCount = 0
    $success = $false
    while (($success -ne $true)){
      try {
        Invoke-RestMethod -Method "Post" -Uri $dismissUrl -Headers $headers
        $success = $true
      }  
      catch [System.Net.WebException]{
        $StatusCode = [int]$PSItem.Exception.Response.StatusCode
        if ($StatusCode -eq 429) {
          Write-Host "Request was throttled"
          try{
            $RetryAfter = [int]$PSItem.Exception.Response.Headers["Retry-After"]
          }
          catch {
            $RetryAfter = 360
          }

          if($retryCount -gt 5){
            Write-Host "max retry reached, throwing exception"
            throw
          }
          Write-Host "Sleep for $($RetryAfter) Seconds then retry"
          Start-Sleep -Seconds $RetryAfter
          $retryCount++
        }
        else{
          throw
        }   
      }
    }
   

 

  }
}
function Should-BeDismissed($alert) {
	return $alert.properties.status -ne "Dismissed"
}

try {
  Main
}
catch {
  Write-Host "`n"
  Write-Warning $("============ EXCEPTION DETAILS ====================`n" +
    "Exception Type: $($PSItem.Exception.GetType().FullName)`n" +
    "Message: $($PSItem.Exception.Message)`n" +
    "Script Stack Trace:`n" + 
    $PSItem.ScriptStackTrace + 
    "`n============================================================")

  throw
}

