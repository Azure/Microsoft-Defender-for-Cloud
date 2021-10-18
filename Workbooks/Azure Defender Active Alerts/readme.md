# Azure Defender Active Alerts Workbook
**Author: Safeena Begum**

## Playbook Description: 
Security Alerts are the notifications that Security Center generates when it detects threats on your resources. Security Center prioritizes and lists the alerts, along with information needed for you to quickly investigate the problem. Security Center also provides detailed steps to help you remediate attacks. Alerts data is retained for 90 days. Here is the list of resource types that Azure Defender secures. Make sure to visit this article that lists the security alerts you might get from Azure Security Center and any Azure Defender plans you’ve enabled. 

Azure Security Center allows you to create custom workbooks across your data, and also comes with built-in workbook templates to allow you to quickly gain insights across your data as soon as you connect a data source. For example, with Secure Score Over Time report, you can track your organization’s security posture. Read more about how workbooks provide rich set of functionalities in our Azure monitor documentation and to understand workbooks gallery in Azure Security Center, make sure to review our documentation. 

With this automation, I’m introducing you to another great template that provides representation of your active alerts in different pivots that would help you understand the overall threats on your environment and prioritize between them. 

Pre-requisites: Most of the workbook uses Azure Resource Graph to query the data. At some places (to display Map View) it uses Log Analytics workspace to query the data. So, make sure you have continuous export turned on and exporting the Security Alerts to the Log Analytics workspace 

You can deploy the main template by clicking the button below:

***

To deploy main template:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fblob%2Fmain%2FWorkbooks%2FAzure%20Defender%20Active%20Alerts%2FAzureDefenderActiveAlerts.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fblob%2Fmain%2FWorkbooks%2FAzure%20Defender%20Active%20Alerts%2FAzureDefenderActiveAlerts.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a> 

***

## NOTE: 
To get the best experience, make sure you have your browser zoom settings set to 75% or 80%
