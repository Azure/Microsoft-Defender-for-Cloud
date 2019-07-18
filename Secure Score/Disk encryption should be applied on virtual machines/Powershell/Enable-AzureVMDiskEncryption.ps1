Write-Verbose "Checking for Azure module..."
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
    Else
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

        Else
        {
        # Admin, install to all users
        Install-Module Az.Security -Force
        }
    }
}
}

# Check/Set Execution Policy
if ((Get-ExecutionPolicy).value__ -eq '3') 
{
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
}

# Import Modules
Import-Module Az
Import-Module Az.Security

# Login to Azure
Login-AzAccount

# Get All Subs
$Subscriptions = Get-AzSubscription

# Loop Through Subs
foreach($Subscription in $Subscriptions)
{
    $Id = ($Subscription.Id)
    Select-AzSubscription $Id
    # Get Security Task for Storage Security
    $SecurityTasks += Get-AzSecurityTask | Where-Object {$_.RecommendationType -eq "EncryptionOnVm"}
}


foreach($SecurityTask in $SecurityTasks)
{
    $sub = $securityTask.Id.Split("/")[2]
    $vm = $securityTask.ResourceId.Split("/")[8]
    $vmlocation = (Get-AzVm -Name $vm).Location
    $vmrg = (Get-AzVm -Name $vm).ResourceGroupName
    Select-AzSubscription $sub

    # Check for Existing Keyvault
    [array]$vaultnames = $null
    [array]$localvault = $null
    $vaultnames += (Get-AzKeyVault).VaultName
    foreach ($vaultname in $vaultnames)
    {
        $vaultdetails = Get-AzKeyVault -VaultName $vaultname
        
        # Find local KVs with Disk Encryption Flag
        if(($vaultdetails.EnabledForDiskEncryption -eq $true) -and ($vmlocation -eq $vaultdetails.Location))
        {
        $localvault += $vaultdetails.VaultName
        }
    }
        
    # Use local KV if one exists
    if ($localvault -ne $null)
    {
    $localvaultdetails = Get-AzKeyVault -VaultName $localvault[0]
    
    # Encrypt VM using existing KV 
    Set-AzVMDiskEncryptionExtension -ResourceGroupName $vmrg -VMName $vm -DiskEncryptionKeyVaultUrl $localvaultdetails.VaultUri -DiskEncryptionKeyVaultId $localvaultdetails.ResourceId -VolumeType All -SkipVmBackup -Force
    } 

    # If no local KV exists, create one.
    else 
    {
    # Create KV with unique name, allowing for long location names
    $subid = $sub.split("-")[0].substring(0,4)
    $vaultname = "${vmlocation}${subid}"
    $vaultRG = "DiskEncryptionRG-${vmlocation}"
    New-AzResourceGroup –Name $vaultRG –Location $vmlocation
    New-AzKeyVault -VaultName $vaultname -ResourceGroupName $vaultRG -Location $vmlocation -EnableSoftDelete -EnabledForDeployment -EnabledForTemplateDeployment -EnabledForDiskEncryption
    $kvid = (Get-AzKeyVault -VaultName $vaultname -ResourceGroupName $vaultRG).ResourceId
    $kvurl = (Get-AzKeyVault -VaultName $vaultname -ResourceGroupName $vaultRG).VaultUri

    # Encrypt VM
    Set-AzVMDiskEncryptionExtension -ResourceGroupName $vmrg -VMName $vm -DiskEncryptionKeyVaultUrl $kvurl -DiskEncryptionKeyVaultId $kvid -VolumeType All -SkipVmBackup -Force 
    }
}