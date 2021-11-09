# Microsoft Defender for App Service - Price Estimation Dashboard based on 7 days

This workbook considers all App Services with and without Microsoft Defender for App Services enabled across your selected subscription. The results are from within the last 7 days. 
- The **Estimated Price for 7 days** is based on the hours running the App Service within that period.
- The **Estimated Monthly Price** takes those 7 days as sample and calculates it for a month.

## Try it on the Azure Portal
You can deploy the workbook by clicking on the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmain%2FWorkbooks%2FAppServiceCost7Days%2FMicrosoft%20Defender%20for%20App%20Service%20-%20Price%20Estimation.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>

## Overview Tab
![Image of OverviewTab](OverviewofWorkbook.png)

Columns:
- **Subscription** 
- **App Services**
- **CPU Time:** metric retrieved from the latest 7 day period and displayed in minutes & hours
- **Estimated Price (7 days):** total of CPU Time hours running the App Service within the latest 7 days and multiplied by 0.02. This doesn't consider discounts. [Price reference](https://azure.microsoft.com/en-us/pricing/details/azure-defender/)
- **Estimated Monthly Price:** total of CPU Time hours running the App Service within the latest 7 days, divided by the TimeRange, multiplied by 30. The result multiplied by 0.02. This doesn't consider discounts. [Price reference](https://azure.microsoft.com/en-us/pricing/details/azure-defender/)


> **Credits:** [Sarah Wendel](https://www.linkedin.com/in/sarahwendel/)
