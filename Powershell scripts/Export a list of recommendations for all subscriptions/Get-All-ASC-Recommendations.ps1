#######################################################################################
# This sample script enumerates through all your subscriptions you have access to     #
# and creates a CSV file with all recommendations across your subscriptions           #
# Prerequisites:                                                                      #
# - Latest Az PowerShell module                                                       #
# - logged into to Azure (login-AzAccount)                                            #
# - output folder and filename                                                        #
#######################################################################################

$ErrorActionPreference = 'Stop'
$outputFolder = "<Your Output Folder>" # use format "c:\temp"
$outputFileName = "ASC-Recommendations.csv"
$Subscriptions = Get-AzSubscription
$RecommendationTable = @()
$MissingSubscriptions = @()

#region check Az Module presence
Write-Host "Checking if you have installed the Azure module..." -ForeGroundColor Green
$AzModule = Get-Module -Name "Az.*" -ListAvailable
if ($AzModule -eq $null) 
{
    Write-Verbose "Azure PowerShell module not found"
    # Check for Admin Privleges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isadmin = ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    if($isadmin -eq $False)
    {
        # No Admin, install to current user
        Write-Warning -Message "Can not install Az Module.  You are not running as Administrator"
        Write-Warning -Message "Installing Az Module to Current User Scope"
        Install-Module Az -Scope CurrentUser -Force
        Install-Module Az.Security -Scope CurrentUser -Force
    }
    else
    {
        # Admin, install to all users
        Install-Module Az -Force
        Install-Module Az.Security -Force
    }
else 
{
    if ($AzModule.Name -notcontains "Az.Security") 
    {
        Write-Verbose "Azure Security PowerShell module not found"
        if($isadmin -eq $False){
            Write-Warning -Message "Can not install Az Security Module.  You are not running as Administrator"
            Write-Warning -Message "Installing Az Security Module to Current User Scope"
            Install-Module Az.Security -Scope CurrentUser -Force
    }
    else
        {
            # Admin, install to all users
            Install-Module Az.Security -Force
        }
    }
 }
}

# Import Modules - uncomment if the modules are not loaded by default
#Import-Module Az
#Import-Module Az.Security

# Login to Azure - uncomment if you need to login
#Login-AzAccount
#endregion

Write-Host "Getting recommendations from your Azure subscriptions.....please by patient" -ForegroundColor Green
foreach($Subscription in $Subscriptions)
{
    Select-AzSubscription $Subscription.Id

    try
    {
        $SecurityTasks = Get-AzSecurityTask # get all recommendations from ASC

        foreach($SecurityTask in $SecurityTasks)
        {
            If([string]::IsNullOrEmpty($SecurityTask.ResourceId.Split("/")[8])) {  
            # resource field is empty, do nothing, since this is not actionable
            }
            
            else {
                $Recommendations = New-Object psobject -Property @{
                    Recommendation = $SecurityTask.RecommendationType
                    Resource = ($SecurityTask.ResourceId.Split("/")[8])
                    SubscriptionName = $Subscription.Name
                    SubscriptionId = ($SecurityTask.ResourceId.Split("/")[2])
                    ResourceGroup = ($SecurityTask.ResourceId.Split("/")[4])
                }
                $RecommendationTable += $Recommendations
            }
        }
    }
    catch
    {
        Write-Host "Could not get recommendations for subscription: " $Subscription.Name -ForegroundColor Red
        Write-Host "Error Message: " $_.Exception.Message -ForeGroundColor Red
        Write-Host "Skipping subscription `r`n" -ForegroundColor Red
        $MissingSubscriptionsDetails = New-Object psobject -Property @{
            SubscriptionName = $Subscription.Name
            SubscriptionId = ($SecurityTask.ResourceId.Split("/")[2])
            ErrorMessage = $_.Exception.Message
        }
        $MissingSubscriptions += $MissingSubscriptionsDetails
    }
}

Write-Host "*** Creating Output file: " ($outputFolder + "\" + $outputFileName)  "***" -ForegroundColor Green
try
{
    $RecommendationTable | Select-Object "SubscriptionName", "SubscriptionId", "Resource", "Recommendation", "ResourceGroup" | Export-Csv -Path ($outputFolder + "\" + $outputFileName) -Force -NoTypeInformation
    Write-Host "Done! `r`n" -ForegroundColor Yellow
}
catch {Write-Host "Could not create output file.... Please check your path, filename and write permissions." -ForeGroundColor Red}

# list missing subscriptions, in case we could not get recommendations for a certain subscription due to an error
if($MissingSubscriptions -ne $null)
{
    Write-Host "Recommendations for the following subscriptions could not be retrieved:" -ForegroundColor Red
    $MissingSubscriptions
}
