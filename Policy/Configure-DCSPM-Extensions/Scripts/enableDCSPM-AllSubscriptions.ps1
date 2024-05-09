# Authenticate to Azure
Login-AzAccount

# Fetch all Azure subscriptions
$subscriptions = get-azsubscription

foreach ($subscription in $subscriptions) {

    # Select the current subscription
    Set-AzContext -SubscriptionId $subscription.Id

    # Define the endpoint and body for each subscription
    $uri = "https://management.azure.com/subscriptions/$($subscription.Id)/providers/Microsoft.Security/pricings/CloudPosture?api-version=2023-01-01"

    $body = @{
        properties = @{
            pricingTier = "Standard"
            extensions = @(
                @{
                    name = "AgentlessVmScanning"
                    isEnabled = "True"
                },
                @{
                    name = "AgentlessDiscoveryForKubernetes"
                    isEnabled = "True"
                },
                @{
                    name = "SensitiveDataDiscovery"
                    isEnabled = "True"
                },
                @{
                    name = "ContainerRegistriesVulnerabilityAssessments"
                    isEnabled = "True"
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

    # Send the PUT request for the current subscription
    $response = Invoke-RestMethod -Method Put -Uri $uri -Headers $headers -Body $body

    # Optionally, display the response for each subscription
    Write-Host "Response for subscription $($subscription.Id):"
    Write-Output $response
}
