# Integration Settings Scripts

- [Overview](#overview)
- [get-integration-report](#get-integration-report)
- [enable-integration-settings](#enable-integration-settings)

## Overview
These scripts will allow you to report and update integration settings in Defender for Cloud for multiple subscriptions. 

## get-integration-report

get-integration-report.ps1 script will report on:
- Defender for Servers Plan
- Defender for Cloud Apps Integration
- Defender for Endpoint Integration
- Defender for Endpoint Unified Agent
- Defender for Endpoint: Exclude Linux Servers Public Preview Flag
- Sentinel Bi-Directional Alert Sync Settings

### Running the Script

```powershell
# Get all subscription integration settings for the currently connected Tenant
$settings = .\get-integration-report.ps1
$settings | Export-CSV integration-settings.csv
```

```powershell
Get all subscription integration settings for a specific Tenant
$settings = .\get-integration-report.ps1 -TenantId 'c94dffc7-2dd9-4750-a3de-a160ddd68c90'
$settings | Export-CSV integration-settings.csv
```

## enable-integration-settings

enable-integration-settings.ps1 will update:
- Defender for Servers Plan
- Defender for Cloud Apps Integration
- Defender for Endpoint Integration
- Defender for Endpoint Unified Agent
- Defender for Endpoint: Exclude Linux Servers Public Preview Flag
- Sentinel Bi-Directional Alert Sync Settings

### Default Settings
> The script will impose the following default settings unless specified

| Feature | Setting |
| ------- | ------- |
| Defender for Servers Plan | Current Subscription Setting |
| Defender for Cloud Apps Integration | Enabled |
| Defender for Endpoint Integration | Enabled |
| Defender for Endpoint Unified Agent | Enabled |
| Defender for Endpoint: Exclude Linux Servers Public Preview Flag | Disabled |
| Sentinel Bi-Directional Alert Sync Settings | Enabled |

### Running the Script

```powershell
# Enable with all reccomended settings: Defender for Servers current plan, Defender for Endpoint Integration, Defender for Cloud Apss Integration, Unified Agent, Include Linux Servers
.\enable-integration-settings.ps1 -subscriptionId 'c94dffc7-2dd9-4750-a3de-a160ddd68c90'
```

```powershell
# Enable with all reccomended settings on multiple subscriptions
Get-AzSubscription | % {.\enable-integration-settings.ps1 -subscriptionId $_.id}
```

```powershell
#  Enable with all reccomended settings and Defender for Servers P1
.\enable-integration-settings.ps1 -subscriptionId 'c94dffc7-2dd9-4750-a3de-a160ddd68c90' -DefenderforServersPlan 'P1'
``` 
