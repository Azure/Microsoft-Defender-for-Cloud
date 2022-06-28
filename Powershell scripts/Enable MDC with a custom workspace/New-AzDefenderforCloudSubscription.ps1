#Requires -Modules az.security
#Requires -Modules az.monitoringsolutions

# Define the Params
Param(
    $SubscriptionId    = '525c7f2e-XXXX-XXXX-XXXX-384e05b9e30f',
    $ResourceGroupName = 'Demo_analytics',
    $WorkSpaceName     = 'DemoWorkSpaceName',
    $tenantID          = '525c7f2e-XXXX-XXXX-XXXX-384e05b9e30f'
)

Connect-AzAccount -Tenant $tenantID

# Set the context of the script to apply only to the chosen subsctiption
$Context  = Set-AzContext -SubscriptionId $SubscriptionId

Register-AzResourceProvider -ProviderNamespace 'Microsoft.Security'

#region Enable Defender for Cloud Plans

# Define the Defender plans to enable
# You could choose from the list
<# Defender Plan List
VirtualMachines              
SqlServers                   
AppServices                  
StorageAccounts              
SqlServerVirtualMachines     
KubernetesService            
ContainerRegistry            
KeyVaults                    
Dns                          
Arm                          
OpenSourceRelationalDatabases
CosmosDbs                    
Containers
#>
$DefenderPlans = @(
                    'Arm',
                    'KeyVaults', 
                    'VirtualMachines', 
                    'StorageAccounts', 
                    'SqlServerVirtualMachines', 
                    'Dns'
                    )

# Get a list of the free plans currently deployed on the subscription
$SecurityPricing = Get-AzSecurityPricing | Where-Object {($_.name -in $DefenderPlans) -and ($_.PricingTier -eq 'Free')}

# Enable the standard plan for each of the Defender plans chosen above
foreach ($DefenderPlan in $SecurityPricing){
        Set-AzSecurityPricing -Name $DefenderPlan.Name -PricingTier "Standard" 
}

#endregion

#region Configure Environment Settings for the Subscription in the Defender for Cloud 

# Set the Subscription to send data to a specific workspace
$WorkspaceSettingName = "default"
Set-AzSecurityWorkspaceSetting -Name $WorkspaceSettingName `
    -Scope "/subscriptions/$SubscriptionId" `
    -WorkspaceId "/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupName/providers/microsoft.operationalinsights/workspaces/$WorkSpaceName"

# Enable Auto Provisioning
Set-AzSecurityAutoProvisioningSetting -Name $WorkspaceSettingName -EnableAutoProvision

#endregion

#region Enable the Log Analytics Workspace Solution

$Workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkSpaceName

$SolutionTypes = @('Security', 'SecurityCenterFree')

foreach ($SolutionType in $SolutionTypes) {
    New-AzMonitorLogAnalyticsSolution -ResourceGroupName $ResourceGroupName `
                                  -Location $workspace.Location `
                                  -WorkspaceResourceId $WorkSpace.ResourceId `
                                  -Type $SolutionType
}

#endregion

#region Set Security event collection tier

# Create the request header using your bearer token from your session
$tenantID = $Context.Tenant.Id
$tokenCache = Get-AzAccessToken -TenantId $tenantID
$requestHeader = @{
    "Authorization" = "{0} {1}" -f $tokenCache.Type, $tokenCache.Token
    "Content-Type"   = "application/json"
}

# Choose: "None", "Minimal", "Recommended" (for "Common") or "All" (for "All Events")
$SecurityEventCollectionTier = "Recommended"

# Create the Body
$Properties = @{Tier = $SecurityEventCollectionTier}
$Body       = @{kind = "SecurityEventCollectionConfiguration"}
$Body.add("properties", $Properties)
$jsonBody = $Body | ConvertTo-Json

# Generate the request URI  
$RestURI = 'https://management.azure.com/subscriptions/{0}/resourcegroups/{1}/providers/Microsoft.OperationalInsights/Workspaces/{2}/datasources/SecurityEventCollectionConfiguration?api-version=2015-11-01-preview' -f $SubscriptionId, $ResourceGroupName, $WorkSpaceName

Invoke-RestMethod -Uri $RestURI -Method Put -Body $jsonBody -Headers $requestHeader

#endregion




# Update JUT network access policy Set-AzJitNetworkAccessPolicy


