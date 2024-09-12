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

# Ensure the Azure CLI is installed
Write-Output "Checking if Azure CLI is installed."
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Throw-Error "Error: Azure CLI (az) is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli."
}
Write-Output "Azure CLI is installed."

# Authenticate with Azure
Write-Output "Authenticating with Azure."
az login

# Read the subscriptions and their corresponding enable/disable flags from the file
Write-Output "Reading subscriptions and isEnabled flags from the CSV file."
$subscriptions = Import-Csv -Path $FilePath -Delimiter ',' -Header "subscriptionId", "isEnabled"

if ($subscriptions.Count -eq 0) {
    Throw-Error "Error: No subscriptions found in the specified file."
}

foreach ($entry in $subscriptions) {
    $subscriptionId = $entry.'subscriptionId'
    $isEnabled = $entry.'isEnabled'

    if (-not $subscriptionId) {
        Write-Error "Error: SubscriptionId is missing in one of the entries."
        continue
    }

    try {
        Write-Output "Setting context to subscription: $subscriptionId"
        # Set the context to the current subscription
        az account set --subscription $subscriptionId

        Write-Output "Setting security pricing for subscription: $subscriptionId"
        # Set the security pricing tier to standard for AI with the provided isEnabled value
        az security pricing create -n AI --tier standard --extensions name=AIPromptEvidence isEnabled=$isEnabled

        Write-Output "Successfully set security pricing for subscription: $subscriptionId with isEnabled=$isEnabled"
    } catch {
        Write-Error "Failed to set security pricing for subscription: $subscriptionId"
        Write-Error $_.Exception.Message
    }
}

Write-Output "Script execution completed."
