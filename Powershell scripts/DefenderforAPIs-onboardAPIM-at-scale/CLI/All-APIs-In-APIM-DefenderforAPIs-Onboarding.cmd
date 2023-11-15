onboard_to_defender() {
    local apimServiceId=$1
    local apiName=$2
    local apiVersion="2023-11-15"
    apiUrl="https://management.azure.com${apimServiceId}/providers/Microsoft.Security/apiCollections/${apiName}?api-version=${apiVersion}"
    echo "Constructed URL: $apiUrl"

    # Make the PUT request
    az rest --method put --url "$apiUrl" --body "{}" --headers "Content-Type=application/json"
}

apimApiVersion="2022-08-01"
subscriptionId="<SubId>"
apimServiceName="<APIMServiceName>"

# Query using Azure Resource Graph to get a specific APIM service by name within a subscription
queryResult=$(az graph query -q "Resources | where type =~ 'Microsoft.ApiManagement/service' and name == '$apimServiceName' and subscriptionId == '$subscriptionId' | project id, name, resourceGroup, subscriptionId" -o json)

# Parse the JSON and iterate over the APIM service
echo "$queryResult" | jq -c '.data[]' | while read service; do
    serviceName=$(echo $service | jq -r '.name')
    resourceGroupName=$(echo $service | jq -r '.resourceGroup')
    serviceId=$(echo $service | jq -r '.id')
    subscriptionId=$(echo $service | jq -r '.subscriptionId')

    echo "Processing APIM Service: $serviceName in Resource Group: $resourceGroupName in Subscription: $subscriptionId"

    # Get the API collections for the APIM service
    apiResponse=$(az rest --method get --url "https://management.azure.com${serviceId}/apis?api-version=$apimApiVersion")

    # Parse the JSON and iterate over the API collections
    echo "$apiResponse" | jq -c '.value[]' | while read api; do
        apiId=$(echo $api | jq -r '.id')
        apiName=$(echo $api | jq -r '.name')
        echo "Onboarding API with ID $apiId and Name $apiName to Defender for APIs..."

        # Extract the base APIM service ID
        baseApimServiceId="${apiId%/apis/*}"

        onboard_to_defender "$baseApimServiceId" "$apiName"
    done
done
