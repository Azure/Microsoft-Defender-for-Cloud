
<#  
.SYNOPSIS  
   Microsoft Defender for Cloud - Recommendations Exemption removal script.
.DESCRIPTION  
   This script is purposed to remove Azure Policy exemptions under a subscription.
   It can remove all exemptions under a subscription or single Recommendation exemptions from subscription scope.
   This script can remove all the exemptions for all recommendations in a subscription or one Recommendation exemption - use with care!
.EXAMPLE
  Remove-MDFCPolicyExemptions.md -SubscriptionId {subId} -referenceId {policyReferenceId}
  Remove the exemption for single policy 
  
.EXAMPLE
  Remove-MDFCPolicyExemptions.md -SubscriptionId {subId} -deleteExemptionsFromAllRecommendations
  Remove all the exemptions from a subscription

.PARAMETER subscriptionId
  The subscription Id in context
  
.PARAMETER referenceId
  Recommendation Policy Id to remove its exemption
  To find a Policy reference ID go to Azure Policy, locate the relevant initiative (e.g. Azure Security Benchmark), open it and look for the policy to exempt, find it under Reference ID column.
  
.PARAMETER deleteExemptionsFromAllRecommendations
  Indicate this flag to clear out all the exemptions from the subscription.
  Use with care!

.INPUTS 
    None. You cannot pipe objects to Add-Extension.

.OUTPUTS
    REST API invocation. Only errors will be output.


.NOTES
   It is recommended to list the existing exemptions before running this script by using https://docs.microsoft.com/en-us/rest/api/policy/policy-exemptions/list

.LINK
 This script posted to and discussed at the following locations:
 https://github.com/Azure/Microsoft-Defender-for-Cloud/tree/main/Powershell%20scripts
#>

## 

param (
#---------Parameters---------
#Define scoped to delete
	[Parameter(Mandatory = $true)]
	[string]$subscriptionId,
#Delete all exemptions flag
	[switch]$deleteExemptionsFromAllRecommendations,
#Reference id (optional)
	[string]$referenceId # = "REFERENCE_ID", the policy definition of the assessment. aka "Log Analytics agent health issues should be resolved on your machines" -> resolveLogAnalyticsHealthIssuesMonitoring
)

# Validate parameters
if(!($deleteExemptionsFromAllRecommendations) -AND !($referenceId))
{
	Write-Host "`nPlease asssign the Recommendation reference ID for the exemption you wish to remove.`nIf you want to remove all exemptions in the subscription, pass the ```-deleteExemptionsFromAllRecommendations``` parameter.`n" -ForegroundColor Yellow
	return
}

# Subscription login
$subContext = Get-AzContext
if (!($subContext.Subscription.Id) -OR $subContext.Subscription.Id -ne $subscriptionId)
{
	try 
	{
		Set-AzContext -SubscriptionId $subscriptionId -ErrorAction Stop
	}
	catch
	{
		write-host "`nPlease make sure you logged on to your Azure subscription using Login-AzAccount cmdlet" -ForegroundColor Yellow
	}
}

if ($subContext.Subscription.Id -eq $subscriptionId)
{
	Write-Host "Subscription $subscriptionId was set as the context`n" -ForegroundColor Green
}

#Subscription token
$token = (Get-AzAccessToken).Token

# Removing exemptions
$getExemptionUrl = "https://management.azure.com/subscriptions/$($subscriptionId)/providers/Microsoft.Authorization/policyExemptions?api-version=2020-07-01-preview"
$exemptions = Invoke-RestMethod -Uri $getExemptionUrl -Headers @{ Authorization="Bearer $token" } 
Write-Host "$($exemptions.value.Count) Policy exemptions were found under subscription ID: $subscriptionId.`n" -ForegroundColor Red

$counter =0
foreach($exemption in $exemptions.value)
{
	if (($exemption.properties.policyDefinitionReferenceIds -contains $referenceId) -or $deleteExemptionsFromAllRecommendations)
	{
		$deleteExemptionUrl = "https://management.azure.com/$($exemption.id)?api-version=2020-07-01-preview"
		$res = Invoke-RestMethod -Uri $deleteExemptionUrl -Headers @{ Authorization="Bearer $token" } -Method "Delete"
		$counter = $counter +1
		Write-Host "`"$($exemption.Name)`" exemption deleted from $subscriptionId count: $counter" -ForegroundColor Red 
	} 
}


Write-Host "`nCompleted. $counter exemptions were attempted to delete!"

