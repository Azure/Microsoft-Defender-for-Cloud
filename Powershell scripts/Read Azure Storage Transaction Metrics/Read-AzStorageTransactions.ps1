<#PSScriptInfo

.VERSION 1.0

.GUID 8acc693a-076b-4e28-8e9d-288f27ebbaeb

.AUTHOR ndicola@microsoft.com

.COMPANYNAME Microsoft

.COPYRIGHT Microsoft

.TAGS 

.LICENSEURI 

.PROJECTURI 
https://github.com/JimGBritt/Azure-Security-Center

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
January 6, 2020 1.0
    - Initial Release
    - Special tanks to Jim Britt (Microsoft) https://twitter.com/JimBrittPhotos for the policy script which has many of the discovery functions!
#>

<#  
.SYNOPSIS  
  This script will enumerate all storage accounts and get the metrics for the last week (aggregated by day) 
  so that you can calculate ASC Storage ATP costs.
   
.DESCRIPTION  
  This script takes a SubscriptionID, ResourceGroup as parameters, analyzes the subscription or
  specific ResourceGroup defined for the resources specified in $Resources, and gets all storage accounts,
  then enumerates the transactions metrics for each. 

.PARAMETER SubscriptionId
    The subscriptionID of the Azure Subscription that contains the resources you want to analyze

.PARAMETER ResourceGroupName
    If desired, use a resourcegroup instead of analyzing all resources within an Azure subscription 

.PARAMETER ExportFile
    PATH\File name to export the output to.  If not used, the working directory of the script will be leveraged as the export directory base folder

.PARAMETER Tenant
    Use the -Tenant parameter to bypass the subscriptionID requirement
    Note: Cannot use in conjunction with -SubscriptionID


.EXAMPLE
  .\Read-AzStorageTransactions.ps1 -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512" -ResourceGroup "RGName"
  Enumerate metrics for all storage accounts in the Resource group in the specified Subscription.
  
.EXAMPLE
  .\Read-AzStorageTransactions.ps1 -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512"
  Enumerate metrics for all storage accounts in the specified Subscription.

.EXAMPLE
  .\Read-AzStorageTransactions.ps1 -Tenant
  Enumerate metrics for all storage accounts in all subscriptions.

.NOTES
   AUTHOR: Nicholas DiCola Principal Group PM  Manager - Security CxE 
   LASTEDIT: January 6, 2020 1.0
    - Initial Release
    - Special tanks to Jim Britt (Microsoft) https://twitter.com/JimBrittPhotos for the policy script which has many of the discovery functions!

.LINK
    This script posted to and discussed at the following locations:
    https://github.com/JimGBritt/Azure-Security-Center
#>

[cmdletbinding(
        DefaultParameterSetName='Default'
    )]

param
(
    
    # Export Directory Path for output - if not set - will default to script directory
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [string]$ExportFile,
    
    # Add a ResourceGroup name to reduce scope from entire Azure Subscription to RG
    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [string]$ResourceGroupName,

    # Provide SubscriptionID to bypass subscription listing
    [Parameter(ParameterSetName='Subscription')]
    [guid]$SubscriptionId,

    # Tenant switch to bypass subscriptionId requirement
    [Parameter(ParameterSetName='Tenant')]
    [switch]$Tenant=$False

)

# FUNCTIONS
# Build out the body for the GET / PUT request via REST API
function BuildBody
(
    [parameter(mandatory=$True)]
    [string]$method
)
{
    $BuildBody = @{
    Headers = @{
        Authorization = "Bearer $($token.AccessToken)"
        'Content-Type' = 'application/json'
    }
    Method = $Method
    UseBasicParsing = $true
    }
    $BuildBody
}  

# Function used to build numbers in selection tables for menus
function Add-IndexNumberToArray (
    [Parameter(Mandatory=$True)]
    [array]$array
    )
{
    for($i=0; $i -lt $array.Count; $i++) 
    { 
        Add-Member -InputObject $array[$i] -Name "#" -Value ($i+1) -MemberType NoteProperty 
    }
    $array
}

# MAIN SCRIPT
if ($MyInvocation.MyCommand.Path -ne $null)
{
    $CurrentDir = Split-Path $MyInvocation.MyCommand.Path
}
else
{
    # Sometimes $myinvocation is null, it depends on the PS console host
    $CurrentDir = "."
}
Set-Location $CurrentDir


If(!($ExportFile))
{
    $ExportFile = "$CurrentDir\azstoragemetrics.csv"
}

#Variable Definitions
$SubScriptionsToProcess = $null

# Login to Azure - if already logged in, use existing credentials.
Write-Host "Authenticating to Azure..." -ForegroundColor Cyan
try
{
    $AzureLogin = Get-AzSubscription
    $currentContext = Get-AzContext
    $token = $currentContext.TokenCache.ReadItems() | Where-Object {$_.tenantid -eq $currentContext.Tenant.Id} 
    if($Token.ExpiresOn -lt $(get-date))
    {
        "Logging you out due to cached token is expired for REST AUTH.  Re-run script"
        $null = Disconnect-AzAccount        
    } 
}
catch
{
    $null = Login-AzAccount
    $AzureLogin = Get-AzSubscription
    $currentContext = Get-AzContext
    $token = $currentContext.TokenCache.ReadItems() | Where-Object {$_.tenantid -eq $currentContext.Tenant.Id} 

}

# Authenticate to Azure if not already authenticated 
If($AzureLogin -and !($SubscriptionID) -and !($Tenant))
{
    [array]$SubscriptionArray = Add-IndexNumberToArray (Get-AzSubscription) 
    [int]$SelectedSub = 0

    # use the current subscription if there is only one subscription available
    if ($SubscriptionArray.Count -eq 1) 
    {
        $SelectedSub = 1
    }
    # Get SubscriptionID if one isn't provided
    while($SelectedSub -gt $SubscriptionArray.Count -or $SelectedSub -lt 1)
    {
        Write-host "Please select a subscription from the list below"
        $SubscriptionArray | Select-Object "#", Id, Name | Format-Table
        try
        {
            $SelectedSub = Read-Host "Please enter a selection from 1 to $($SubscriptionArray.count)"
        }
        catch
        {
            Write-Warning -Message 'Invalid option, please try again.'
        }
    }
    if($($SubscriptionArray[$SelectedSub - 1].Name))
    {
        $SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].Name)
    }
    elseif($($SubscriptionArray[$SelectedSub - 1].SubscriptionName))
    {
        $SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].SubscriptionName)
    }
    write-verbose "You Selected Azure Subscription: $SubscriptionName"
    
    if($($SubscriptionArray[$SelectedSub - 1].SubscriptionID))
    {
        [guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].SubscriptionID)
    }
    if($($SubscriptionArray[$SelectedSub - 1].ID))
    {
        [guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].ID)
    }
}
if($SubscriptionId -and !($Tenant))
{
    Write-Host "Selecting Azure Subscription: $($SubscriptionID.Guid) ..." -ForegroundColor Cyan
    $Null = Select-AzSubscription -SubscriptionId $SubscriptionID.Guid
}
if($Tenant)
{
    $SubScriptionsToProcess = Get-AzSubscription -TenantId $($token).TenantId
}



# Gather a list of resources supporting Azure Diagnostic logs and metrics and display a table
try
{
    if($SubscriptionId -and !($Tenant))
    {
        Write-Host "Gathering a list of Storage Accounts from Azure Subscription ID " -NoNewline -ForegroundColor Cyan
        Write-Host "$SubscriptionId..." -ForegroundColor Yellow
        $ResourcesToCheck = Get-AzStorageAccount
    }
    elseif($Tenant -and !($SubscriptionId))
    {
        if($Tenant){Write-Host "Gathering a list of Storage Accounts from Azure AD Tenant " -ForegroundColor Cyan}
        Write-Host "A total of $($SubScriptionsToProcess.count) subscriptions to process..."
        foreach($Sub in $SubScriptionsToProcess)
        {
            
            $SubIDToProcess = $($Sub.SubscriptionId)
            $SubName = $($Sub.Name)
            $SelectedSub = Select-AzSubscription -SubscriptionID $SubIDToProcess
            Write-Host "Getting Storage Accounts from Subscription: $SubName"
            $ResourcesToCheck += Get-AzStorageAccount
        }       
    }

    #Loop through all storage accounts
    # GET https://management.azure.com/subscriptions/44e4eff8-1fcb-4a22-a7d6-992ac7286382/resourceGroups/CxE-Nicholas/providers/Microsoft.Storage/storageAccounts/cxenicholas/providers/microsoft.insights/metrics?api-version=2018-01-01&metricnames=transactions&timespan=2020-01-05T00:00:00Z/2020-01-05T23:59:59Z&interval=P1D
    $Start = (Get-Date).AddDays(-7) | Get-Date -Hour 0 -Minute 0 -Second 0 | Get-Date -Format "yyyy-MM-ddThh:mm:ssZ"
    $End = (Get-Date).AddDays(-1) | Get-Date -Hour 23 -Minute 59 -Second 59 | Get-Date -Format "yyyy-MM-ddThh:mm:ssZ"
    $body = BuildBody GET
    $records = @()
    Write-Host "Getting metrics for $($ResourcesToCheck.Count) storage accounts"
    foreach($storageAccount in $ResourcesToCheck){
        $uri = "https://management.azure.com$($storageAccount.Id)/providers/microsoft.insights/metrics?api-version=2018-01-01&metricnames=transactions&timespan=$start/$end&interval=P1D"
        $transactions = Invoke-RestMethod -Method GET -Uri $uri -Headers ($body.Headers)
        foreach($result in $transactions.value.timeSeries.data){
            $result | Add-Member -MemberType NoteProperty -Name "Id" -Value $storageAccount.id
            $result | Add-Member -MemberType NoteProperty -Name "StorageAccount" -Value $storageAccount.StorageAccountName
            $result | Add-Member -MemberType NoteProperty -Name "ResourceGroup" -Value $storageAccount.ResourceGroupName
            $result | Add-Member -MemberType NoteProperty -Name "Location" -Value $storageAccount.Location
            $result | Add-Member -MemberType NoteProperty -Name "Subscription" -Value ($storageAccount.id).split("/")[2]            
            $records += $result
        }

    }
    Write-Host "Exporting $($records.Count) records to $($ExportFile)"
    $records | Export-csv $ExportFile
}
catch
{
    if($SubscriptionId)
    {
        Throw write-host "No Storage Accounts available in selected subscription $SubscriptionID" -ForegroundColor Red
    }
}

Write-Host "Complete" -ForegroundColor Green