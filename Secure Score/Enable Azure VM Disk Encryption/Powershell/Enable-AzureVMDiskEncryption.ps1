# Improvements to make
# 1) Add KEK support
# 2) Logic for existing RG and KV
# 3) Protect KV from deletion


Write-Verbose "Checking for Azure module..."
$AzModule = Get-Module -Name "Az.*" -ListAvailable
if ($AzModule -eq $null) {
    Write-Verbose "Azure PowerShell module not found"
    #check for Admin Privleges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isadmin = ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    if($isadmin -eq $False){
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
else {
    if ($AzModule.Name -notcontains "Az.Security") {
    Write-Verbose "Azure Security PowerShell module not found"
        if($isadmin -eq $False){
        Write-Warning -Message "Can not install Az Security Module.  You are not running as Administrator"
        Write-Warning -Message "Installing Az Security Module to Current User Scope"
        Install-Module Az.Security -Scope CurrentUser -Force

    }
        Else{
        #Admin, install to all users
        Install-Module Az.Security -Force
    }
}
}
}

#Check/Set Execution Policy
if ((Get-ExecutionPolicy).value__ -eq '3') {
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
}

#Import Modules
Import-Module Az
Import-Module Az.Security

#Login to Azure
Login-AzAccount

#Get All Subs
$Subscriptions = Get-AzSubscription -SubscriptionId 44e4eff8-1fcb-4a22-a7d6-992ac7286382

#Loop Through Subs
foreach($Subscription in $Subscriptions){
    $Id = ($Subscription.Id)
    Select-AzSubscription $Id
    #Get Security Task for Storage Security
    #$SecurityTasks += Get-AzSecurityTask | Where-Object {$_.RecommendationType -eq "EncryptionOnVm"}
    $SecurityTasks += Get-AzSecurityTask | where {$_.Name -like '95d35*'}
}


foreach($SecurityTask in $SecurityTasks){
    $sub = $securityTask.Id.Split("/")[2]
    $vm = $securityTask.ResourceId.Split("/")[8]
    $vmlocation = (Get-AzVm -Name $vm).Location
    $vmrg = (Get-AzVm -Name $vm).ResourceGroupName
    $vaultname = "DiskEncryptionKV${vmlocation}"
    $vaultRG = "DiskEncryptionKV${vmlocation}RG"

    #Create RG and KV and configure KV for disk encryption
    Select-AzSubscription $sub
    New-AzResourceGroup –Name $vaultRG –Location $vmlocation
    New-AzKeyVault -VaultName $vaultname -ResourceGroupName $vaultRG -Location $vmlocation
    Set-AzKeyVaultAccessPolicy -VaultName $vaultname -ResourceGroupName $vaultRG -EnabledForDiskEncryption -EnabledForDeployment -EnabledForTemplateDeployment
    $kvid = (Get-AzKeyVault -VaultName $vaultname -ResourceGroupName $vaultRG).ResourceId
    $kvurl = (Get-AzKeyVault -VaultName $vaultname -ResourceGroupName $vaultRG).VaultUri

    #Create a KEK
#    $kekname = "EncryptionKey${vm}"
#   Add-AzKeyVaultKey -VaultName $vaultname -Name $kekname -Destination 'Software'
#    $kekurl = (Get-AzKeyVaultKey -VaultName $vaultname -Name $kekname).Key.kid
    
    #Encrypt VM
    Set-AzVMDiskEncryptionExtension -ResourceGroupName $vmrg -VMName $vm -DiskEncryptionKeyVaultUrl $kvurl -DiskEncryptionKeyVaultId $kvid
}
