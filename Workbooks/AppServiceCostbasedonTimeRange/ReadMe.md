# Microsoft Defender for App Service - Price Estimation Dashboard based on Time Range

This workbook considers all App Services with and without Microsoft Defender for App Services enabled across your selected subscription. The **Estimated Price** is based on the selected Time Range.

## Try it on the Azure Portal
You can deploy the workbook by clicking on the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmain%2FWorkbooks%2FAppServiceCostbasedonTimeRange%2FMicrosoft%20Defender%20for%20App%20Service%20-%20Price%20Estimation%20based%20on%20Time%20Range%20Selection.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>

## Overview Tab
![Image of OverviewTab](OverviewofWorkbook.png)

Columns:
- **Subscription** 
- **App Services**
- **CPU Time:** metric retrieved based on the Time Range selection and displayed in minutes & hours
- **Estimated Price:** total of CPU Time hours running the App Service within the selected time range and multiplied by 0.02. This doesn't consider discounts. [Price reference](https://azure.microsoft.com/en-us/pricing/details/azure-defender/)


> **Credits:** [Sarah Wendel](https://www.linkedin.com/in/sarahwendel/)
