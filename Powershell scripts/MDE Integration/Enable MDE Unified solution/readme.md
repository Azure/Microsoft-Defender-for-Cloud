# Microsoft Defender for Servers - Enable MDE Unified Solution integration for Windows Server 2012 R2 and 2016 machines

**Author: Tom Janetscheck**

## Description

In spring 2022, we added Microsoft Defender for Endpoint (MDE) Unified Solution integration supportto Microsoft Defender for Cloud. In order to avoid breaking changes during the preview, we added an activation option for this integration so customers can select if they want to upgrade MDE to unified solution in subscriptions that have existed before this release and which already had MDE integration enabled.

[This script](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Powershell%20scripts/MDE%20Integration/Enable%20MDE%20Unified%20solution/Enable-UnifiedMDE.ps1) has been created to enable MDE Unified Solution integration at scale across all subscriptions within your Tenant. When running the script, it will ask you to enter a Tenant ID and if you want to enable MDE on all subscriptions (including those that don't have the MDE integration enabled at all), or only add MDE Unified Solution integration on subscriptions that already have MDE integration enabled.

You can learn more about MDE unified solution integration with Microsoft Defender for Cloud in [this blog](https://techcommunity.microsoft.com/t5/microsoft-defender-for-cloud/defender-for-servers-plan-2-now-integrates-with-defender-for/ba-p/3527534).

### Prerequisites

- You need to run the script with a user account that has **Security Admin** access rights on all subscriptions you want to enable MDE integration on.
- Make sure to use the latest version of the [Az.Security PowerShell module](https://docs.microsoft.com/powershell/module/az.security).
- In order to allow Defender for Cloud to deploy and integrate MDE, you need to enable one of the [Microsoft Defender for Servers plans](https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-servers-introduction#what-are-the-microsoft-defender-for-server-plans) on your subscriptions.
