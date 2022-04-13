# Microsoft Defender for Key Vault - Price Estimation Dashboard 1.0

> ## Important note
>  
> We have released another Microsoft Defender for Cloud price estimation workbook that covers all of the following plans:
>
> * Microsoft Defender for App Services
> * Microsoft Defender for Containers
> * Microsoft Defender for Key Vaults
> * Microsoft Defender for Servers
> * Microsoft Defender for Storage
> * Microsoft Defender for Databases
>
> **You can find the new workbook [here](https://github.com/Azure/Microsoft-Defender-for-Cloud/tree/main/Workbooks/Microsoft%20Defender%20for%20Cloud%20Price%20Estimation)**.

Microsoft Defender for Key Vault currently monitors vault transactions and usage patterns, detecting unusual and potentially harmful attempts to access or exploit Key Vaults. [Learn more here.](https://docs.microsoft.com/en-us/azure/security-center/defender-for-key-vault-introduction)

This workbook (shamelessly based on the [Storage counterpart](https://github.com/Azure/Microsoft-Defender-for-Cloud/tree/main/Workbooks/Azure%20Defender%20for%20Storage%20Price%20Estimation)) considers all Key Vaults with and without Microsoft Defender for Key Vault enabled across your selected subscription. The results are from within the last 7 days. 
- The **Estimated Price for 7 days** is based on the number of transactions performed within that period
- The **Estimated Monthly Price** takes those 7 days as sample and calculates it for a month

## Try it on the Azure Portal

You can deploy the workbook by clicking on the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FWorkbooks%2FMicrosoft%20Defender%20for%20Key%20Vault%20Price%20Estimation%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FWorkbooks%2FMicrosoft%20Defender%20for%20Key%20Vault%20Price%20Estimation%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazuregovbutton"/></a>

## Overview Tab
![Image of OverviewTab](overview.jpg)

Columns:
- **Subscription** 
- **Key Vault**
- **Transactions:** metric retrieved from the latest 7 day period
- **Estimated Price (7 days):** total of Key Vault transactions of the latest 7 day period, divided by 10K and multiplied by 0.02. This doesn't consider discounts. [Price reference](https://azure.microsoft.com/en-us/pricing/details/azure-defender/)
- **Estimated Monthly Price:** total of Key Vault transactions of the latest 7 day period, divided by the TimeRange, multiplied by 30. The result is divided by 10K and multiplied by 0.02. This doesn't consider discounts. [Price reference](https://azure.microsoft.com/en-us/pricing/details/azure-defender/)

## Known Issues
- Azure Monitor Metrics data backends have limits and probably the number of requests to fetch data across Key Vaults might time out. To solve this you will need to narrow the scope (reduce the selected Key Vaults). 
- Errors might reflect by showing 0 transactions. To verify this error, go to Edit Mode and the "Timed out" message will be displayed in the query. 
![Image of Error](error.jpg)

> **Credits:** [Hélder Pinto](https://www.linkedin.com/in/hspinto/)
