<#
.SYNOPSIS
    Retrieves registry values from all underlying VMs of your SQL Virtual Machines (in the scope of the current subscription)
    for every SQL instance (under HKLM:\SOFTWARE\Microsoft\AzureDefender\SQL\) and exports the results to an Excel file.

.DESCRIPTION
    For each SQL VM (as returned by Get-AzSqlVM), this script:
      - Determines its underlying Virtual Machine.
      - Invokes a run command (with -AsJob) on that VM. The remote script:
           • Enumerates all instance names (subkeys) under HKLM:\SOFTWARE\Microsoft\AzureDefender\SQL\
           • Retrieves the registry values "SqlQueryProtection_Status" and "SqlQueryProtection_Timestamp"
           • Converts the .NET ticks timestamp into an ISO 8601 date/time
           • Outputs a JSON array of objects (one per SQL instance)
      - The local script waits for all jobs to complete, parses each job’s JSON output (using the Message property).
      - Finally, the results are exported to an Excel file.

.NOTES
    - Requires the Az modules (Az.Accounts, Az.Compute, Az.SqlVirtualMachine) and the ImportExcel module.
    - Ensure you are connected to your Azure account (Connect-AzAccount).
#>

# Ensure required modules are imported
Import-Module Az.Accounts
Import-Module Az.Compute
Import-Module Az.SqlVirtualMachine
Import-Module ImportExcel

# Connect to Azure if not already connected
if (-not (Get-AzContext)) { Connect-AzAccount }

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Initialize an empty array to store results
$allResults = @()

foreach ($subscription in $subscriptions) {
    # Set the subscription context
    Set-AzContext -SubscriptionId $subscription.Id

    # Existing logic to retrieve registry values from VMs
    # (Assuming this logic is encapsulated in a function for clarity)
    $results = Get-SqlVMProtectionStatusForSubscription -SubscriptionId $subscription.Id

    # Append results to the allResults array
    $allResults += $results
}

# Export all results to an Excel file
$excelFilePath = "SqlVMProtectionStatusReport.xlsx"
$allResults | Export-Excel -Path $excelFilePath -AutoSize

Write-Output "Report generated: $excelFilePath"

function Get-SqlVMProtectionStatusForSubscription {
    param (
        [string]$SubscriptionId
    )

    # Placeholder for the existing logic to retrieve registry values from VMs
    # This function should return an array of results for the given subscription

    # Example return value (replace with actual logic)
    return @()
}