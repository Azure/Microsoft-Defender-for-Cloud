function Get-AccessToken {
    $tenantId = "<ADD>"
    $clientId = "<ADD>"
    $clientSecret = "<ADD>"

    $body = @{
        'grant_type'    = 'client_credentials'
        'client_id'     = $clientId
        'client_secret' = $clientSecret
        'resource'      = 'https://management.azure.com/'
    }

    $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -Method Post -Body $body

    return $tokenResponse.access_token
}

function Onboard-ToDefender {
    param (
        [string]$apimServiceId,
        [string]$apiName
    )
    $apiVersion = "2023-11-15"
    $accessToken = Get-AccessToken

    if (![string]::IsNullOrEmpty($apiName)) {
        $apiUrl = "https://management.azure.com${apimServiceId}/providers/Microsoft.Security/apiCollections/${apiName}?api-version=$apiVersion"
    } else {
        $apiUrl = "https://management.azure.com${apimServiceId}/providers/Microsoft.Security/apiCollections?api-version=$apiVersion"
    }

    Write-Host "Constructed URL: $apiUrl"
    $headers = @{
        'Authorization' = "Bearer $accessToken"
    }
    Invoke-RestMethod -Method Put -Uri $apiUrl -Body "{}" -ContentType "application/json" -Headers $headers
}

$apimApiVersion = "2022-08-01"
$queryResult = az graph query -q "Resources | where type =~ 'Microsoft.ApiManagement/service' | project id, name, resourceGroup, subscriptionId" -o json | ConvertFrom-Json

foreach ($service in $queryResult.data) {
    $serviceName = $service.name
    $resourceGroupName = $service.resourceGroup
    $serviceId = $service.id
    $subscriptionId = $service.subscriptionId

    Write-Host "Processing APIM Service: $serviceName in Resource Group: $resourceGroupName in Subscription: $subscriptionId"

    $apiResponse = az rest --method get --url "https://management.azure.com$serviceId/apis?api-version=$apimApiVersion" | ConvertFrom-Json

    foreach ($api in $apiResponse.value) {
        Write-Host $api | Format-List
        $apiId = $api.id
        $apiName = $api.name -replace ";.*$", "" -replace "-$", ""

        Write-Host "Onboarding API with ID $apiId and Name $apiName to Defender for APIs..."

        $baseApimServiceId = $apiId -replace "/apis/.*$", "" -replace "/$", ""

        Onboard-ToDefender -apimServiceId $baseApimServiceId -apiName $apiName
    }
}
