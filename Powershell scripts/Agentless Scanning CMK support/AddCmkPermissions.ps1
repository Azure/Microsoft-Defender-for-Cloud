<#
.SYNOPSIS
   This script iterates over all VMs in specified subscriptions, identifying those with Customer Managed Keys (CMK).
   It applies RBAC permissions at the **subscription level** by default but can also apply permissions at the **Key Vault level** if specified.

.PARAMETER Subscriptions
   An array of Azure Subscription IDs.

.PARAMETER DryRun
   A switch parameter to simulate the process without making changes.

.PARAMETER ApplyAtKeyVaultLevel
   A switch parameter to apply permissions at the Key Vault level instead of the default subscription level.

.NOTES
   - **Access Policies Key Vaults**: Subscription-level RBAC permissions do not apply. The script detects such cases and offers options to configure manually.
   - **Migration to RBAC is recommended** for better security & manageability.
     - Migration Guide: https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-migration
     - RBAC vs. Access Policies: https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-access-policy

.EXAMPLE
   .\AddCmkPermissions.ps1 -Subscriptions "Subscription1", "Subscription2" -DryRun
   .\AddCmkPermissions.ps1 -Subscriptions "Subscription1" -ApplyAtKeyVaultLevel
#>

param (
    [Parameter(Mandatory=$true)]
    [string[]]$Subscriptions,

    [switch]$DryRun,

    [switch]$ApplyAtKeyVaultLevel
)

if (-not $PSBoundParameters.ContainsKey('DryRun')) {
    $DryRun = $false
}

function Green { process { Write-Host $_ -ForegroundColor Green } }
function Red { process { Write-Host $_ -ForegroundColor Red } }

# Check if the user is logged in to Azure
$loggedIn = az account show --output none 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "You are not logged in to Azure. Please run 'az login' to log in."
    Exit 1
}

# Microsoft Defender for Cloud Servers Scanner Resource Provider
$appId = '0c7668b5-3260-4ad0-9f53-34ed54fa19b2'

# Iterate over each subscription
foreach ($subscription in $Subscriptions) {
    Write-Output "Processing subscription $subscription" | Green

    # Step 1: Get Disk Encryption Sets (DES) from VMs
    $vmsInSubscription = az vm list --subscription $subscription --query "[].{OsDiskDES:storageProfile.osDisk.managedDisk.diskEncryptionSet.id, DataDisksDES:storageProfile.dataDisks[].managedDisk.diskEncryptionSet.id}" --output json

    # Step 2: Extract Unique DES IDs
    $desOsIds = $vmsInSubscription | ConvertFrom-Json | ForEach-Object { $_.OsDiskDES } | Where-Object { $_ -ne $null }
    $desDataIds = $vmsInSubscription | ConvertFrom-Json | ForEach-Object { $_.DataDisksDES } | Where-Object { $_ -ne $null }
    $desIds = @($desOsIds + $desDataIds | Sort-Object -Unique)

    if ($desIds.count -eq 0) {
        Write-Output "No disk encryption sets found in subscription $subscription" | Green
        continue
    }

    if ($ApplyAtKeyVaultLevel) {
        # Step 3: Get Key Vaults associated with DES
        Write-Output "Applying permissions at the Key Vault level." | Green
        $keyVaultIds = az disk-encryption-set show --ids @desIds --query "[].activeKey.sourceVault.id || activeKey.sourceVault.id" --output json
        $keyVaultIds = $keyVaultIds | ConvertFrom-Json | Sort-Object -Unique

        if ($keyVaultIds -and $keyVaultIds.Count -gt 0) {
            # Provide a prompt to apply to ALL or ONE-BY-ONE
            $response = Read-Host "Do you want to apply Key Vault permissions for these Key Vault(s)?
            (A)ll - Apply permissions to all Key Vaults
            (O)ne-by-one - Ask for approval for each Key Vault
            (N)o - Skip Key Vaults"

            if ($response -eq "A" -or $response -eq "a") {
                foreach ($keyVaultId in $keyVaultIds) {
                    $keyVaultName = ($keyVaultId -split '/')[-1]
                    $keyVaultSubscription = ($keyVaultId -split '/')[2]
                    Write-Output "Processing Key Vault: $keyVaultName in subscription: $keyVaultSubscription" | Green

                    # Check if the Key Vault is RBAC or Access Policy-based
                    $keyVaultProperties = az keyvault show --subscription $subscription --name $keyVaultName --query "properties" --output json | ConvertFrom-Json
                    $keyVaultRbacEnabled = $keyVaultProperties.enableRbacAuthorization -eq $true
                    Write-Output "Key Vault: $keyVaultName, RBAC Enabled: $keyVaultRbacEnabled" | Green

                    if ($keyVaultRbacEnabled) {
                        if ($DryRun) {
                            Write-Output "DRY RUN: Would apply RBAC permissions for App ID '$appId' to Key Vault: $keyVaultName." | Green
                        } else {
                            Write-Output "Applying RBAC permissions for App ID '$appId' to Key Vault: $keyVaultName." | Green
                            az role assignment create --assignee $appId --role "Key Vault Crypto Service Encryption User" --scope $keyVaultId
                        }
                    } else {
                        if ($DryRun) {
                            Write-Output "DRY RUN: Would apply access policies for App ID '$appId' to Key Vault: $keyVaultName." | Green
                        } else {
                            Write-Output "Applying access policies for App ID '$appId' to Key Vault: $keyVaultName." | Green
                            az keyvault set-policy --subscription $subscription --name $keyVaultName --spn $appId --key-permissions get wrapKey unwrapKey
                        }
                    }
                }
            }
            elseif ($response -eq "O" -or $response -eq "o") {
                # ONE-BY-ONE mode
                foreach ($keyVaultId in $keyVaultIds) {
                    $keyVaultName = ($keyVaultId -split '/')[-1]
                    $keyVaultSubscription = ($keyVaultId -split '/')[2]
                    Write-Output "Processing Key Vault: $keyVaultName in subscription: $keyVaultSubscription" | Green

                    $keyVaultProperties = az keyvault show --subscription $subscription --name $keyVaultName --query "properties" --output json | ConvertFrom-Json
                    $keyVaultRbacEnabled = $keyVaultProperties.enableRbacAuthorization -eq $true
                    Write-Output "Key Vault: $keyVaultName, RBAC Enabled: $keyVaultRbacEnabled" | Green

                    $confirm = Read-Host "Apply permissions to Key Vault: $keyVaultName? (Y/N)"
                    if ($confirm -eq "Y" -or $confirm -eq "y") {
                        if ($keyVaultRbacEnabled) {
                            if ($DryRun) {
                                Write-Output "DRY RUN: Would apply RBAC permissions for App ID '$appId' to Key Vault: $keyVaultName." | Green
                            } else {
                                Write-Output "Applying RBAC permissions for App ID '$appId' to Key Vault: $keyVaultName." | Green
                                az role assignment create --assignee $appId --role "Key Vault Crypto Service Encryption User" --scope $keyVaultId
                            }
                        } else {
                            if ($DryRun) {
                                Write-Output "DRY RUN: Would apply access policies for App ID '$appId' to Key Vault: $keyVaultName." | Green
                            } else {
                                Write-Output "Applying access policies for App ID '$appId' to Key Vault: $keyVaultName." | Green
                                az keyvault set-policy --subscription $subscription --name $keyVaultName --spn $appId --key-permissions get wrapKey unwrapKey
                            }
                        }
                    } else {
                        Write-Output "Skipping Key Vault: $keyVaultName." | Red
                    }
                }
            }
            else {
                Write-Output "Skipping all Key Vault permissions at the Key Vault level." | Green
            }
        } else {
            Write-Output "No Key Vaults associated with the Disk Encryption Sets in subscription $subscription." | Green
        }
    }
    else {
        # Step 4: Apply RBAC permissions at the subscription level (default)
        Write-Output "Applying RBAC permissions at the subscription level for App ID '$appId' in subscription $subscription." | Green

        if ($DryRun) {
            Write-Output "DRY RUN: Would apply RBAC permissions for App ID '$appId' at subscription scope: /subscriptions/$subscription." | Green
        } else {
            Write-Output "Applying RBAC permissions for App ID '$appId' at subscription scope." | Green
            az role assignment create --assignee $appId --role "Key Vault Crypto Service Encryption User" --scope "/subscriptions/$subscription"
        }

        # Step 5: Handle Access Policy Key Vaults (since RBAC does not apply to them)
        $accessPolicyKVs = az disk-encryption-set show --ids @desIds --query "[?properties.activeKey.sourceVault.id && !properties.enableRbacAuthorization].properties.activeKey.sourceVault.id" --output json | ConvertFrom-Json | Sort-Object -Unique

        if ($accessPolicyKVs.Count -gt 0) {
            Write-Output "Found $( $accessPolicyKVs.Count ) Key Vault(s) using Access Policies. They need separate permission setup." | Red

            # Instead of skipping these on DryRun, we'll show the same prompt
            $response = Read-Host "Do you want to apply Key Vault permissions for access policy Key Vaults?
            (A)ll - Apply permissions to all access policy Key Vaults
            (O)ne-by-one - Ask for approval for each Key Vault
            (N)o - Skip access policy Key Vaults"

            if ($response -eq "A" -or $response -eq "a") {
                foreach ($kvId in $accessPolicyKVs) {
                    $kvName = ($kvId -split '/')[-1]
                    if ($DryRun) {
                        Write-Output "DRY RUN: Would apply access policies for App ID '$appId' to Key Vault: $kvName." | Green
                    } else {
                        Write-Output "Applying permissions to $kvId" | Green
                        az keyvault set-policy --subscription $subscription --name $kvName --spn $appId --key-permissions get wrapKey unwrapKey
                    }
                }
            }
            elseif ($response -eq "O" -or $response -eq "o") {
                foreach ($kvId in $accessPolicyKVs) {
                    $kvName = ($kvId -split '/')[-1]
                    $confirm = Read-Host "Apply permissions to $kvId? (Y/N)"
                    if ($confirm -eq "Y" -or $confirm -eq "y") {
                        if ($DryRun) {
                            Write-Output "DRY RUN: Would apply access policies for App ID '$appId' to Key Vault: $kvName." | Green
                        } else {
                            Write-Output "Applying permissions to $kvId" | Green
                            az keyvault set-policy --subscription $subscription --name $kvName --spn $appId --key-permissions get wrapKey unwrapKey
                        }
                    }
                }
            }
            else {
                Write-Output "Skipping access policy Key Vaults." | Green
            }
        }
    }
}

Write-Output "Script execution complete." | Green
