param (
    $location,
    $resourceGroupName,
    $subscriptionID,
    $armTemplateFile = "$PSScriptRoot/../ARM_template/AntivirusAutomationForStorageTemplate.json",
    $armTemplateParametersFile = "$PSScriptRoot/../ARM_template/AntivirusAutomationForStorageTemplate.json"
)

az login

az group create `
    --location $location `
    --name $resourceGroupName `
    --subscription $subscriptionID

az deployment group create `
    --subscription $subscriptionID `
    --name "AntivirusAutomationForStorageTemplate" `
    --resource-group $resourceGroupName `
    --template-file $armTemplateFile `
    --parameters $armTemplateParametersFile

