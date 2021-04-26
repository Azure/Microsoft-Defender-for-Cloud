param (
    $location,
    $resourceGroupName,
    $subscriptionID,
    $armTemplateFile = "$PSScriptRoot/../ARM_template/AutomationAntivirusForStorageTemplate.json",
    $armTemplateParametersFile = "$PSScriptRoot/../ARM_template/AutomationAntivirusForStorageTemplate.json"
)

az login

az group create `
    --location $location `
    --name $resourceGroupName `
    --subscription $subscriptionID

az deployment group create `
    --subscription $subscriptionID `
    --name "AutomationAntivirusForStorageTemplate" `
    --resource-group $resourceGroupName `
    --template-file $armTemplateFile `
    --parameters $armTemplateParametersFile

