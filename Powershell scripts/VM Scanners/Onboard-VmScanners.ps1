param(
[Parameter(Mandatory = $False)] $exclusionTags=@{}
)

$objectid= (az ad sp list --display-name "Microsoft Defender for Cloud Servers Scanner Resource Provider" --query [].objectId --output tsv)
$exclusionTagsJson = ($exclusionTags | ConvertTo-Json -Compress).Replace('"', '\"')

$vmScannerRgName = "VmScannerResourceGroup"
$vmScannerRgLocation = "westeurope"
az group create -l $vmScannerRgLocation -n $vmScannerRgName

az feature register --namespace Microsoft.Security --name VmScanners.Preview
az provider register --namespace "Microsoft.Security" --wait

az deployment sub create --location "West Europe" --template-uri "https://raw.githubusercontent.com/Azure/Microsoft-Defender-for-Cloud/main/Powershell%20scripts/VM%20Scanners/onboardingTemplate" --parameters vmScannerRgName=$vmScannerRgName principalId=$objectid exclusionTags=$exclusionTagsJson vmScannerRgLocation=$vmScannerRgLocation 
