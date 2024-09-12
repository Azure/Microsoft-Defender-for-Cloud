param (
    [string]$FilePath
)

# Function to print error and exit script
function Throw-Error {
    param (
        [string]$ErrorMessage
    )
    Write-Error $ErrorMessage
    exit 1
}

Write-Output "Starting script execution."

# Check if the file path is provided
Write-Output "Checking if file path is provided."
if (-not $FilePath) {
    Throw-Error "Error: No file path specified. Please provide the path to the subscription file."
}
Write-Output "File path provided: $FilePath"

# Check if the file exists
Write-Output "Checking if the specified file exists."
if (-not (Test-Path -Path $FilePath)) {
    Throw-Error "Error: The specified file '$FilePath' does not exist. Please provide a valid file path."
}
Write-Output "File exists: $FilePath"

# Ask the customer if they want to enable the feature
$isEnabled = Read-Host "Do you want to enable the AI Prompt Evidence feature? Enter 'True' or 'False'"

# Authenticate with Azure using Azure CLI
Write-Output "Authenticating with Azure CLI."
az login

# Read the subscriptions from the file
Write-Output "Reading subscriptions from the file."
$subscriptions = Get-Content -Path $FilePath
Write-Output "Subscriptions read: $($subscriptions -join ', ')"

foreach ($subscription in $subscriptions) {
    try {
        Write-Output "Setting context to subscription: $subscription"
        # Set the context to the current subscription
        az account set --subscription $subscription

        Write-Output "Setting security pricing for subscription: $subscription"
        # Set the security pricing tier to standard for AI
        az security pricing create -n AI --tier standard --extensions name=AIPromptEvidence isEnabled=$isEnabled

        Write-Output "Successfully set security pricing for subscription: $subscription"
    } catch {
        Write-Error "Failed to set security pricing for subscription: $subscription"
        Write-Error $_.Exception.Message
    }
}

Write-Output "Script execution completed."
