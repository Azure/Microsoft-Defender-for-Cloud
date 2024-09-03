#Requires -Modules Az, Az.Resources, Az.Accounts, Az.Compute, Az.ConnectedMachine, Az.SqlVirtualMachine

<#
.SYNOPSIS
Finds SQL VMs and Arc machines not protected by Defender for SQL servers on machines.

.DESCRIPTION
This script identifies SQL VMs and Arc machines that lack Defender for SQL servers on machines protection.

.PARAMETER SubscriptionId
[Required] The Azure subscription ID for enabling Defender for SQL servers on machines.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId
)

try {
    # Log in to Azure if not already logged in
    Connect-AzAccount -Subscription $SubscriptionId -ErrorAction Stop
    # Retrieve all Arc machine resources and SQL VMs from the selected subscription
    Write-Host "Retrieving all Arc machine resources and VMs from subscription $($SubscriptionId)"
    $allResources = Get-AzResource | Where-Object {
        $_.ResourceType -match 'Microsoft.HybridCompute/machines|Microsoft.Compute/virtualMachines'
    }
}
catch {
    Write-Error "Unable to retrieve Arc resources and SQL VMs from subscriptio $($SubscriptionId), error: $_"
    Write-Error "Stopping the script."
    exit 1
}


# Filter Arc machines and VMs
$ArcResources = $allResources | Where-Object { $_.ResourceType -eq 'Microsoft.HybridCompute/machines' }
$VMResources = $allResources | Where-Object { $_.ResourceType -eq 'Microsoft.Compute/virtualMachines' }

# Initialize lists to store not protected machines and their errors
$nonCompliantVMs = @()
$nonCompliantVMsError = @()

Write-Host "-----------------------"
# Iterate over all SQL VMs in the subscription to identify not protected VMs
Write-Host "Checking all SQL VMs in the subscription for compliance"
foreach ($vm in $VMResources) {
    try {
        # Obtain the instance view of the VM
        $vmInstanceView = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to obtain status for machine $($vm.Name). Exception: $_"
        continue
    }

    try {
        # Obtain the instance view of the SQL VM
        $sqlVMInstanceView = Get-AzSqlVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -ErrorAction Stop
    }
    catch {
        Write-Host "VM $($vm.Name) is missing SQL extension, skipping.."
        continue
    }

    # Exclude deallocated machines
    $powerState = ($vmInstanceView.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus

    if (-not $powerState -or $powerState.ToLower() -ne 'vm deallocated') {
        # Exclude Linux machines
        if ($vmInstanceView.OsName.ToLower() -like "*windows*") {
            # Verify the presence of extensions
            if ($vmInstanceView.Extensions) {

                # Search for the Defender for SQL extension
                $defenderForSQLExtension = $vmInstanceView.Extensions | Where-Object {
                    $_.Type -ne $null -and $_.Type.ToLower() -eq 'microsoft.azure.azuredefenderforsql.advancedthreatprotection.windows'
                }

                if ($defenderForSQLExtension) {
                    $addToNonCompliant = $false
                    $errorMsg  = ""

                    # Inspect the extension statuses
                    if ($defenderForSQLExtension.Statuses) {
                        foreach ($status in $defenderForSQLExtension.Statuses) {
                            $message = $status.Message.ToLower()
                            $displayStatus = $status.DisplayStatus.ToLower()

                            # Validate the status message
                            if ($displayStatus -ne $null -and $displayStatus -like "*provisioning succeeded*") {
                                    if ($message -ne $null -and $message -notlike "*extension is running*") {
                                    Write-Host "VM $($vm.Name) is not protected. Defender for SQL extension status contains errors."
                                    $errorMsg  = $message
                                    $addToNonCompliant = $true
                                }
                            } else {
                                Write-Host "VM $($vm.Name) is not protected. Defender for SQL extension provisioning failed."
                                $errorMsg  = "Defender for SQL extension provisioning failed, $message"
                                $addToNonCompliant = $true
                            }
                        }
                    } else {
                        Write-Host "VM $($vm.Name) is not protected. Missing Defender for SQL extension status."
                        $errorMsg  = "Missing Defender for SQL extension status."
                        $addToNonCompliant = $true
                    }

                    if ($addToNonCompliant) {
                        $nonCompliantVMs += $vm.Name
                        $nonCompliantVMsError += $errorMsg
                    }
                } else {
                    Write-Host "VM $($vm.Name) is not protected. Defender for SQL extension is missing."
                    $errorMsg  = "Defender for SQL extension is missing."
                    $nonCompliantVMs += $vm.Name
                    $nonCompliantVMsError += $errorMsg
                }
            } else {
                Write-Host "VM $($vm.Name) is missing extensions, skipping.."
            }
        } else {
            Write-Host "VM $($vm.Name) OS type is Linux, skipping.."
        }
    } else {
        Write-Host "VM $($vm.Name) is deallocated. Missing extensions information. skipping.."
    }
}

# Initialize a list to store Arcs that don't meet the criteria
$nonCompliantArcs = @()
$nonCompliantArcsError = @()

Write-Host "-----------------------"
# Iterate over all Arc machines in the subscription to identify not protected Arc machines
Write-Host "Checking all Arc machines in the subscription for compliance machines"
foreach ($arc in $ArcResources) {
    try {
        # Obtain the instance view of the Arc machine
        $arcInstanceView = Get-AzConnectedMachine -ResourceGroupName $arc.ResourceGroupName -MachineName $arc.Name -ErrorAction Stop
        $arcInstanceExtensionView = Get-AzConnectedMachineExtension -ResourceGroupName $arc.ResourceGroupName -MachineName $arc.Name -Expand StatusMessage -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to obtain status for machine $($arc.Name). Exception: $_"
        continue
    }

       # Exclude not connected machines
    if ($arcInstanceView.Status -ne $null -and $arcInstanceView.Status -like 'Connected') {
        # Exclude Linux machines
        if ($arcInstanceView.OSType.ToLower() -like "windows") {
            $addToNonCompliant = $false
            $errorMsg  = ""

            # Search for the Defender for SQL extension
            $defenderForSQLExtension = $arcInstanceExtensionView | Where-Object {
                $_.Publisher -ne $null -and $_.Publisher.ToLower() -eq 'microsoft.azure.azuredefenderforsql'
            }

            # Search for the SQL IaaS extension
            $sqlExtension = $arcInstanceExtensionView | Where-Object {
                $_.Publisher -ne $null -and $_.Publisher.ToLower() -eq 'microsoft.azuredata' -and $_.Name -ne $null -and $_.Name.ToLower() -eq 'windowsagent.sqlserver'
            }

            if ($sqlExtension) {
                if ($defenderForSQLExtension -ne $null) {
                    # Inspect the extension provisioning state
                    $displayStatus = $defenderForSQLExtension.ProvisioningState.ToLower()
                    if ($displayStatus -ne $null -and $displayStatus -like "*Succeeded*") {
                    # Inspect the extension statuses
                        if ($defenderForSQLExtension.StatusMessage -ne $null) {
                            $message = $defenderForSQLExtension.StatusMessage.ToLower()

                            # Validate the status message
                            if ($message -ne $null -and $message -notlike "*extension is running*") {
                                Write-Host "Arc machine $($arc.Name) is not protected. Defender for SQL extension status contains errors."
                                $errorMsg  = $message
                                $addToNonCompliant = $true
                            }
                        } else {
                            Write-Host "Arc machine $($arc.Name) is not protected. Missing Defender for SQL extension status."
                            $errorMsg  = "Missing Defender for SQL extension status."
                            $addToNonCompliant = $true
                        }
                    } else {
                        Write-Host "Arc machine $($arc.Name) is not protected. Defender for SQL extension provisioning failed."
                        $errorMsg  = "Defender for SQL extension provisioning failed, $($defenderForSQLExtension.StatusMessage)"
                        $addToNonCompliant = $true
                    }

                    if ($addToNonCompliant) {
                        $nonCompliantArcs += $arc.Name
                        $nonCompliantArcsError += $errorMsg
                    }
                } else {
                    Write-Host "Arc machine $($arc.Name) is not protected. Defender for SQL extension is missing."
                    $errorMsg  = "Defender for SQL extension is missing."
                    $nonCompliantArcs += $arc.Name
                    $nonCompliantArcsError += $errorMsg
                }
            }
            else {
                Write-Host "Arc machine $($arc.Name) is missing SQL extension, skipping.."
            }
        } else {
            Write-Host "Arc machine $($arc.Name) OS type is Linux, skipping.."
        }
    } else {
        Write-Host "Arc machine $($arc.Name) is not connected. Missing extensions information. skipping.."
    }
}

# Output the list of not protected VMs
Write-Host "-----------------------"
if ($nonCompliantVMs.Count -gt 0) {
    Write-Host "The following VMs are not protected:"
    for ($i = 0; $i -lt $nonCompliantVMs.Count; $i++) {
    Write-Host "VM: $($nonCompliantVMs[$i]), error: $($nonCompliantVMsError[$i])"
}
} else {
    Write-Host "After checking all connected VMs, no not protected VMs were found. To test deallocated VMs, please turn them on and re-run the script."
}

# Output the list of not protected Arc machines
Write-Host "-----------------------"
if ($nonCompliantArcs.Count -gt 0) {
    Write-Host "The following Arc machines are not protected:"
    for ($i = 0; $i -lt $nonCompliantArcs.Count; $i++) {
    Write-Host "Arc machine: $($nonCompliantArcs[$i]), error: $($nonCompliantArcsError[$i])"
}
} else {
    Write-Host "After checking all connected Arc machines, no not protected Arc machines were found. To test disconnected Arc machines, please turn them on and re-run the script."
}
