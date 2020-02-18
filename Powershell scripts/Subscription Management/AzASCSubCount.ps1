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

        Install-Module Az.Accounts -Scope CurrentUser -Force

  
    }

    Else{

        #Admin, install to all users

        Install-Module -Name Az -AllowClobber -Force

        Import-Module -Name Az.Accounts -Force

        Import-Module -Name Az.Security -Force
      

    }

}

# Logging in ( Getting token for Azure Tenant )
Write-Verbose "Logging into Azure Tenant"
Login-AzAccount

# Pulling subscriptions this user has access to
Write-Verbose " Pulling all subscriptions assoicated to the AAD Token"
$Subscriptions = Get-AzSubscription

# Collecting events per subscrption, this will take time.
Write-Verbose "Searching each subscription can take up to 30 seconds each"
Write-Host " Please wait while searching all" ($Subscriptions).Count "subscriptions"

foreach($Subscription in $Subscriptions){

    $Id = ($Subscription.Id)

    Select-AzSubscription $Id | Out-Null

    #Get Security Task for App Services

    $ASC += Get-AzSecurityPricing

}

#Total Subscriptions you've collected
Write-Host " Here is a list of all the subscriptions you've just searched"
$Subscriptions | ft

# Providing count of Free and Standard within Subscriptions:

$FreeAppServices = $ASC | where{$_.PricingTier -eq "Free"} | where{$_.Name -eq "AppServices"}
$FreeStorageAccounts = $ASC | where{$_.PricingTier -eq "Free"} | where{$_.Name -eq "StorageAccounts"}
$FreeSQLServers = $ASC | where{$_.PricingTier -eq "Free"} | where{$_.Name -eq "SqlServers"}
$FreeVirtualMachines = $ASC | where{$_.PricingTier -eq "Free"} | where{$_.Name -eq "VirtualMachines"}
$StandardAppServices = $ASC | where{$_.PricingTier -eq "Standard"} | where{$_.Name -eq "AppServices"}
$StandardStorageAccounts = $ASC | where{$_.PricingTier -eq "Standard"} | where{$_.Name -eq "StorageAccounts"}
$StandardSQLServers = $ASC | where{$_.PricingTier -eq "Standard"} | where{$_.Name -eq "SqlServers"}
$StandardVirtualMachines = $ASC | where{$_.PricingTier -eq "Standard"} | where{$_.Name -eq "VirtualMachines"}

Write-Host " The Total Count of Azure Security Center 'Free' subscriptions " -NoNewline
Write-Host ($ASC | where{$_.PricingTier -eq "Free"} | Measure-Object).Count -ForegroundColor Red
Write-Host " Free Sub - App Services " -NoNewline
Write-Host ($ASC | where{$_.PricingTier -eq "Free"} | where{$_.Name -eq "AppServices"} | Measure-Object).Count -ForegroundColor Red
Write-Host " Free Sub - Storage Accounts " -NoNewline
Write-Host ($ASC | where{$_.PricingTier -eq "Free"} | where{$_.Name -eq "StorageAccounts"} | Measure-Object).Count -ForegroundColor Red
Write-Host " Free Sub - Sql Servers " -NoNewline
Write-Host ($ASC | where{$_.PricingTier -eq "Free"} | where{$_.Name -eq "SqlServers"} | Measure-Object).Count -ForegroundColor Red
Write-Host " Free Sub - Virtual Machines " -NoNewline
Write-Host ($ASC | where{$_.PricingTier -eq "Free"} | where{$_.Name -eq "VirtualMachines"} | Measure-Object).Count -ForegroundColor Red
foreach($FreeVirtualMachine in $FreeVirtualMachines){

    $Id = ($FreeVirtualMachine.Id.Split("/")[2])

    Select-AzSubscription $Id | Out-Null

    #Get Security Task for App Services

    $FreeVMCount += Get-AzVM

}
Write-Host " Total Node Count " -NoNewline
Write-Host ($FreeVMCount | Measure-Object).Count -ForegroundColor Yellow
Write-Host " Total Provisioned " -NoNewline
Write-Host ($FreeVMCount | where {$_.ProvisioningState -eq "Succeeded"}).count -ForegroundColor Green
Write-Host " Total Unprovisioned " -NoNewline
Write-Host ($FreeVMCount | where {$_.ProvisioningState -eq "Failed"}).count -ForegroundColor Red

Write-Host " The Total Count of Azure Security Center 'Standard' subscriptions " -NoNewline
Write-Host ($ASC | where{$_.PricingTier -eq "Standard"} | Measure-Object).Count -ForegroundColor Green
Write-Host " Standard Sub - App Services " -NoNewline
Write-Host ($ASC | where{$_.PricingTier -eq "Standard"} | where{$_.Name -eq "AppServices"} | Measure-Object).Count -ForegroundColor Green
Write-Host " Standard Sub - Storage Accounts " -NoNewline
Write-Host ($ASC | where{$_.PricingTier -eq "Standard"} | where{$_.Name -eq "StorageAccounts"} | Measure-Object).Count -ForegroundColor Green
Write-Host " Standard Sub - Sql Servers " -NoNewline
Write-Host ($ASC | where{$_.PricingTier -eq "Standard"} | where{$_.Name -eq "SqlServers"} | Measure-Object).Count -ForegroundColor Green
Write-Host " Standard Sub - Virtual Machines "-NoNewline
Write-Host ($ASC | where{$_.PricingTier -eq "Standard"} | where{$_.Name -eq "VirtualMachines"} | Measure-Object).Count -ForegroundColor Green
foreach($StandardVirtualMachine in $StandardVirtualMachines){

    $Id = ($StandardVirtualMachine.Id.Split("/")[2])

    Select-AzSubscription $Id | Out-Null

    #Get Security Task for App Services

    $StandardVMCount += Get-AzVM

}
Write-Host " Total Node Count " -NoNewline
Write-Host ($StandardVMCount | Measure-Object).Count -ForegroundColor Yellow
Write-Host " Total Provisioned " -NoNewline
Write-Host ($StandardVMCount | where {$_.ProvisioningState -eq "Succeeded"}).count -ForegroundColor Green
Write-Host " Total Unprovisioned " -NoNewline
Write-Host ($StandardVMCount | where {$_.ProvisioningState -eq "Failed"}).count -ForegroundColor Red
