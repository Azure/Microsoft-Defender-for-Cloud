# Microsoft Defender for Servers - Create Azure Monitor Agent Data Collection Rule for Security Events collection

**Author: Hélder Pinto**

## Description

**This script only creates the Data Collection Rule**. Don't forget to create the Data Collection Rule Associations for each of the Virtual Machines you want to collect Security Events from.

## Usage

## Prerequisites

- You need to run the script with a user account that has at least **Monitoring Contributor** access rights on the subscriptions you want to create the Data Collection Rule
- Make sure to use the latest version of the [Az.Accounts PowerShell module](https://docs.microsoft.com/powershell/module/az.accounts)
- In order to benefit from the 500-MB free data ingestion allowance (per server, per day), you have to [enable Defender for Servers Plan 2 on the Azure subscription and on the Log Analytics Workspace](https://learn.microsoft.com/en-us/azure/defender-for-cloud/faq-defender-for-servers#do-i-need-to-enable-defender-for-servers-on-the-subscription-and-on-the-workspace-) you chose as the destination for the Data Collection Rule