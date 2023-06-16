    <#
    .SYNOPSIS
        Enable Defender for Cloud cloud posture plan with containers related features.

    .DESCRIPTION
        A longer description.

    .PARAMETER SubscriptionsListFile
        Path to file containing subscriptions list.
        Subscriptions expected to be separated by new line

    .EXAMPLE
        onboard.ps1 subscriptions.txt
    #>

param(
    $SubscriptionsListFile
)

function main()
{
    az login --use-device-code

    $regex = ''
    foreach($line in Get-Content -Path $SubscriptionsListFile) 
    {
        if($line -match $regex)
        {
            handleSubscription $line
        }
    }
}

function handleSubscription($subscription)
{
    echo "Handling subscription $subscription"
    
    # Account set
    az account set -s $line
    
    # Call Pricing API
    $auth = az account get-access-token --output json | ConvertFrom-Json
    $token = "$($auth.tokenType) $($auth.accessToken)"
    enableMdcPricing $subscription $token
    
    echo "Done for subscription $subscription"
}

function enableMdcPricing($subscription, $token)
{
    $url = "https://management.azure.com/subscriptions/$subscription/providers/Microsoft.Security/pricings/cloudposture/?api-version=2023-01-01"
    
    $body = "{`"properties`":{`"pricingTier`":`"Standard`",`"extensions`":[{`"name`":`"AgentlessDiscoveryForKubernetes`",`"isEnabled`":`"True`"},{`"name`":`"ContainerRegistriesVulnerabilityAssessments`",`"isEnabled`":`"True`"}]}}"

    $headers = @{
        "Accept" = "application/json"
        "Content-Type" = "application/json"
        "Authorization" = $token
    }
    
    # Invoke
    $response = Invoke-RestMethod -Uri $url -Method 'PUT' -Body $body -Headers $headers
}

main
