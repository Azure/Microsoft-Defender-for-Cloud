# Microsoft Defender for Servers - Enable MDE integration for Linux machines

**Author: Tom Janetscheck**

## Description

In summer 2021, we added MDE integration support for Linux machines to Microsoft Defender for Servers. In order to avoid breaking changes during the preview, we added an activation option for this integration so customers can select if they want to deploy MDE to their Linux machines in subscriptions that have existed before this release.

![MDE Integration](./integration.png)

This script has been created to enable MDE integration for Linux machines at scale across on subscriptions within your Tenant. When running the script, it will ask you to enter a Tenant ID and if you want to enable MDE on all subscriptions (including those that don't have the MDE integration enabled at all), or only add MDE integration for Linux machines on subscriptions that already have Windows integration enabled.

### Prerequisites

- You need to run the script with a user account that has Security Admin access rights on all subscriptions you want to enable MDE integration on.
- Make sure to use the latest version of the [Az.Security PowerShell module](https://docs.microsoft.com/powershell/module/az.security).
- In order to allow Defender for Cloud to deploy and integrate MDE, you need to enable one of the [Microsoft Defender for Servers plans](https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-servers-introduction#what-are-the-microsoft-defender-for-server-plans) on your subscriptions.
