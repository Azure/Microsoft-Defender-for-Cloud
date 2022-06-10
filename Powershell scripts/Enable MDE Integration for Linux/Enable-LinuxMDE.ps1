write-host '#####################################################################################################' -ForegroundColor green
write-host '#                                                                                                   #' -ForegroundColor green
write-host '#   This script will enable MDE integration for Linux machines with Microsoft Defender for Cloud.   #' -ForegroundColor green
write-host '#   Please enter your Tenant ID. The script will then configure all subscriptions in this tenant.   #' -ForegroundColor green
write-host '#                                                                                                   #' -ForegroundColor green
write-host '#   You will be asked if you want to enable MDE integration on all subscriptions, or only those     #' -ForegroundColor green
write-host '#   that already have MDE integration for Windows machines enabled.                                 #' -ForegroundColor green
write-host '#                                                                                                   #' -ForegroundColor green
write-host '#####################################################################################################' -ForegroundColor green
write-host ''
$tenantId = Read-Host "Enter your Tenant ID"
$enableMDE = Read-Host "Do you want to enable MDE integration on all subscriptions (y/n)?"
while ("y","n" -notcontains $enableMDE) {
    $enableMDE = Read-Host "Do you want to enable MDE integration on all subscriptions? Please only enter (y/n)."
}
$subscriptions = Get-AzSubscription -TenantId $tenantId
Foreach ($subscription in $subscriptions){
    $context = Set-AzContext -Subscription $subscription.id
    Write-host -nonewline "Testing subscription "
    Write-host -nonewline $context.subscription.Name -ForegroundColor Green
    Write-host -nonewline " with subscription ID "
    Write-host -nonewline $context.subscription.Id -ForegroundColor Green
    Write-host "."
    $test0 = Get-AzSecuritySetting -SettingName WDATP
    If ($test0.enabled) {
        $test1 = Get-AzSecuritySetting -SettingName WDATP_EXCLUDE_LINUX_PUBLIC_PREVIEW
        If ($test1.enabled){
            Set-AzSecuritySetting -SettingName WDATP_EXCLUDE_LINUX_PUBLIC_PREVIEW `
            -SettingKind DataExportSettings `
            -Enabled $false > $null
            Write-Host "Enabled MDE integration for Linux machines on subscription" $context.subscription.id
        }
    }
    elseif ($enableMDE -eq "y"){
        Set-AzSecuritySetting -SettingName WDATP `
        -SettingKind DataExportSettings `
        -Enabled $true > $null
        Write-Host "Enabled MDE integration for all machines on subscription" $context.subscription.id
    }
    else {
        continue
    }
}