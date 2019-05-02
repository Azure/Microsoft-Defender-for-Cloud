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
    $SecurityTasks += Get-AzSecurityTask | Where-Object {$_.RecommendationType -eq "Enable auditing for the SQL server"}
}

#Loop Thru tasks
foreach($SecurityTask in $SecurityTasks){
    $SQLDatabases = Get-AzSqlDatabase -ServerName ($SecurityTask.ResourceId.Split("/")[8]) -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4])
    Write-Host ($SecurityTask.ResourceId)
    Write-Host "Which type of auditing storage do you want to use?"
    $StorageType = Read-Host "Storage, LogA or EventHub"
    if($StorageType -eq "Storage"){
        $StorageName = Read-Host "Enter the name of the storage account"
        Set-AzSqlServerAuditing -State Enabled -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -ServerName ($SecurityTask.ResourceId.Split("/")[8]) -StorageAccountName "$StorageName"
        foreach($SQLDatabase in $SQLDatabases){
            if(($SQLDatabase.ResourceId.Split("/")[10]) -ne "master"){
                Set-AzSqlDatabaseAuditing -State Enabled -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -DatabaseName ($SQLDatabase.ResourceId.Split("/")[10]) -StorageAccountName "$StorageName"
            }
        }
    }
    if($StorageType -eq "LogA"){
        $WorkspaceName = Read-Host "Enter the name of the workspace to use"
        $Workspace = Get-AzOperationalInsightsWorkspace | Where-Object {$_.Name -eq "$WorkspaceName"}
        Set-AzSqlServerAuditing -State Enabled -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -ServerName ($SecurityTask.ResourceId.Split("/")[8]) -LogAnalytics -WorkspaceResourceId ($Workspace.ResourceId)
        foreach($SQLDatabase in $SQLDatabases){
            if(($SQLDatabase.ResourceId.Split("/")[10]) -ne "master"){
                Set-AzSqlDatabaseAuditing -State Enabled -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -DatabaseName ($SQLDatabase.ResourceId.Split("/")[10]) -LogAnalytics -WorkspaceResourceId ($Workspace.ResourceId)
            }
        }
    }
    if($StorageType -eq "EventHub"){
        $RGName = Read-Host "Enter the Resource Group of the eventhub to use"
        $Namespace = Read-Host "Enter the namespace of the event hub to use"
        $EventHub = Get-AzEventHub -ResourceGroupName "$RGName" -Namespace "$Namespace"
        $EventHubAuthRules = Get-AzEventHubAuthorizationRule -ResourceGroupName "$RGName" -Namespace "$Namespace"
         Write-Host ($EventHubAuthRules.Name)
        $Rule = Read-Host "Which auth rule do you want to use?"  
        $EventHubAuthRule = $EventHubAuthRules | Where-Object {$_.Name -eq "$Rule"}      
        Set-AzSqlServerAuditing -State Enabled -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -ServerName ($SecurityTask.ResourceId.Split("/")[8]) -EventHubName ($EventHub.Name) -EventHubAuthorizationRuleResourceId ($EventHubAuthRule.Id)
        foreach($SQLDatabase in $SQLDatabases){
            if(($SQLDatabase.ResourceId.Split("/")[10]) -ne "master"){
                Set-AzSqlDatabaseAuditing -State Enabled -ResourceGroupName ($SecurityTask.ResourceId.Split("/")[4]) -DatabaseName ($SQLDatabase.ResourceId.Split("/")[10]) -EventHubName ($EventHub.Name) -EventHubAuthorizationRuleResourceId ($EventHubAuthRule.Id)
            }
        }
    }
    
}
