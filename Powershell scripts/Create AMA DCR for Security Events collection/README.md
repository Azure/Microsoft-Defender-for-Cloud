# Microsoft Defender for Servers - Create Azure Monitor Agent Data Collection Rule for Security Events collection

**Author: Hélder Pinto**

## Description

Although Defender for Servers does not rely on security events collection to provide its protection capabilities, customers may want to collect this valuable data to bring additional context to their server security investigations or alerts. This script allows you to create a Data Collection Rule for Security Events collection by Azure Monitor Agents running in your Windows servers.

You must specify an event filter according to the options described [here](https://learn.microsoft.com/en-us/azure/defender-for-cloud/working-with-log-analytics-agent#what-event-types-are-stored-for-common-and-minimal). For custom event filters, see [how to define XPath queries](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/data-collection-rule-azure-monitor-agent?tabs=portal#filter-events-using-xpath-queries).

**This script only creates the Data Collection Rule**. Don't forget to create the Data Collection Rule Associations for each of the Virtual Machines you want to collect Security Events from.

## Usage

```powershell
./Add-AMASecurityEventDCR.ps1 -DcrName "<DCR name>" -ResourceGroup "<DCR resource group>" -SubscriptionId "<DCR subscription>" -Region "<DCR region>" -LogAnalyticsWorkspaceARMId "<Log Analytics Workspace ARM resource ID>" -EventFilter AllEvents|Common|Minimal|Custom [-CustomEventFilter "<XPath query 1>","<XPath query 2>","<XPath query N>"]
```

### Examples

```powershell
# Collect all Security Events
./Add-AMASecurityEventDCR.ps1 -DcrName "securityevents-dcr" -ResourceGroup "dfs-rg" -SubscriptionId "00000000-0000-0000-0000-000000000000" -Region "eastus" -LogAnalyticsWorkspaceARMId "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/loganalytics-rg/providers/microsoft.operationalinsights/workspaces/myworkspace" -EventFilter AllEvents
```

```powershell
# Collect custom Security Events
./Add-AMASecurityEventDCR.ps1 -DcrName "securityevents-dcr" -ResourceGroup "dfs-rg" -SubscriptionId "00000000-0000-0000-0000-000000000000" -Region "eastus" -LogAnalyticsWorkspaceARMId "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/loganalytics-rg/providers/microsoft.operationalinsights/workspaces/myworkspace" -EventFilter Custom -CustomEventFilter "Microsoft-Windows-AppLocker/MSI and Script!*[System[(EventID=8005) or (EventID=8006) or (EventID=8007)]]","Microsoft-Windows-AppLocker/EXE and DLL!*[System[(EventID=8001) or (EventID=8002) or (EventID=8003) or (EventID=8004)]]"
```

## Prerequisites

- You need to run the script with a user account that has at least **Monitoring Contributor** access rights on the scope you want to create the Data Collection Rule (see [more about permissions](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-rule-overview#permissions))
- Make sure to use the latest version of the [Az.Accounts PowerShell module](https://docs.microsoft.com/powershell/module/az.accounts)
- In order to benefit from the 500-MB free data ingestion allowance (per server, per day), you have to [enable Defender for Servers Plan 2 on the Azure subscription and on the Log Analytics Workspace](https://learn.microsoft.com/en-us/azure/defender-for-cloud/faq-defender-for-servers#do-i-need-to-enable-defender-for-servers-on-the-subscription-and-on-the-workspace-) you chose as the destination for the Data Collection Rule