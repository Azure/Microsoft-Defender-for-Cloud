# EnableAlertsStreamingTo3rdPartySiem.ps1
  This script will create the required resources and configurations to stream alerts from Microsoft Defender for Cloud to 3rd party SIEM.

## Description
  Streaming Microsoft Defender for Cloud security alerts to external SIEM solutions require setups on both Azure side and the 3rd party SIEM side.
  This script execute the required steps on Azure side and provide the information required to enable the connector on the SIEM side.


### Usage
  **PARAMETER** ***scope***  
  [mandatory]  
  The scope to apply the continious export policy on.

**PARAMETER** ***subscriptionId***  
  [mandatory]  
  The Azure subscription id of the subscription the event hub will be created in.

**PARAMETER** ***resourceGroupName***  
  [mandatory]  
  The resourceGroupName of the resource group the event hub and continious export will be created in.
  If no suce resource group exists the script will create it.

**PARAMETER** ***eventHubNamespaceName***  
  [mandatory]  
  The name of the event hub namespace to create.
  
**PARAMETER** ***eventHubName***  
  [mandatory]  
  The name of the event hub to create.

**PARAMETER** ***location***  
  [mandatory]  
  The desired Azure region location for the resources.

**PARAMETER** ***siem***  
  [mandatory]  
  The target SIEM, used to create the required resources for the specific SIEM.
  Current options are: Splunk, QRadar.

**PARAMETER** ***aadAppName***  
  The AAD application name to create to support streaming to Splunk.
  Must be passed if $siem=="Splunk"

**PARAMETER** ***storageName***  
  The storage account name to create to support streaming to QRadar.
  Must be passed if $siem=="QRadar"

## Examples
Syntax:  
   > .\EnableAlertsStreamingTo3rdPartySiem.ps1 -scope `<Scope>` -subscriptionId `<Subscription Id>` -resourceGroupName `<RG Name>` -eventHubNamespaceName `<New event hub namespace name>` -eventHubName `<New event hub name>` -location `<Location>` -siem `<Splunk / QRadar>` -aadAppName `<New AAD application name>` -storageName `<New storage name>`

Full command:  
Splunk
```powershell
   .\EnableAlertsStreamingTo3rdPartySiem.ps1 -scope '' -subscriptionId 'f4cx1b69-dtgb-4ch6-6y6f-ea2e95373d3b' -resourceGroupName 'DefaultResourceGroup-WEU' -eventHubNamespaceName 'eventHubNamespace' -eventHubName 'eventHub' -location 'Central US' -siem 'Splunk' -aadAppName 'SplunkConnectorApp'
```  
QRadar
```powershell
   .\EnableAlertsStreamingTo3rdPartySiem.ps1 -scope '' -subscriptionId 'f4cx1b69-dtgb-4ch6-6y6f-ea2e95373d3b' -resourceGroupName 'DefaultResourceGroup-WEU' --eventHubNamespaceName 'eventHubNamespace' -eventHubName 'eventHub' -location 'Central US' -siem 'QRadar' -storageName 'qradarconnectorstorage'
```  
Note: The values in the example above are fake. Any attempt to use the example as is will fail.
### Prerequisites

##### Required PowerShell modules
  Install-module Az  
  Install-module Az.Resources
  Install-module Az.EventHub
  Install-module Az.Storage

##### Credits
   AUTHOR: Gal Grinblat, Microsoft Defender for Cloud  
   LASTEDIT: January 27, 2022 1.0  
    - 1.0 change log: Initial commit
    
##### Link
  This script posted and discussed at the folllowing location:  
  [https://github.com/Azure/Azure-Security-Center/tree/master/Powershell scripts](https://github.com/Azure/Azure-Security-Center/tree/master/Powershell%20scripts)