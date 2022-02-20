#Requires -Modules @{ ModuleName="Az.Resources"; ModuleVersion="5.2.0" }
#Requires -Modules @{ ModuleName="Az.EventHub"; ModuleVersion="1.9.1" }
#Requires -Modules @{ ModuleName="Az.Storage"; ModuleVersion="3.12.0" }
<#  
  .SYNOPSIS  
    This script will create the required resources and configurations to stream alerts from Microsoft Defender for Cloud to 3rd party SIEM.
      
  .DESCRIPTION  
    Streaming Microsoft Defender for Cloud security alerts to external SIEM solutions require setups on both Azure side and the 3rd party SIEM side.
    This script execute the required steps on Azure side and provide the information required to enable the connector on the SIEM side.
    
  .PARAMETER scope
    [mandatory] 
    The scope to apply the continious export policy on

  .PARAMETER subscriptionId
    [mandatory] 
    The Azure subscription id of the subscription the event hub will be created in.

  .PARAMETER resourceGroupName
    [mandatory]
    The resourceGroupName of the resource group the event hub and continious export will be created in.
    If no suce resource group exists the script will create it.

  .PARAMETER eventHubNamespaceName
    [mandatory] 
    The name of the event hub namespace to create.
    
  .PARAMETER eventHubName
    [mandatory] 
    The name of the event hub to create.

  .PARAMETER location
    [mandatory] 
    The desired Azure region location for the resources.

  .PARAMETER siem
    [mandatory] 
    The target SIEM, used to create the required resources for the specific SIEM.
    Current options are: Splunk, QRadar.

  .PARAMETER aadAppName
    The AAD app name to create to support streaming to Splunk.
    Must be passed if $siem=="Splunk"

  .PARAMETER storageName
    The storage account name to create to support streaming to QRadar.
    Must be passed if $siem=="QRadar"

  .EXAMPLE
  .\EnableAlertsStreamingTo3rdPartySiem.ps1 -scope `<Scope>` -subscriptionId `<Subscription Id>` -resourceGroupName `<RG Name>` -eventHubNamespaceName `<New event hub namespace name>` -eventHubName `<New event hub name>` -location `<Location>` -siem `<Splunk / QRadar>` -aadAppName `<New AAD application name>` -storageName `<New storage name>`

  .EXAMPLE
  .\EnableAlertsStreamingTo3rdPartySiem.ps1 -scope '' -subscriptionId 'f4cx1b69-dtgb-4ch6-6y6f-ea2e95373d3b' -resourceGroupName 'DefaultResourceGroup-WEU' -eventHubNamespaceName 'eventHubNamespace' -eventHubName 'eventHub' -location 'Central US' -siem 'Splunk' -aadAppName 'SplunkConnectorApp'

  .EXAMPLE
  .\EnableAlertsStreamingTo3rdPartySiem.ps1 -scope '' -subscriptionId 'f4cx1b69-dtgb-4ch6-6y6f-ea2e95373d3b' -resourceGroupName 'DefaultResourceGroup-WEU' --eventHubNamespaceName 'eventHubNamespace' -eventHubName 'eventHub' -location 'Central US' -siem 'QRadar' -storageName 'qradarconnectorstorage'

  .NOTES
    AUTHOR: Gal Grinblat - MDC ???
    LASTEDIT: January 20, 2022 0.1
      - 0.1 change log: Initial commit

  .LINK
      This script posted to and discussed at the following locations:
      https://github.com/Azure/Azure-Security-Center/tree/master/Powershell%20scripts
#>

# Prerequisites
  # Install-module Az
  # Install-module Az.Resources
  # Install-module Az.EventHub
  # Install-module Az.Storage

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$scope,

    [Parameter(Mandatory)]
    [string]$subscriptionId,

    [Parameter(Mandatory)]
    [string]$resourceGroupName,

    [Parameter(Mandatory)]
    [string]$eventHubNamespaceName,

    [Parameter(Mandatory)]
    [string]$eventHubName,

    [Parameter(Mandatory)]
    [string]$location,

    [Parameter(Mandatory)]
    [ValidateSet("Splunk","QRadar")]$siem,

    [Parameter()]
    [string]$aadAppName,

    [Parameter()]
    [string]$storageName
)

function CreateSplunkRelatedResources {
    param (
        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.EventHub.Models.PSNamespaceAttributes]$eventHubNamespace,

        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.EventHub.Models.PSEventHubAttributes]$eventHub,

        [Parameter(Mandatory)]
        [string]$aadAppName
    )

    # Create AAD app
    Write-Output "Create new AAD app"
    $app = New-AzADApplication -DisplayName $aadAppName

    Write-Debug "Create a service principal for the aad app"
    $servicePrincipal = New-AzADServicePrincipal -ApplicationId $app.AppId

    Write-Debug "Create a new password for the aad app"
    $appCred = New-AzADAppCredential -ApplicationId $app.AppId

    Write-Debug "Give the service principal access to read from the event hub"
    $roleDefinitionId = "a638d3c7-ab3a-418d-83e6-5f17a39d4fde" # Azure Event Hubs Data Receiver
    Write-Debug "Going to give $($servicePrincipal.Id) role definition id $roleDefinitionId on scope $eventHub.Id"
    New-AzRoleAssignment -ObjectId $servicePrincipal.Id -RoleDefinitionId $roleDefinitionId -Scope $eventHub.Id

    Write-Output "Requierd information for Splunk connection:"
    Write-Output "AAD app params:" 
    Write-Output "Client ID: $($app.AppId)"
    Write-Output "Key (Client Secret): $($appCred.SecretText)"
    Write-Output "Tenant ID: $(Get-AzTenant)"
    Write-Output "Event Hub params:"
    Write-Output "Event Hub Namespace(FQDN): $($eventHubNamespace.ServiceBusEndpoint)"
    Write-Output "Event Hub Name: $($eventHub.Name)"
    Write-Output "Consumer Group: $($consumerGroup.Name)"

}

function CreateQRadatRelatedResources {
    param (   
        [Parameter(Mandatory)]
        [string]$resourceGroupName,
    
        [Parameter(Mandatory)]
        [string]$eventHubNamespaceName,
    
        [Parameter(Mandatory)]
        [string]$eventHubName,

        [Parameter(Mandatory)]
        [string]$location,

        [Parameter(Mandatory)]
        [string]$storageName
    )

    Write-Output "Create new Event Hub listen policy for $eventHubName in $eventHubNamespaceName"
    $eventHubListenAccessPolicyName = "ContinuousExportListenPolicy"
    $ListenAuthRule = New-AzEventHubAuthorizationRule -ResourceGroupName $resourceGroupName -NamespaceName $eventHubNamespaceName -EventHubName $eventHubName -AuthorizationRuleName $eventHubListenAccessPolicyName -Rights Listen
    $eventHubConnectionString = Get-AzEventHubKey -ResourceGroupName $resourceGroupName -NamespaceName $eventHubNamespaceName -EventHub $eventHubName -Name $ListenAuthRule.Name | Select-Object PrimaryConnectionString

    Write-Output "Create new storage account"
    $storage = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageName -Location $location -SkuName Standard_LRS
    $storageKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageName)[0].Value
    $storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=' + $storageName + ';AccountKey=' + $storageKey + ';EndpointSuffix=core.windows.net' 


    Write-Output "Requierd information for Qradar connection:"
    Write-Output "Event Hub connection string: $($eventHubConnectionString.PrimaryConnectionString)"
    Write-Output "Storage account connection string: $storageConnectionString"
    Write-Output "Consumer Group: $($consumerGroup.Name)"
}

# Validate params
if ($siem -eq "Splunk")
{
    if ([string]::IsNullOrEmpty($aadAppName))
    {
        Write-Error "When selecting Splunk as the SIEM type the aadAppName parameter is mandatory"
        Return
    }
}

if ($siem -eq "QRadar")
{
  if ([string]::IsNullOrEmpty($storageName))
  {
      Write-Error "When selecting QRadar as the SIEM type the storageName parameter is mandatory"
      Return
  }
}

Set-AzContext -SubscriptionId $subscriptionId -ErrorAction Break
$eventHubSendAccessPolicyName = "ContinuousExportSendPolicy"

# Continious Export section
## Create event hub
Write-Output "Creating the continuous export target event hub..."

Write-Debug "Check if resource group '$resourceGroupName' already exists..."
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ( $notPresent) {
  Write-Debug "Resource group '$resourceGroupName' doesn't exists, creating it."
  $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location
}
else {
  Write-Debug "Resource group already exists."
}

Write-Debug "Creating new Event Hub Namespace '$eventHubNamespaceName'"
$eventHubNamespace = New-AzEventHubNamespace -ResourceGroupName $resourceGroupName -Name $eventHubNamespaceName -Location $location

Write-Debug "Creating new Event Hub $eventHubName in $eventHubNamespaceName"
$eventHub = New-AzEventHub -ResourceGroupName $resourceGroupName -NamespaceName $eventHubNamespaceName -Name $eventHubName -MessageRetentionInDays 1

Write-Debug "Creating new Event Hub send policy for $eventHubName in $eventHubNamespaceName"
$SendAuthRule = New-AzEventHubAuthorizationRule -ResourceGroupName $resourceGroupName -NamespaceName $eventHubNamespaceName -EventHubName $eventHubName -AuthorizationRuleName $eventHubSendAccessPolicyName -Rights Send

## Enable continuous export (by policy)
Write-Output "Creating new continuous export policy"
$policyDef = Get-AzPolicyDefinition -Name cdfcce10-4578-4ecd-9703-530938e4abcb

$PolicyParameterObject = @{
    'resourceGroupName' = $resourceGroupName
    'resourceGroupLocation' = $location
    'eventHubDetails' = $SendAuthRule.Id
    'exportedDataTypes' = @('Security alerts')
    'alertSeverities' = @('High', 'Medium', 'Low')
}

$policyAssignment = New-AzPolicyAssignment -Name "Continuous export policy" -PolicyDefinition $policyDef -Scope $scope -PolicyParameterObject $PolicyParameterObject -Location $location -AssignIdentity
$roleDefinitionIds = $policyDef.Properties.policyRule.then.details.roleDefinitionIds

$retryCount = 0
$policyRoleAssignmentSuccess = $true
do {
  try {
    $roleDefinitionIds | ForEach-Object {
      $roleDefId = $_.Split("/") | Select-Object -Last 1
      Write-Debug "Going to assign role definition id $roleDefId to service principal $($policyAssignment.Identity.PrincipalId) on scope $scope"
      New-AzRoleAssignment -Scope $scope -ObjectId $policyAssignment.Identity.PrincipalId -RoleDefinitionId $roleDefId -ErrorAction Stop
      $policyRoleAssignmentSuccess = $true
      break
    }  
  }
  catch {
    if ($retryCount -gt 3) {
      $policyRoleAssignmentSuccess = $false
      break
    }
    Write-Debug "Failed to assign role difinition, will retry in 5 seconds"
    $retryCount++
    Start-Sleep -Seconds 5
  }
} while ($retryCount -le 3)

if ($policyRoleAssignmentSuccess) {
  $remediationJob = Start-AzPolicyRemediation -PolicyAssignmentId $policyAssignment.PolicyAssignmentId -Name "Initial assignment" -AsJob
}

# 3rd party siem region

Write-Debug "Create new consumer group for event hub: $eventHubName"
$siemConsumerGroupName = "Siem"
$consumerGroup = New-AzEventHubConsumerGroup -ResourceGroupName $resourceGroupName -NamespaceName $eventHubNamespaceName -EventHubName $eventHubName -ConsumerGroupName $siemConsumerGroupName

## Splunk
if ($siem -eq "Splunk") {
    CreateSplunkRelatedResources -eventHubNamespace $eventHubNamespace -eventhub $eventHub -aadAppName $aadAppName
}

## QRadar
else {
    CreateQRadatRelatedResources -resourceGroupName $resourceGroupName -eventHubNamespaceName $eventHubNamespaceName -eventHubName $eventHubName -location $location -storageName $storageName
}

if ($policyRoleAssignmentSuccess) {
  $remediationJob | Wait-Job
  $remediation = $remediationJob | Receive-Job
  if ($remediation.ProvisioningState -ne "Succeeded")
  {
      Write-Warning "The policy assignment failed"
  }
}
else {
  Write-Error "Failed to assign role difinition to the continuous export policy, the policy doesn't have the required permissions to remediate."
  Write-Error "To fix the role assignment try running the following command(s):"
  $roleDefinitionIds | ForEach-Object {
    $roleDefId = $_.Split("/") | Select-Object -Last 1
    Write-Error "New-AzRoleAssignment -Scope $scope -ObjectId $policyAssignment.Identity.PrincipalId -RoleDefinitionId $roleDefId"
  }
}


