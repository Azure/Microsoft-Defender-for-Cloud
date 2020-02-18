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
    #Get Security Task for SQL VA
    $SecurityTasks += Get-AzSecurityTask | Where-Object {$_.RecommendationType -eq "Vulnerability assessment should be enabled on your SQL managed instances"}
}

#Loop Thru tasks
foreach($SecurityTask in $SecurityTasks){
    $SecurityTask.ResourceId
    $StorageAccount = Read-Host "Please enter the stroage account name to configure for SQL MI VA"
    Update-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -ServerName ($SecurityTask.ResourceId.Split("/")[8]) -StorageAccountName $StorageAccount
}
