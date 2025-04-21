# This is a script to clean up the Resources for Microsoft Defender for Cloud Trusted IPs.
$ResourceGroupName = "mdc-network-exposure-trusted-ips"

# Ask for scope type first
Write-Host "At which scope level do you want to delete resources? (Which scope did you apply the policy at?)" -ForegroundColor Cyan
Write-Host "1. Subscription scope"
Write-Host "2. Management group scope"
$scopeChoice = Read-Host "Enter your choice (1 or 2)"

# Log in to Azure if not already logged in
az login

# Resource Group deletion section
if ($scopeChoice -eq "1") {
    # For subscription scope, delete resource group from a specific subscription
    $subscriptionId = Read-Host -Prompt "Enter the subscription ID"
    if ([string]::IsNullOrWhiteSpace($subscriptionId)) {
        Write-Host "Subscription ID cannot be empty. Exiting script." -ForegroundColor Red
        exit
    }
    
    # Set the subscription context
    try {
        az account set --subscription $subscriptionId
    } catch {
        Write-Host "Error setting subscription context: $_" -ForegroundColor Red
        exit
    }
    
    # Check if the resource group exists in this subscription
    $resourceGroupExists = az group exists --name $ResourceGroupName
    
    if ($resourceGroupExists -eq "true") {
        Write-Host "Found '$ResourceGroupName' in subscription: $subscriptionId"
        
        # Ask for confirmation before deleting the resource group
        $confirmation = Read-Host "Are you sure you want to delete resource group '$ResourceGroupName' and the resources inside it from this subscription? (Y/N)"
        
        if ($confirmation -eq 'Y') {
            try {
                Write-Host "Deleting resource group '$ResourceGroupName' from subscription '$subscriptionId'..."
                az group delete --name $ResourceGroupName --yes
                Write-Host "Resource group '$ResourceGroupName' has been successfully deleted from subscription '$subscriptionId'."
            } catch {
                Write-Host "Error deleting resource group: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Resource group deletion cancelled."
        }
    } else {
        Write-Host "Resource group '$ResourceGroupName' was not found in subscription '$subscriptionId'."
    }
} 
elseif ($scopeChoice -eq "2") {
    $managementGroupName = Read-Host -Prompt "Enter the management group name"
    if ([string]::IsNullOrWhiteSpace($managementGroupName)) {
        Write-Host "Management group name cannot be empty. Exiting script." -ForegroundColor Red
        exit
    }
    
    Write-Host "===== RESOURCE GROUP DELETION FROM MANAGEMENT GROUP =====" -ForegroundColor Cyan

    # Get the list of subscriptions under the management group
    $subscriptions = az account management-group subscription show-sub-under-mg --name $managementGroupName --query "[].{Name:displayName}" -o tsv

    # Array to store subscriptions that have the resource group
    $subscriptionsWithResourceGroup = @()

    # First, check which subscriptions have the resource group and list them
    Write-Host "Checking for resource group '$ResourceGroupName' across subscriptions..."
    Write-Host "------------------------------------------------"

    foreach ($subscription in $subscriptions) {
        if ($subscription.Trim() -eq "") {
            continue
        }

        try {
            # Set the context for the current subscription
            az account set --subscription $subscription

            # Check if the resource group exists in the current subscription
            $resourceGroupExists = az group exists --name $ResourceGroupName
            
            if ($resourceGroupExists -eq "true") {
                Write-Host "Found '$ResourceGroupName' in subscription: $subscription"
                $subscriptionsWithResourceGroup += $subscription
            }
        } catch {
            Write-Host "Error checking subscription '$subscription': $_"
        }
    }

    Write-Host "------------------------------------------------"

    # If no subscriptions have the resource group, exit
    if ($subscriptionsWithResourceGroup.Count -eq 0) {
        Write-Host "Resource group '$ResourceGroupName' was not found in any subscription under management group '$managementGroupName'."
        exit
    }

    # Ask for confirmation once before deleting all resource groups
    Write-Host "Found resource group '$ResourceGroupName' in $($subscriptionsWithResourceGroup.Count) subscription(s)."
    $confirmation = Read-Host "Are you sure you want to delete resource group '$ResourceGroupName' and the resources inside it from all these subscriptions? (Y/N)"

    if ($confirmation -eq 'Y') {
        Write-Host "Proceeding with deletion..."
        
        foreach ($subscription in $subscriptionsWithResourceGroup) {
            try {
                # Set the context for the current subscription
                az account set --subscription $subscription

                # Delete the resource group
                Write-Host "Deleting resource group '$ResourceGroupName' from subscription '$subscription'..."
                az group delete --name $ResourceGroupName --yes
                Write-Host "Resource group '$ResourceGroupName' has been successfully deleted from subscription '$subscription'."
            } catch {
                Write-Host "Error deleting from subscription '$subscription': $_" -ForegroundColor Red
            }
        }
        
        Write-Host "Resource group '$ResourceGroupName' has been deleted from all identified subscriptions."
    } else {
        Write-Host "Operation cancelled. No resource groups were deleted."
    }
} else {
    Write-Host "Invalid scope choice. Exiting script." -ForegroundColor Red
    exit
}
