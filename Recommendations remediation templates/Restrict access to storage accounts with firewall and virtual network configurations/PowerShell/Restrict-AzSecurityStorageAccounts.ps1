<#

.Synopsis

  Add IP address Restrictions to Azure Storage Accounts

.EXAMPLE

More information: https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security 

Step 1. (Get-AzStorageAccountNetworkRuleSet -ResourceGroupName "myresourcegroup" -AccountName "mystorageaccount").DefaultAction
Step 2. Update-AzStorageAccountNetworkRuleSet -ResourceGroupName "myresourcegroup" -Name "mystorageaccount" -DefaultAction Deny
Step 3. (Get-AzStorageAccountNetworkRuleSet -ResourceGroupName "myresourcegroup" -AccountName "mystorageaccount").VirtualNetworkRules
Step 4. (Get-AzStorageAccountNetworkRuleSet -ResourceGroupName "myresourcegroup" -AccountName "mystorageaccount").IPRules
Step 5. Update-AzStorageAccountNetworkRuleSet -ResourceGroupName "myresourcegroup" -Name "mystorageaccount" -Bypass AzureServices,Metrics,Logging
Step 6. Add-AzStorageAccountNetworkRule -ResourceGroupName "myresourcegroup" -AccountName "mystorageaccount" -IPAddressOrRange "16.17.18.0/24"

.Requirements

  Az.Resources
  Az.Accounts
  Az.Storage
  Az.Security

.Known Issues
    
  AzureRM Module mixed in with Az Module will break scripting due to conflict of current migration

#>

if ((Test-Path variable:SecurityTasks) -eq $true ) {

Clear-Variable SecurityTasks -Force

}

Write-Verbose "Checking for Azure module..."

$AzModule = Get-Module -Name "Az.*" -ListAvailable

if ($AzModule -eq $null) {

    Write-Verbose "Azure PowerShell module not found"

    #check for Admin Privleges

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    if(-not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){

        #No Admin, install to current user

        Write-Warning -Message "Can not install Az Module.  You are not running as Administrator"

        Write-Warning -Message "Installing Az Module to Current User Scope"

        Install-Module Az -Scope CurrentUser -Force

        Install-Module Az.Security -Scope CurrentUser -Force

        Install-Module Az.Resources -Scope CurrentUser -Force

        Install-Module Az.Accounts -Scope CurrentUser -Force

        Install-Module Az.Storage -Scope CurrentUser -Force



    }

    Else{

        #Admin, install to all users

        Install-Module -Name Az -AllowClobber -Force

        Import-Module -Name Az.Accounts -Force

        Import-Module -Name Az.Security -Force

        Import-Module -Name Az.Resources -Force

        Import-Module -Name Az.Storage -Force

    }

}

#Login to Azure

Login-AzAccount


#Get All Subs

$Subscriptions = Get-AzSubscription

Write-Host "Collecting Subscrptions within tenant. Note: Looking through each subscrption might take some time"

#Loop Through Subs

foreach($Subscription in $Subscriptions){

    $Id = ($Subscription.Id)

    Select-AzSubscription $Id | Out-Null

    #Get Security Task for App Services

    $SecurityTasks += Get-AzSecurityTask | Where-Object {$_.RecommendationType -eq "Restrict access to storage accounts with firewall and virtual network configurations"}

}

Write-Host "Found Active 'Restrict access to storage accounts with firewall and virtual network configurations ' within your subscrptions"

foreach($SecurityTask in $SecurityTasks){

    Write-Host ($SecurityTask.ResourceId)

if  (-not ( ((Get-AzContext).Subscription.id) -eq ($SecurityTask.ResourceId.Split("/")[2])) ) {

  Select-AzSubscription ($SecurityTask.ResourceId.Split("/")[2])
  
  }   
 
if  (-not ((Get-AzStorageAccountNetworkRuleSet -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -AccountName ($SecurityTask.ResourceId.Split("/")[8])).DefaultAction -eq $Deny) ) {

  Write-Host  'Changing Storage Network to "Deny", Required Configuration Change to add IP restrctions see "https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security"'
  Update-AzStorageAccountNetworkRuleSet -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -AccountName ($SecurityTask.ResourceId.Split("/")[8]) -DefaultAction Deny
  Update-AzStorageAccountNetworkRuleSet -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -Name ($SecurityTask.ResourceId.Split("/")[8]) -Bypass AzureServices,Metrics,Logging
  
  }   
Else  {

  Write-Host 'Rule Set is already configured for Deny - Collecting current network configuration of StorageAccount (Blank Line = Nothing configured)'
  (Get-AzStorageAccountNetworkRuleSet -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -AccountName ($SecurityTask.ResourceId.Split("/")[8])).VirtualNetworkRules
  (Get-AzStorageAccountNetworkRuleSet -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -AccountName ($SecurityTask.ResourceId.Split("/")[8])).IpRules
  Update-AzStorageAccountNetworkRuleSet -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -Name ($SecurityTask.ResourceId.Split("/")[8]) -Bypass AzureServices,Metrics,Logging   

  }
  
$IpAddress = Read-Host "Enter IPAddress or IPAddressRange"

Add-AzStorageAccountNetworkRule -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -AccountName ($SecurityTask.ResourceId.Split("/")[8]) -IPAddressOrRange $IpAddress



  }

