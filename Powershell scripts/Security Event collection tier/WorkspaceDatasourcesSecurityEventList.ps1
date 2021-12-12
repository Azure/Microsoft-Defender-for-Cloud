#------------------------------------------------------------------------
# Script to Get Windows securityeventconfig on all workspaces in a Tenant
#------------------------------------------------------------------------

$Resultlist = @()

$subIdList=Get-AzSubscription


#Security Event Collection Tiers -  "None", "Minimal", "Recommended" or "All"
ForEach ($subId in $subIdList) 
{

#Set-AzContext -SubscriptionId $subId.ID
$context = Set-AzContext -SubscriptionId $subId.ID

$tenantId = (Get-AZContext).Tenant.Id
$tokenCache =  Get-AzAccessToken
$accessToken = $tokenCache[0].Token
$requestHeader = @{
  "Authorization" = "Bearer " + $accessToken
  "Content-Type" = "application/json"
}
$LAWlist= Get-AzOperationalInsightsWorkspace

    ForEach ($LAW in $LAWlist){
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"


	$workspaceResourceGroup	= 	$LAW.ResourceGroupName
	$subscriptionId = $subId.ID
	$workspaceName	= $LAW.Name
	$RESTURI = "https://management.azure.com/subscriptions/" + $subscriptionId + `
    "/resourcegroups/" + $workspaceResourceGroup + "/providers/Microsoft.OperationalInsights/workspaces/" + $workspaceName + `
    "/datasources/SecurityEventCollectionConfiguration?api-version=2020-08-01"
	
	$securityeventconfig=Invoke-RestMethod -Uri $RESTURI -Method GET -Headers $requestHeader

	$tmpObj = New-Object -TypeName PSObject
	$tmpObj | Add-Member -MemberType Noteproperty -Name "LAW_Name" -Value $LAW.Name
	$tmpObj | Add-Member -MemberType Noteproperty -Name "SubscriptionID" -Value $subId.ID
	$tmpObj | Add-Member -MemberType Noteproperty -Name "ResourceGroupName" -Value $LAW.ResourceGroupName
	$tmpObj | Add-Member -MemberType Noteproperty -Name "Datasource" -Value "SecurityEventCollectionConfiguration"
	$tmpObj | Add-Member -MemberType Noteproperty -Name "DatasourceTier" -Value   $securityeventconfig.properties.tier
	$Resultlist += $tmpObj
			
    }
     
}

$Csvname= $subId.TenantId+"-SecurityEventCollectionConfiguration.csv"

$Resultlist | Export-Csv -Path $Csvname -NoTypeInformation
