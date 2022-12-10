
# Enable Azure Monitor Agent for Defender for Servers

## Overview
This script will enable auto provisioning of the Azure Monitor Agent for Defender for Servers

> This script will not configure additional security event collection. You will need to create a seperate data collection rule if addtional security event collection is required. 

## Examples

```powershell
# Enable Auto-provisioning configuration for AMA with the default workspace

.\enable-amaDefender4Servers.ps1 -subscriptionId 'ada06e68-4678-4210-443a-c6cacebf41c5'
	
# Enable Auto-provisioning configuration for AMA with a custom workspace

.\enable-amaDefender4Servers.ps1 -subscriptionId 'ada06e68-4678-4210-443a-c6cacebf41c5' -workspaceResourceId '/subscriptions/11c61180-d5dc-4a02-b2da-1f06b8245691/resourcegroups/sentinel-prd/providers/microsoft.operationalinsights/workspaces/sentinel-prd'

```
