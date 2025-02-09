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

# If -DryRun is not provided at all, default to $false
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
    $vmsInSubscription = az vm list `
        --subscription $subscription `
        --query "[].{OsDiskDES:storageProfile.osDisk.managedDisk.diskEncryptionSet.id, DataDisksDES:storageProfile.dataDisks[].managedDisk.diskEncryptionSet.id}" `
        --output json

    # Step 2: Extract Unique DES IDs
    $desOsIds   = $vmsInSubscription | ConvertFrom-Json | ForEach-Object { $_.OsDiskDES } | Where-Object { $_ -ne $null }
    $desDataIds = $vmsInSubscription | ConvertFrom-Json | ForEach-Object { $_.DataDisksDES } | Where-Object { $_ -ne $null }
    $desIds     = @($desOsIds + $desDataIds) | Sort-Object -Unique

    if ($desIds.Count -eq 0) {
        Write-Output "No disk encryption sets found in subscription $subscription" | Green
        continue
    }

    if ($ApplyAtKeyVaultLevel) {
        # APPLY PERMISSIONS AT THE KEY VAULT LEVEL
        Write-Output "`nApplying permissions at the Key Vault level for subscription $subscription." | Green

        # Step 3: Get Key Vaults associated with DES
        $keyVaultIds = az disk-encryption-set show `
            --ids @($desIds) `
            --query "[].activeKey.sourceVault.id || activeKey.sourceVault.id" `
            --output json

        $keyVaultIds = $keyVaultIds | ConvertFrom-Json | Sort-Object -Unique

        if (-not $keyVaultIds -or $keyVaultIds.Count -eq 0) {
            Write-Output "No Key Vaults associated with the Disk Encryption Sets in subscription $subscription." | Green
            continue
        }

        # Gather key vault objects for interactive prompt
        $kvObjects = @()
        foreach ($keyVaultId in $keyVaultIds) {
            $keyVaultName = ($keyVaultId -split '/')[-1]
            $keyVaultSubscription = ($keyVaultId -split '/')[2]

            Write-Output "`nFound Key Vault: $keyVaultName (Subscription: $keyVaultSubscription)" | Green

            # Check if the Key Vault is RBAC or Access Policy-based
            $keyVaultProperties = az keyvault show `
                --subscription $keyVaultSubscription `
                --name $keyVaultName `
                --query "properties" `
                --output json | ConvertFrom-Json

            $keyVaultRbacEnabled = $false
            if ($null -ne $keyVaultProperties.enableRbacAuthorization -and $keyVaultProperties.enableRbacAuthorization -eq $true) {
                $keyVaultRbacEnabled = $true
            }

            $kvObjects += [PSCustomObject]@{
                Id          = $keyVaultId
                Name        = $keyVaultName
                Subscription= $keyVaultSubscription
                RbacEnabled = $keyVaultRbacEnabled
            }
        }

        Write-Output "`nKey Vault(s) to process: $($kvObjects.Count)."
        # Provide an option to handle all Key Vaults, one-by-one, or skip
        $response = Read-Host "Apply Key Vault-level permissions for these Key Vault(s)? 
        (A)ll - Apply to all 
        (O)ne-by-one - Prompt for each 
        (N)o - Skip all"

        foreach ($kv in $kvObjects) {
            if ($response -eq 'N' -or $response -eq 'n') {
                Write-Output "Skipping Key Vault permissions for all remaining Key Vaults." | Red
                break
            }
            elseif ($response -eq 'A' -or $response -eq 'a') {
                # Apply to all Key Vaults (no prompt per vault)
                if ($kv.RbacEnabled) {
                    if ($DryRun) {
                        Write-Output "DRY RUN: Would assign 'Key Vault Crypto Service Encryption User' role to $($kv.Name) (RBAC enabled)."
                    } else {
                        Write-Output "Applying RBAC permissions to Key Vault: $($kv.Name)." | Green
                        az role assignment create `
                            --assignee $appId `
                            --role "Key Vault Crypto Service Encryption User" `
                            --scope $kv.Id `
                            --subscription $kv.Subscription
                    }
                }
                else {
                    if ($DryRun) {
                        Write-Output "DRY RUN: Would set Access Policy on Key Vault: $($kv.Name)."
                    } else {
                        Write-Output "Applying access policies to Key Vault: $($kv.Name)." | Green
                        az keyvault set-policy `
                            --subscription $kv.Subscription `
                            --name $kv.Name `
                            --spn $appId `
                            --key-permissions get wrapKey unwrapKey
                    }
                }
            }
            elseif ($response -eq 'O' -or $response -eq 'o') {
                # Prompt for each Key Vault
                $confirm = Read-Host "Apply permissions to Key Vault: $($kv.Name)? (Y/N)"
                if ($confirm -eq 'Y' -or $confirm -eq 'y') {
                    if ($kv.RbacEnabled) {
                        if ($DryRun) {
                            Write-Output "DRY RUN: Would assign 'Key Vault Crypto Service Encryption User' role to $($kv.Name)."
                        } else {
                            Write-Output "Applying RBAC permissions to Key Vault: $($kv.Name)." | Green
                            az role assignment create `
                                --assignee $appId `
                                --role "Key Vault Crypto Service Encryption User" `
                                --scope $kv.Id `
                                --subscription $kv.Subscription
                        }
                    }
                    else {
                        if ($DryRun) {
                            Write-Output "DRY RUN: Would set Access Policy on Key Vault: $($kv.Name)."
                        } else {
                            Write-Output "Applying access policies to Key Vault: $($kv.Name)." | Green
                            az keyvault set-policy `
                                --subscription $kv.Subscription `
                                --name $kv.Name `
                                --spn $appId `
                                --key-permissions get wrapKey unwrapKey
                        }
                    }
                } else {
                    Write-Output "Skipping Key Vault: $($kv.Name)." | Red
                }
            }
            else {
                Write-Output "Invalid choice or unrecognized response. Skipping Key Vault permissions." | Red
                break
            }
        }

    } else {
        # APPLY PERMISSIONS AT THE SUBSCRIPTION LEVEL (DEFAULT)
        Write-Output "`nApplying RBAC permissions at the subscription level for subscription $subscription." | Green

        if ($DryRun) {
            Write-Output "DRY RUN: Would assign 'Key Vault Crypto Service Encryption User' role to App ID '$appId' at subscription scope: /subscriptions/$subscription." | Green
        } else {
            Write-Output "Applying RBAC permissions for App ID '$appId' at subscription scope /subscriptions/$subscription." | Green
            az role assignment create `
                --assignee $appId `
                --role "Key Vault Crypto Service Encryption User" `
                --scope "/subscriptions/$subscription"
        }

        # Step 5: Handle Access Policy Key Vaults (since RBAC does not apply to them)
        $accessPolicyKVs = az disk-encryption-set show `
            --ids @($desIds) `
            --query "[?properties.activeKey.sourceVault.id && !properties.enableRbacAuthorization].properties.activeKey.sourceVault.id" `
            --output json | ConvertFrom-Json | Sort-Object -Unique

        if ($accessPolicyKVs -and $accessPolicyKVs.Count -gt 0) {
            Write-Output "`nFound $( $accessPolicyKVs.Count ) Key Vault(s) using Access Policies in subscription $subscription. They need separate permission setup." | Red

            # Prompt the user on how to handle these Key Vaults
            $response = Read-Host "Apply Key Vault permissions for Access Policy Key Vault(s)? 
            (A)ll - Apply to all 
            (O)ne-by-one - Prompt for each 
            (N)o - Skip all"

            foreach ($kvId in $accessPolicyKVs) {
                $keyVaultName = ($kvId -split '/')[-1]

                if ($response -eq 'N' -or $response -eq 'n') {
                    Write-Output "Skipping all Access Policy Key Vaults." | Red
                    break
                }
                elseif ($response -eq 'A' -or $response -eq 'a') {
                    # Apply to all KVs
                    if ($DryRun) {
                        Write-Output "DRY RUN: Would set Access Policy on Key Vault: $keyVaultName." | Green
                    } else {
                        Write-Output "Applying Access Policy on Key Vault: $keyVaultName." | Green
                        az keyvault set-policy `
                            --subscription $subscription `
                            --name $keyVaultName `
                            --spn $appId `
                            --key-permissions get wrapKey unwrapKey
                    }
                }
                elseif ($response -eq 'O' -or $response -eq 'o') {
                    # Prompt for each KV
                    $confirm = Read-Host "Apply permissions to Key Vault: $keyVaultName? (Y/N)"
                    if ($confirm -eq 'Y' -or $confirm -eq 'y') {
                        if ($DryRun) {
                            Write-Output "DRY RUN: Would set Access Policy on Key Vault: $keyVaultName." | Green
                        } else {
                            Write-Output "Applying Access Policy on Key Vault: $keyVaultName." | Green
                            az keyvault set-policy `
                                --subscription $subscription `
                                --name $keyVaultName `
                                --spn $appId `
                                --key-permissions get wrapKey unwrapKey
                        }
                    } else {
                        Write-Output "Skipping Key Vault: $keyVaultName." | Red
                    }
                }
                else {
                    Write-Output "Invalid choice or unrecognized response. Skipping Access Policy Key Vaults." | Red
                    break
                }
            }
        }
    }
}

Write-Output "`nScript execution complete." | Green
