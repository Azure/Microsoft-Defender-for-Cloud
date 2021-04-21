$Location = "location"
$ResourceGroupName = "resource-group-name"
$SubscriptionID = "subscription-id"
$ArmTemplatFile = "$PSScriptRoot/../ARM_template/AutomationAntivirusForStorageTemplate.json"
$ArmTemplatParametersFile = "$PSScriptRoot/../ARM_template/AutomationAntivirusForStorageTemplate.json"
az login

az group create `
    --location $Location `
    --name $ResourceGroupName `
    --subscription $SubscriptionID

az deployment group create `
    --subscription $SubscriptionID `
    --name "AutomationAntivirusForStorageTemplate" `
    --resource-group $ResourceGroupName `
    --template-file $ArmTemplatFile `
    --parameters $ArmTemplatParametersFile

