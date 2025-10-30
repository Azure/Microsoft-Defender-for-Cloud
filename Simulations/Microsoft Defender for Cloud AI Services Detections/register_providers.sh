#!/bin/bash

# Array of resource providers to register
providers=(
    "Microsoft.Storage"
    "Microsoft.KeyVault"
    "Microsoft.Insights"
    "Microsoft.ManagedIdentity"
    "Microsoft.CognitiveServices"
    "Microsoft.MachineLearningServices"
    "Microsoft.Authorization"
    "Microsoft.OperationalInsights"
)

# Function to check and wait for provider registration
register_provider() {
    local provider=$1
    echo "Checking registration status for $provider..."
    
    # Get the current registration state
    local state
    state=$(az provider show --namespace "$provider" --query "registrationState" -o tsv 2>/dev/null)
    
    if [ "$state" == "Registered" ]; then
        echo "$provider is already registered."
    else
        echo "Starting registration for $provider..."
        # Start provider registration in the background, suppress errors
        az provider register --namespace "$provider" >/dev/null 2>&1 &
        local pid=$!
        
        # Poll for registration completion
        while true; do
            state=$(az provider show --namespace "$provider" --query "registrationState" -o tsv 2>/dev/null)
            if [ "$state" == "Registered" ]; then
                echo "$provider successfully registered."
                break
            elif [ "$state" == "Registering" ]; then
                echo "$provider is still registering, waiting..."
                sleep 5 # Wait 5 seconds before checking again
            else
                echo "Warning: Failed to register $provider, registration state is $state."
                break
            fi
        done
        # Ensure the background job is complete
        wait "$pid" 2>/dev/null
    fi
}

# Main execution
echo "Starting resource provider registration in parallel..."

# Array to store background job PIDs
pids=()

# Loop through providers and start registration in background
for provider in "${providers[@]}"; do
    register_provider "$provider" &
    pids+=($!)
done

# Wait for all background jobs to complete
for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null
done

echo "Provider registration process completed."
