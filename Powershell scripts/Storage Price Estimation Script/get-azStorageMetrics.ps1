<#
    .DESCRIPTION
        The script will get estimated ingress metrics on Azure Files and Azure Blob files for supported V2 Storage Accounts with file containers across 
        all subscriptions in a tenant based on the ingress metric, which is in bytes. 
        - The ingress metric used in this script is based on the last 30 days at a 5 minute interval
        - Overall this estimate is a ballpark and not to be expected as 100% accurate measure of file size on upload
        - The script will output the totals and export the data to a csv file

    .PARAMETER all
        Get estimates for all storage accounts in the Tenant

    .PARAMETER managementGroupName
        An optional name of a managment group to scope the script to.

    .PARAMETER subscriptionId
        An optional string array of Subscritpion Ids to scope the script to.

    .PARAMETER resourceGroupName
        An optional resource group name to get all storage accounts in a resource group.

    .PARAMETER storageAccountName
        An optional storage account name to get estimates for a single storage account.

    .EXAMPLE
        Get estimates for all storage accounts in the Tenant
        .\get-azStorageMetrics.ps1 -all
    
    .EXAMPLE
        Get estimates for all storage accounts in a management group you specify
        .\get-azStorageMetrics.ps1 -managementGroupName "Finance" 

    .EXAMPLE
        Get estimates for all storage accounts in Subscriptions you specify
        # Single Subscription
        .\get-azStorageMetrics.ps1 -subscriptionId '98aaxxab-0ef8-48e2-8397-a0101e0712e3'
        # Multiple Subscriptions
        .\get-azStorageMetrics.ps1 -subscriptionId '98aaxxab-0ef8-48e2-8397-a0101e0712e3,adaxxe68-375e-4210-be3a-c6cacebf41c5'

    .EXAMPLE
        Get estimates for all storage accounts in a resource group you specify
        .\get-azStorageMetrics.ps1 -resourceGroupName "production accounts" -subscriptionId 'adaxxe68-375e-4210-be3a-c6cacebf41c5'

    .EXAMPLE
        Get estimates for a single storage account
        .\get-azStorageMetrics.ps1 -storageAccountName "customeruploads" -resourceGroupName 'production accounts' -subscriptionId 'adaxxe68-375e-4210-be3a-c6cacebf41c5'
#>
param(
    [CmdletBinding(DefaultParameterSetName="all")]
    [Parameter(Mandatory=$true, ParameterSetName = 'all')]
    [switch]$all,

    [Parameter(Mandatory=$true, ParameterSetName = 'mgscope')]
    [string]$managementGroupName,

    [Parameter(Mandatory=$true, ParameterSetName = 'resourcegroupscope')]
    [Parameter(Mandatory=$true, ParameterSetName = 'storageAccountScope')]
    [Parameter(Mandatory=$true, ParameterSetName = 'subscope')]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true, ParameterSetName = 'resourcegroupscope')]
    [Parameter(Mandatory=$true, ParameterSetName = 'storageAccountScope')]
    [string]$resourceGroupName,
    
    [Parameter(Mandatory=$true, ParameterSetName = 'storageAccountScope')]
    [string]$storageAccountName
)

# List Prices and Caculations
$defenderForStoragePerAccountPrice = 10
$overageTransactionsPrice  = 0.1492
$overageTransactionLimit = 73000000
$malwareScanningPerGBPrice = .15

$requiredModules = 'Az.Accounts', 'Az.Storage', 'Az.Monitor'
$availableModules = Get-Module -ListAvailable -Name $requiredModules
$modulesToInstall = $requiredModules | where-object {$_ -notin $availableModules.Name}
ForEach ($module in $modulesToInstall){
    Write-Host "Installing Missing PowerShell Module: $module" -ForegroundColor Yellow
    Install-Module $module -force
}

# Load Latest Version 
ForEach ($module in $requiredModules){
    Remove-Module $module -Force -Confirm:$false -ErrorAction SilentlyContinue
    (Get-Module -Name $module -ListAvailable | Sort-Object -Property Version)[-1] | Import-Module
}

# Connect to Azure if not already connected
If(!(Get-AzContext)){
    Write-Host 'Connecting to Azure' -ForegroundColor Yellow
    Connect-AzAccount -WarningAction SilentlyContinue | Out-Null
}

function Get-StorageAccounts {
    param (
        $subscriptions
    )
    $storageAccounts = @()
    ForEach ($subscription in $subscriptions){
        $subStorageAccounts = $null
        Write-Host ('Getting All Storage Accounts in the {0} Subscription' -f $subscription.Name) -ForegroundColor Yellow
        Set-AzContext -SubscriptionId $subscription.id | Out-Null
        $subStorageAccounts = Get-AzStorageAccount | Where Kind -like 'StorageV2'
        ForEach ($storageAccount in $subStorageAccounts){
            $storageAccount | Add-Member -MemberType NoteProperty -Name 'Subscription' -Value $subscription.Name -Force -ErrorAction SilentlyContinue
            $storageAccount | Add-Member -MemberType NoteProperty -Name 'SubscriptionId' -Value $subscription.Id -Force -ErrorAction SilentlyContinue
            $storageAccount | Add-Member -MemberType NoteProperty -Name 'SubscriptionTenantId' -Value $subscription.TenantId -Force -ErrorAction SilentlyContinue
        }
        $storageAccounts += $subStorageAccounts
    }
    $storageAccounts
}

# Get storage accounts based on parameters
If ($PSCmdlet.ParameterSetName -like 'all') {
    Write-Host "Scope: $($PSCmdlet.ParameterSetName)"
    $subscriptions = Get-AzSubscription | where State -like 'Enabled' -WarningAction SilentlyContinue
    $storageAccounts = Get-StorageAccounts -subscriptions $subscriptions
}
If ($PSCmdlet.ParameterSetName -like 'mgscope'){
    Write-Host "Scope: $($PSCmdlet.ParameterSetName)"
    $mg = Get-AzManagementGroup -GroupName $managementGroupName -Recurse -Expand -WarningAction SilentlyContinue
    # Get All Subscriptions in the parent management group supplied
    $mgSubs = @()
    $mgSubs += Get-AzManagementGroupSubscription -GroupName $managementGroupName -WarningAction SilentlyContinue
    # Get all Subscriptions in all child management groups
    If ($mg.Children){
        $childMg = $true
        $childrenMgs = $mg.children | where Type -eq 'Microsoft.Management/managementGroups'
        while($childMg) {
            $childMg = $false
            ForEach ($childrenMg in $childrenMgs){
                If ($childrenMg.Children){
                    $childMg = $true
                    $childrenMgs = $childrenMg.Children | where Type -eq 'Microsoft.Management/managementGroups'
                }
                $mgSubs += Get-AzManagementGroupSubscription -GroupName $childrenMg.Name -WarningAction SilentlyContinue
            }
        }
    }
    $subscriptions = @()
    $mgSubs | % {$subscriptions += Get-AzSubscription -SubscriptionId $_.Id.split('/')[-1] -WarningAction SilentlyContinue}
    $storageAccounts = Get-StorageAccounts -subscriptions $subscriptions
}
If ($PSCmdlet.ParameterSetName -like 'subscope'){
        Write-Host "Scope: $($PSCmdlet.ParameterSetName)"
        If ($subscriptionId -match ','){
            $subscriptions += $subscriptionId.split(',').trim() | % {Get-AzSubscription -SubscriptionId $_ -WarningAction SilentlyContinue}
        }else{
            $subscriptions += $subscriptionId | % {Get-AzSubscription -SubscriptionId $_ -WarningAction SilentlyContinue}
        }
        $storageAccounts = Get-StorageAccounts -subscriptions $subscriptions
}
If ($PSCmdlet.ParameterSetName -like 'resourcegroupscope'){
    Write-Host "Scope: $($PSCmdlet.ParameterSetName)"
    $subscriptions = Get-AzSubscription -SubscriptionId $subscriptionId
    $storageAccounts = Get-StorageAccounts -subscriptions $subscriptions | where ResourceGroupName -Like $resourceGroupName

}
If ($PSCmdlet.ParameterSetName -like 'storageAccountScope') {
    Write-Host "Scope: $($PSCmdlet.ParameterSetName)"
    $subscriptions = Get-AzSubscription -SubscriptionId $subscriptionId
    $storageAccounts = Get-StorageAccounts -subscriptions $subscriptions | Where-Object {$_.ResourceGroupName -Like $resourceGroupName -and $_.StorageAccountName -like $storageAccountName}
}

$report = @()
# Blob Specific metrics to determine accurate put operations of content
$blobMetricFilter = (New-AzMetricFilter -Dimension 'ApiName' -Operator eq -Value 'PutBlob','CopyBlob','PutBlock','PutBlockFromURL','AppendFile','FlushFile','CreatePathFile'  -WarningAction SilentlyContinue)

# Get the related metrics for each Storage Account
Write-Host ('Found a total of {0} storage Accounts' -f $storageAccounts.Count) -ForegroundColor Yellow
ForEach ($storageAccount in $storageAccounts){
    If((Get-AzContext).Subscription.Id -notlike $storageAccount.SubscriptionId){
        Set-AzContext -subscriptionId $storageAccount.SubscriptionId | Out-Null
    }
    $totalBlobIngress30dayBytes = $null
    $totalBlobIngress30dayMB = $null
    $totalBlobIngress30dayGB = $null
    $blobIngress = $null
    $totalBlobIngress = 0
    $blobTransactions = $null
    $totalBlobTransactions = 0
    $fileTransactions = $null
    $totalFileTransactions = 0
    $totalTransactions30day = $null
    $transactionOverageCost = 0
    $totalTransactionsOverages30day = 0
  
    Write-Host ('Getting metrics for storage account: {0} in Resource Group: {1} Subscription: {2} in Tenant: {3}' -f $storageAccount.StorageAccountName, $storageAccount.ResourceGroupName, $storageAccount.Subscription, $storageAccount.SubscriptionTenantId) -ForegroundColor Yellow

    # Get blob ingress in bytes over the past 30 days
    $blobIngress = Get-AzMetric -ResourceId $($storageAccount.id + "/blobservices/default") -MetricName Ingress -MetricFilter $blobMetricFilter -AggregationType Total -StartTime $((Get-Date).AddMonths(-1)) -EndTime $(Get-Date) -WarningAction SilentlyContinue
    # Get Transactions over the past 30 days
    $fileTransactions = Get-AzMetric -ResourceId $($storageAccount.id + "/fileservices/default") -MetricName Transactions -AggregationType Total -StartTime $((Get-Date).AddMonths(-1)) -EndTime $(Get-Date) -WarningAction SilentlyContinue
    $blobTransactions = Get-AzMetric -ResourceId $($storageAccount.id + "/blobservices/default") -MetricName Transactions -AggregationType Total -StartTime $((Get-Date).AddMonths(-1)) -EndTime $(Get-Date) -WarningAction SilentlyContinue
    
    # Get Totals on transactions and blob ingress
    $blobIngress.Data.Total | % {$totalBlobIngress += $_}
    $fileTransactions.Data.Total | % {$totalFileTransactions += $_}
    $blobTransactions.Data.Total | % {$totalBlobTransactions += $_}
    $totalTransactions30day = $totalFileTransactions + $totalBlobTransactions
    $totalBlobIngress30dayBytes = $totalBlobIngress
    $totalBlobIngress30dayMB = [math]::round([decimal]$totalBlobIngress/1000/1000,6)
    $totalBlobIngress30dayGB = [math]::round([decimal]$totalBlobIngress/1000/1000/1000,6)

    # Calculate any overage costs for transactions
    If ($totalTransactions30day -gt $overageTransactionLimit){
        $totalTransactionsOverages30day = $totalTransactions30day - $transactionOverageLimit
        $transactionOverageCost = ($totalTransactionsOverages30day / 1000000) * $overageTransactionsPrice
    }
    $storageAccount | Add-Member -MemberType NoteProperty -Name 'totalTransactions30day' -Value $totalTransactions30day -Force -ErrorAction SilentlyContinue
    $storageAccount | Add-Member -MemberType NoteProperty -Name 'totalTransactionsOverages30day' -Value $totalTransactionsOverages30day -Force -ErrorAction SilentlyContinue
    $storageAccount | Add-Member -MemberType NoteProperty -Name 'totalBlobIngress30dayBytes' -Value $totalBlobIngress30dayBytes -Force -ErrorAction SilentlyContinue
    $storageAccount | Add-Member -MemberType NoteProperty -Name 'totalBlobIngress30dayMB' -Value $totalBlobIngress30dayMB -Force -ErrorAction SilentlyContinue
    $storageAccount | Add-Member -MemberType NoteProperty -Name 'totalBlobIngress30dayGB' -Value $totalBlobIngress30dayGB -Force -ErrorAction SilentlyContinue
    $storageAccount | Add-Member -MemberType NoteProperty -Name 'defenderForStorageCost' -Value $defenderForStoragePerAccountPrice -Force -ErrorAction SilentlyContinue
    $storageAccount | Add-Member -MemberType NoteProperty -Name 'transactionOverageCost' -Value $transactionOverageCost -Force -ErrorAction SilentlyContinue
    $storageAccount | Add-Member -MemberType NoteProperty -Name 'malwareScanningCost' -Value $($totalBlobIngress30dayGB * $malwareScanningPerGBPrice) -Force -ErrorAction SilentlyContinue

    Write-Host ('    {0} totalTransactions30day: {1}' -f $storageAccount.StorageAccountName,  $totalTransactions30day) -ForegroundColor Yellow
    Write-Host ('    {0} totalBlobIngress30dayBytes: {1}, totalBlobIngress30dayMB:{2} totalBlobIngress30dayGB: {3},' -f $storageAccount.StorageAccountName,  $totalBlobIngress30dayBytes, $totalBlobIngress30dayMB, $totalBlobIngress30dayGB) -ForegroundColor Yellow
}

$report += $storageAccounts | Select StorageAccountName, SubscriptionTenantId, Subscription, SubscriptionId, ResourceGroupName, totalTransactions30day, totalTransactionsOverages30day, totalBlobIngress30dayBytes, totalBlobIngress30dayMB, totalBlobIngress30dayGB,
defenderForStorageCost, transactionOverageCost, malwareScanningCost

# All Storage Account Totals
$totals = @{
    numberOfSubscriptions = ($report.Subscription | Get-Unique | Measure-Object).Count
    numberOfStorageAccounts = ($report.StorageAccountName | Measure-Object).Count
    totalTransactions30day = ($report.totalTransactions30day | Measure-Object -Sum).Sum
    totalTransactionsOverages30day = ($report.totalTransactionsOverages30day | Measure-Object -Sum).Sum
    allAccountsTotalBlobIngress30dayBytes = ($report.totalBlobIngress30dayBytes | Measure-Object -Sum).Sum
    allAccountsTotalBlobIngress30dayMB = ($report.totalBlobIngress30dayMB | Measure-Object -Sum).Sum
    allAccountsTotalBlobIngress30dayGB = ($report.totalBlobIngress30dayGB | Measure-Object -Sum).Sum
    allAccountsTotaldefenderForStorageCost = ($report.defenderForStorageCost | Measure-Object -Sum).Sum
    allAccountsTotaltransactionOverageCost = ($report.transactionOverageCost | Measure-Object -Sum).Sum
    allAccountsTotalmalwareScanningCost = ($report.malwareScanningCost | Measure-Object -Sum).Sum
}

# Adding Some formatting to make the CSV look pretty
$report +=  [PSCustomObject]@{
    StorageAccountName = ''
    SubscriptionTenantId = ''
}
$report +=  [PSCustomObject]@{
    StorageAccountName = 'Total Category'
    SubscriptionTenantId = 'Total Value'
}
$totalsObj = $totals.GetEnumerator() | Sort Name -Descending | % {
    [PSCustomObject]@{
        StorageAccountName = $_.key
        SubscriptionTenantId = $_.Value
    }
}
$report += $totalsObj

Write-Host ('Found a Total of {0} storage accounts in {1} Subscriptions. The values below represent the estimated totals for all storage accounts' -f $totals.numberOfStorageAccounts, $totals.numberOfSubscriptions) -ForegroundColor Green
Write-Host ('Total Transactions Over 30 Days: {0}' -f $totals.totalTransactions30day) -ForegroundColor Green
Write-Host ('Total Transactions Oververage Over 30 Days: {0}' -f $totals.totalTransactionsOverages30day) -ForegroundColor Green
Write-Host ('Total Blob Ingress Over 30 Days (Bytes): {0}' -f $totals.allAccountsTotalBlobIngress30dayBytes) -ForegroundColor Green
Write-Host ('Total Blob Ingress Over 30 Days (MB): {0}' -f $totals.allAccountsTotalBlobIngress30dayMB) -ForegroundColor Green
Write-Host ('Total Blob Ingress Over 30 Days (GB): {0}' -f $totals.allAccountsTotalBlobIngress30dayGB) -ForegroundColor Green
Write-Host ('Total Monthly Defender for Storage Costs: {0}' -f $totals.allAccountsTotaldefenderForStorageCost) -ForegroundColor Blue
Write-Host ('Total Monthly Transactions Overage Costs: {0}' -f $totals.allAccountsTotaltransactionOverageCost) -ForegroundColor Blue
Write-Host ('Total Monthly Malware Scanning Costs: {0}' -f $totals.allAccountsTotalmalwareScanningCost) -ForegroundColor Blue

$report | Export-CSV -Path .\defenderforstorage_estimates.csv -Force

Write-Host ('CSV file created with estimates: {0}\{1}' -f $(pwd).path, 'defenderforstorage_estimates.csv') -ForegroundColor Yellow