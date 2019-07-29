Write-Verbose "Checking for Azure module..."
$AzModule = Get-Module -Name "Az.*" -ListAvailable
if ($AzModule -eq $null) {
    Write-Verbose "Azure PowerShell module not found"
    #check for Admin Privleges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if(-not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){
        #No Admin, install to current user
        Write-Warning -Message "Can not install Az Module.  You are not running as Administrator"
        Write-Warning -Message "Installing Az Module to Current User Scope"
        Install-Module Az -Scope CurrentUser -Force
        Install-Module Az.Security -Scope CurrentUser -Force

    }
    Else{
        #Admin, install to all users
        Install-Module Az -Force
        Install-Module Az.Security -Force
    }
}

#Login to Azure
Login-AzAccount

#Get All Subs
$Subscriptions = Get-AzSubscription

#Loop Through Subs
foreach($Subscription in $Subscriptions){
    $Id = ($Subscription.Id)
    Select-AzSubscription $Id
    #Get Security Task for Storage Security
    $SecurityTasks += Get-AzSecurityTask | Where-Object {$_.RecommendationType -eq "DDoS Protection Standard should be enabled"}
    $DDOSPlans = Get-AzDdosProtectionPlan
}


#Loop Thru tasks
foreach($SecurityTask in $SecurityTasks){
    $SecurityTask.ResourceId
    If($DDOSPlans.count -eq 1){
        #Plan found use it
        $DDOSPlan = $DDOSPlans
    }
    ElseIF($DDOSPlans.Count -eq 0){
        #No Plans found create one
        $RgName = Read-Host "Please enter a ResourceGroup Name"
        $Location = Read-Host "Please enter an Azure Location"
        $DDOSPlan = New-AzDdosProtectionPlan -ResourceGroupName $RgName -Name "DdosProtectionPlan" -Location $Location
    }
    $Vnet = Get-AzVirtualNetwork -Name ($SecurityTask.ResourceId.Split("/")[8]) -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4])
    $vnet.DdosProtectionPlan = New-Object Microsoft.Azure.Commands.Network.Models.PSResourceId
    $vnet.DdosProtectionPlan.Id = $DDOSPlan.Id
    $vnet.EnableDdosProtection = $true
    $vnet | Set-AzVirtualNetwork
}
