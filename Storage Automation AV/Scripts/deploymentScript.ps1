$Location = "location"
$ResourceGroupName = "resource-group-name"
$SubscriptionID = "subscription-id"

az login

az group create `
    --location $Location `
    --name $ResourceGroupName `
    --subscription $SubscriptionID

az deployment group create `
    --subscription $SubscriptionID `
    --name "AutomationAntivirusForStorageTemplate" `
    --resource-group $ResourceGroupName `
    --template-file "../ARM_template/AutomationAntivirusForStorageTemplate.json"`
    --parameters "../ARM_template/AutomationAntivirusForStorageTemplate.parameters.json"

