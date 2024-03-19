<#
.SYNOPSIS
   This script iterate over all VMs in given subscriptions, flitering VMs with CMK (customer managed keys). It then shows all keyvaults connected to these VMs disks Disk Encryption Sets, and optionally 
   Sets permissions on this keyvaults to allow disk scanning app id to access them.

.PARAMETER Subscriptions
   An array of Azure Subscription IDs.
   
.PARAMETER Apply
   A switch parameter to control whether to apply Key Vault permissions.

.EXAMPLE
   .\AddCmkPermissions.ps1 -Subscriptions "Subscription1", "Subscription2" -Apply $true
#>

param (
    [Parameter(Mandatory=$true)]
    [string[]]$Subscriptions,
    [switch]$Apply
)

# Function to print debug information
function Print-DebugInfo {
    param (
        [string]$Message,
        [object]$Data
    )
    Write-Host "DEBUG: $Message"
    $Data | Format-Table -AutoSize
}

function Green
{
    process { Write-Host $_ -ForegroundColor Green }
}

function Red
{
    process { Write-Host $_ -ForegroundColor Red }
}

# Check if the user is logged in to Azure
$loggedIn = az account show --output none 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "You are not logged in to Azure. Please run 'az login' to log in."
    Exit 1
}

# Iterate over Subscriptions
foreach ($subscription in $Subscriptions) {
    Write-Output "Processing subscription $subscription" | Green
	
    # Step 3: Iterate over VMs and get all disk encryption sets  
    $vmsInSubscription = az vm list --subscription $subscription --query "[].{OsDiskDES:storageProfile.osDisk.managedDisk.diskEncryptionSet.id, DataDisksDES:storageProfile.dataDisks[].managedDisk.diskEncryptionSet.id}" --output json    

    # Step 4: Get a list of disk encryption set unique ids
    $desOsIds = $vmsInSubscription | ConvertFrom-Json | ForEach-Object { $_.OsDiskDES } | Where-Object { $_ -ne $null }
	$desDataIds = $vmsInSubscription | ConvertFrom-Json | ForEach-Object { $_.DataDisksDES } | Where-Object { $_ -ne $null }
	$desIds = @($desOsIds + $desDataIds | Sort-Object -Unique)
	Print-DebugInfo -Message "Disk encryption set IDs:" -Data $desIds

    if ($desIds.count -eq 0) {
        Write-Output "No disk encryption sets in subscription $Subscription" | Green
	    continue
    }
	
	# Step 5: Get a list of key vaults unique ids
	$keyVaultIds = az disk-encryption-set show --ids @desIds --query "[].activeKey.sourceVault.id || activeKey.sourceVault.id" --output json
	$keyVaultIds = $keyVaultIds | ConvertFrom-Json | Sort-Object -Unique
	Print-DebugInfo -Message "Key vault IDs:" -Data $keyVaultIds
	
	# Disk scanning Microsoft Entra app: "Microsoft Defender for Cloud Servers Scanner Resource Provider". 
	$appId = '0c7668b5-3260-4ad0-9f53-34ed54fa19b2'
	
	if (-not $Apply) {
		Write-Output "Key Vault permissions will not be applied. Use -apply to apply permissions." | Green
    }
	else
	{
		Write-Output "Key Vault permissions will  be applied. WARNING: keyvaults referenced by VMs disks disk encryption sets may reside in different subscriptions then the VMs subscriptions given as input to this script." | Green
	}
	
	# Iterate over the Key Vault IDs
	foreach ($keyVaultId in $keyVaultIds) {
		# Extract Key Vault name from the resource ID
		$keyVaultName = ($keyVaultId -split '/')[-1]
		$keyVaultSubscription = ($keyVaultId -split '/')[2]
		Print-DebugInfo -Message "Processing Key Vault id $keyVaultId"
		
		# Check if Key Vault is RBAC or non-RBAC
		$keyVaultProperties = az keyvault show --subscription $subscription --name $keyVaultName --query "properties"--output json | ConvertFrom-Json
		$keyVaultRbacEnabled = $keyVaultProperties.enableRbacAuthorization -eq $true
		Print-DebugInfo -Message "Key Vault: $keyVaultName at subscription: $keyVaultSubscription enableRbacAuthorization: $keyVaultRbacEnabled"
		
		if (-not $Apply) {
			continue
        }
		
		if ($Apply) {
            $confirmation = Read-Host "Do you want to apply Key Vault permissions for '$keyVaultId'? (Y/N)"
            if (-not ($confirmation -eq 'Y' -or $confirmation -eq 'y')) {
				Write-Output "Key Vault permissions not applied." | Green 
				continue
			}
		}

		if ($keyVaultRbacEnabled -eq $true) {
			Write-Output "Key Vault '$keyVaultId' is RBAC-enabled. Adding 'Key Vault Crypto Service Encryption User' role for App ID '$appId' at keyvault scope: $keyVaultId" | Green 

			# Add "Key Vault Crypto Service Encryption User" role to the specified app ID
			$res = az role assignment create --assignee $appId --role "Key Vault Crypto Service Encryption User" --scope $keyVaultId
		} else {
			Write-Output "Key Vault '$keyVaultId' is non-RBAC. Adding key get,wrap,unwrap permissions for App ID '$appId'." | Green 

			# Add permissions for key get, wrap, and unwrap to the specified app ID
			$res = az keyvault set-policy --subscription $subscription --name $keyVaultName --spn $appId --key-permissions get wrapKey unwrapKey
		}
	}
}

Write-Output "Done." | Green
