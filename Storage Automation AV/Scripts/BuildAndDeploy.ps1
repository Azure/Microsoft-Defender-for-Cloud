param (
    $sourceCodeContainerName = "release-container",
    $sourceCodeStorageAccountName = "storage-account-name",
    $targetContainerName = "upload-container",
    $targetStorageAccountName = "storage-with-antivirus",
    $targetResourceGroup = "resource-group-name",
    $subscriptionID = "subscription-id",
    $deploymentResourceGroupName = "resource-group-name",
    $deploymentResourceGroupLocation = "location",
    $vmUserName = "username",
    [SecureString] $vmPassword = "password"
)


$ScanHttpServerRoot = "$PSScriptRoot\..\ScanHttpServer"
$ScanHttpServerZipPath = "$ScanHttpServerRoot\ScanHttpServer.Zip"
$VMInitScriptPath = "$ScanHttpServerRoot\VMInit.ps1"

$ScanUploadedBlobRoot = "$PSScriptRoot\..\ScanUploadedBlobFunction"
$ScanUploadedBlobZipPath = "$ScanUploadedBlobRoot\ScanUploadedBlobFunction.zip"


az login

# Zip ScanHttpServer code 
Write-Host Zip ScanHttpServer code
$compress = @{
    Path            = "$ScanHttpServerRoot\*.cs", "$ScanHttpServerRoot\*.csproj", "$ScanHttpServerRoot\*.ps1"
    DestinationPath = $ScanHttpServerZipPath
}
Compress-Archive @compress -Update
Write-Host ScanHttpServer zipped successfully

# prepare ScanUploadedBlob Function code
Write-Host Build ScanUploadedBlob
dotnet publish $ScanUploadedBlobRoot\ScanUploadedBlobFunction.csproj -c Release -o $ScanUploadedBlobRoot/out
Write-Host Build ScanUploadedBlob
Write-Host Zip ScanUploadedBlob code
Compress-Archive -Path $ScanUploadedBlobRoot\out\* -DestinationPath $ScanUploadedBlobZipPath -Update
Write-Host ScanUploadedBlob zipped successfully

# Uploading ScanHttpServer code 
Write-Host Uploading Files
Write-Host Creating container if not exists
az storage container create `
    --name $sourceCodeContainerName `
    --account-name $sourceCodeStorageAccountName `
    --subscription $subscriptionID `
    --auth-mode login `
    --public-access blob

$ScanHttpServerBlobName = "ScanHttpServer.zip"
az storage blob upload `
    --file $ScanHttpServerZipPath `
    --name $ScanHttpServerBlobName `
    --container-name $sourceCodeContainerName `
    --account-name $sourceCodeStorageAccountName `
    --subscription $subscriptionID `
    --auth-mode login

$ScanHttpServerUrl = az storage blob url `
    --name $ScanHttpServerBlobName `
    --container-name $sourceCodeContainerName `
    --account-name $sourceCodeStorageAccountName `
    --subscription $subscriptionID `
    --auth-mode login


$ScanUploadedBlobFubctionBlobName = "ScanUploadedBlobFunction.zip"
az storage blob upload `
    --file $ScanUploadedBlobZipPath `
    --name $ScanUploadedBlobFubctionBlobName `
    --container-name $sourceCodeContainerName `
    --account-name $sourceCodeStorageAccountName `
    --subscription $subscriptionID `
    --auth-mode login

$ScanUploadedBlobFubctionUrl = az storage blob url `
    --name $ScanUploadedBlobFubctionBlobName `
    --container-name $sourceCodeContainerName `
    --account-name $sourceCodeStorageAccountName `
    --subscription $subscriptionID `
    --auth-mode login

$VMInitScriptBlobName = "VMInit.ps1"
az storage blob upload `
    --file $VMInitScriptPath `
    --name $VMInitScriptBlobName `
    --container-name $sourceCodeContainerName `
    --account-name $sourceCodeStorageAccountName `
    --subscription $subscriptionID `
    --auth-mode login
    
$VMInitScriptUrl = az storage blob url `
    --name $VMInitScriptBlobName `
    --container-name $sourceCodeContainerName `
    --account-name $sourceCodeStorageAccountName `
    --subscription $subscriptionID `
    --auth-mode login

Write-Host $ScanHttpServerUrl
Write-Host $ScanUploadedBlobFubctionUrl
Write-Host $VMInitScriptUrl

az group create `
    --location $deploymentResourceGroupLocation `
    --name $deploymentResourceGroupName `
    --subscription $subscriptionID

az deployment group create `
    --subscription $subscriptionID `
    --name "AutomationAntivirusForStorageTemplate" `
    --resource-group $deploymentResourceGroupName `
    --template-file "$PSScriptRoot/../ARM_template/AutomationAntivirusForStorageTemplate.json"`
    --parameters AutoAVAntivirusHttpServerUrl=$ScanHttpServerUrl `
    --parameters AutoAVAntivirusFunctionZipUrl=$ScanUploadedBlobFubctionUrl `
    --parameters vmInitScriptUrl=$VMInitScriptUrl `
    --parameters targetBlobContainerName=$targetContainerName `
    --parameters targetStorageAccountName=$targetStorageAccountName `
    --parameters targetStorageAccountResourceGroup=$targetResourceGroup `
    --parameters targetStorageAccountSubscriptionID=$subscriptionID `
    --parameters vmAdminUsername=$vmUserName `
    --parameters vmAdminPassword=$vmPassword