<#
.NOTES
    Author:     Lior Arviv, MSFT
    Version:    1.0.0
    Created:    14/01/2021
#>

#Requires -Modules Az.Accounts, Az.ResourceGraph

if (-not (Get-AzContext)) {
  Write-Host "Please authenticate to Azure using 'Connect-AzAccount'"
}

# Query  unhelhty resources across all subscriptions for assessmentkey 805651bc-6ecd-4c73-9b55-97a19d0582d0
$query = @"
securityresources
| where type == 'microsoft.security/assessments' and name == '805651bc-6ecd-4c73-9b55-97a19d0582d0'
| extend status = properties.status.code, resourceid = properties.resourceDetails.Id
| where status == 'Unhealthy'
| project resourceid
"@

# Set variables for each unhealthy resource
$vmids = Search-AzGraph -Query $query
foreach ($vmid in $vmids) {
  $sub = ($vmid.resourceid -Split "/")[2]
  $vm = ($vmid.resourceid -Split "/")[8]
  $vmrg = ($vmid.resourceid -Split "/")[4]
  $vmlocation = (Invoke-AzRestMethod -Path ('{0}/?api-version=2020-06-01' -f $vmid.resourceid) -Method GET | Select-Object -ExpandProperty Content | ConvertFrom-Json).Location

  # Build JIT Policy
  $jitpolicy = @{
    kind       = "Basic"
    properties = @{
      virtualMachines = @(
        @{id    = $vmid.resourceid
          ports = (
            @{number = 22; protocol = "*"; allowedSourceAddressPrefix = "*"; maxRequestAccessDuration = "PT3H" },
            @{number = 3389; protocol = "*"; allowedSourceAddressPrefix = "*"; maxRequestAccessDuration = "PT3H" }
          )
        })
    }
  } | ConvertTo-Json -Depth 5

  Write-Host "Applying Just-in-time VM access configuration on: $vm" -ForegroundColor Green
  # Create JIT policy
  Invoke-AzRestMethod -Path "/subscriptions/${sub}/resourceGroups/${vmrg}/providers/Microsoft.Security/locations/${vmlocation}/jitNetworkAccessPolicies/${vm}?api-version=2015-06-01-preview" -Method PUT -Payload $jitpolicy
}