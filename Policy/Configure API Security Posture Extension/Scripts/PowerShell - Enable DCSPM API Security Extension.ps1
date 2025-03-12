#Set Subscription Id and endpoint
$subscriptionId = "SubscriptionId"
$uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Security/pricings/CloudPosture?api-version=2023-01-01"

# Set variables for enabling/disabling extensions using "true" to enable and "false" to not enable
$ApiPostureEnabled = "True"

# Construct the request body using the variables
$body = @{
    properties = @{
        pricingTier = "Standard"
        extensions = @(
            @{
                name = "ApiPosture"
                isEnabled = $ApiPostureEnabled
            }
        )
    }
} | ConvertTo-Json -Depth 4

# Fetch the token and set the headers for the request
$token = (Get-AzAccessToken -ResourceUrl https://management.azure.com).Token
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Send the PUT request
$response = Invoke-RestMethod -Method Put -Uri $uri -Headers $headers -Body $body

# Optionally, display the response
$response
