# This is a script to clean up the Resources for Microsoft Defender for Cloud Trusted IPs.
$ResourceGroupName = "mdc-network-exposure-trusted-ips"

# Ask for scope type first
Write-Output "At which scope level do you want to delete resources? (Which scope did you apply the policy at?)"
Write-Output "1. Subscription scope"
Write-Output "2. Management group scope"
$scopeChoice = Read-Host "Enter your choice (1 or 2)"

# Resource Group deletion section
if ($scopeChoice -eq "1") {
    # For subscription scope, delete resource group from a specific subscription
    $subscriptionId = Read-Host -Prompt "Enter the subscription ID"
    if ([string]::IsNullOrWhiteSpace($subscriptionId)) {
        Write-Output "Subscription ID cannot be empty. Exiting script."
        exit
    }

    # Log in to Azure if not already logged in
    az login

    # Check if subscription exists first
    $subscriptionExists = az account list --query "[?id=='$subscriptionId']" --output tsv
    if (-not $subscriptionExists) {
        Write-Output "Error: Subscription '$subscriptionId' not found or you don't have access to it."
        exit
    }

    # Set the subscription context
    az account set --subscription $subscriptionId
    if ($LASTEXITCODE -ne 0) {
        Write-Output "Error setting subscription context."
        exit
    }

    # Check if the resource group exists in this subscription
    $resourceGroupExists = az group exists --name $ResourceGroupName

    if ($resourceGroupExists -eq "true") {
        Write-Output "Found '$ResourceGroupName' in subscription: $subscriptionId"

        # Ask for confirmation before deleting the resource group
        $confirmation = Read-Host "Are you sure you want to delete resource group '$ResourceGroupName' and the resources inside it from this subscription? (Y/N)"

        if ($confirmation -eq 'Y') {
            try {
                Write-Output "Deleting resource group '$ResourceGroupName' from subscription '$subscriptionId'..."
                az group delete --name $ResourceGroupName --yes
                Write-Output "Resource group '$ResourceGroupName' has been successfully deleted from subscription '$subscriptionId'."
            } catch {
                Write-Output "Error deleting resource group: $_"
            }
        } else {
            Write-Output "Resource group deletion cancelled."
        }
    } else {
        Write-Output "Resource group '$ResourceGroupName' was not found in subscription '$subscriptionId'."
    }
}
elseif ($scopeChoice -eq "2") {
    $managementGroupName = Read-Host -Prompt "Enter the management group name"
    if ([string]::IsNullOrWhiteSpace($managementGroupName)) {
        Write-Output "Management group name cannot be empty. Exiting script."
        exit
    }

    # Log in to Azure if not already logged in
    az login

    # Verify the management group exists
    Write-Output "Checking if management group '$managementGroupName' exists..."
    $mgExists = az account management-group show --name $managementGroupName --query "name" --output tsv
    if (-not $mgExists) {
        Write-Output "Error: Management group '$managementGroupName' not found or you don't have access to it."
        exit
    }

    # Get the list of subscriptions under the management group
    $subscriptions = az account management-group subscription show-sub-under-mg --name $managementGroupName --query "[].{Name:displayName}" -o tsv

    # Array to store subscriptions that have the resource group
    $subscriptionsWithResourceGroup = @()

    # First, check which subscriptions have the resource group and list them
    Write-Output "Checking for resource group '$ResourceGroupName' across subscriptions..."
    Write-Output "------------------------------------------------"

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
                Write-Output "Found '$ResourceGroupName' in subscription: $subscription"
                $subscriptionsWithResourceGroup += $subscription
            }
        } catch {
            Write-Output "Error checking subscription '$subscription': $_"
        }
    }

    # If no subscriptions have the resource group, exit
    if ($subscriptionsWithResourceGroup.Count -eq 0) {
        Write-Output "Resource group '$ResourceGroupName' was not found in any subscription under management group '$managementGroupName'."
        exit
    }

    # Ask for confirmation once before deleting all resource groups
    Write-Output "Found resource group '$ResourceGroupName' in $($subscriptionsWithResourceGroup.Count) subscription(s)."
    $confirmation = Read-Host "Are you sure you want to delete resource group '$ResourceGroupName' and the resources inside it from all these subscriptions? (Y/N)"

    if ($confirmation -eq 'Y') {
        Write-Output "Proceeding with deletion..."

        foreach ($subscription in $subscriptionsWithResourceGroup) {
            try {
                # Set the context for the current subscription
                az account set --subscription $subscription

                # Delete the resource group
                Write-Output "Deleting resource group '$ResourceGroupName' from subscription '$subscription'..."
                az group delete --name $ResourceGroupName --yes
                Write-Output "Resource group '$ResourceGroupName' has been successfully deleted from subscription '$subscription'."
            } catch {
                Write-Output "Error deleting from subscription '$subscription': $_"
            }
        }

        Write-Output "Resource group '$ResourceGroupName' has been deleted from all identified subscriptions."
    } else {
        Write-Output "Operation cancelled. No resource groups were deleted."
    }
} else {
    Write-Output "Invalid scope choice. Exiting script."
    exit
}
