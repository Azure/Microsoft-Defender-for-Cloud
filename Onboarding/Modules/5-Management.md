# Module 5 - Management

## Step #10 - Export Microsoft Defender for Cloud data to Microsoft Sentinel (recommended)
Microsoft Sentinel is Microsoft’s cloud-native SIEM and SOAR solution. We recommend that customers stream their security alerts from Microsoft Defender for Cloud into Microsoft Sentinel for more insights. This gives customers the option to automatically generate incidents in Microsoft Sentinel from Microsoft Defender for Cloud alerts.

### Automation options:
* **[Microsoft Defender for Cloud data connector in Microsoft Sentinel](https://docs.microsoft.com/en-us/azure/sentinel/connect-azure-security-center)** (recommended)  
Microsoft Defender for Cloud natively integrates with Microsoft Sentinel. We recommend the built-in connector to stream Microsoft Defender for Cloud alerts from MDC into Microsoft Sentinel.
    * [REST API](https://docs.microsoft.com/en-us/rest/api/securityinsights/dataconnectors/createorupdate)   
    To create the MDC data connector via REST API, make a `PUT` request for the following URL and replace the placeholders with the subscription ID, resource group name, and workspace name of your Sentinel environment:
https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/providers/Microsoft.SecurityInsights/dataConnectors/763f9fa1-c2d3-4fa2-93e9-bccd4899aa12?api-version=2020-01-01  
The request body should include a JSON object with the following properties:
      ```json
      {
        "kind": "AzureSecurityCenter",
        "properties": {
          "subscriptionId": "<subscriptionID>",
          "dataTypes": {
            "alerts": {
              "state": "Enabled"
            }
          }
        }
      }
      ```
      To connect all subscriptions in your tenant to Microsoft Sentinel, this [blog post](https://techcommunity.microsoft.com/t5/azure-sentinel/azure-security-center-auto-connect-to-sentinel/ba-p/1387539) gives detailed instructions on how to achieve that with an Azure Logic App.

<br />

## Step #11 - Prepare and deploy Logic Apps (recommended)
Azure Logic Apps are an integral part when it comes to automatically responding to an event in Microsoft Defender for Cloud. Logic Apps are a cloud service that helps customers to schedule, automate, and orchestrate tasks, business processes, and workflows. Every logic app workflow starts with a trigger, which fires when a specific event happens, or when new available data meets specific criteria. In MDC, the following two triggers are supported:
*	When an Microsoft Defender for Cloud Recommendation is created or triggered
*	When an Microsoft Defender for Cloud Alert is created or triggered

It may make sense for a central team to provide workflow owners with proven Logic Apps that help them make their environment more secure. The Microsoft Defender for Cloud GitHub Repo already has an [extensive list of templates](https://github.com/Azure/Microsoft-Defender-for-Cloud/tree/main/Workflow%20automation) that customers can start with. 
The deployment scope of a Logic App is a subscription.

### Automation options:
* **[ARM Templates](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-azure-resource-manager-templates-overview)**
    * [Azure CLI](https://docs.microsoft.com/en-us/azure/logic-apps/quickstart-logic-apps-azure-cli)
    * [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/module/az.logicapp/new-azlogicapp?view=azps-5.1.0)
* **[REST API](https://docs.microsoft.com/en-us/rest/api/logic/workflows/createorupdate)**

<br />

## Step #12 - Workflow Automation (recommended)
Automating the organization's monitoring and incident response processes can greatly improve the time it takes to investigate and mitigate security incidents. Workflow automation in Microsoft Defender for Cloud helps customers to automate their workflow for incident response by triggering Logic Apps on security alerts and recommendations. Workflow automation can be used both for external notification on recommendations or alerts (ITSM, DevOps, etc.) and for auto remediation.  
Some of the top use cases for workflow automation include
* Notifications & ticket creation
    * Open a ticket in ServiceNow or JIRA for a new recommendation or alert
    *	Send a message on a Teams or Slack channel for a new recommendation or alert
*	Automation at scale
    * Automatically respond to an alert, e.g. block an IP address as a response to a brute force attack, or quarantine an infected VM
    * Automatically remediate recommendations, e.g. install a vulnerability assessment solution on a VM

A workflow automation is composed of two parts. So to deploy workflow automation, customers need to follow both of the following steps:
1.	Customers need to create a Logic App, e.g. through the Logic App Designer or a template deployment (see [Step #11 - Prepare and deploy Logic Apps (recommended)](./5-Management.md#step-11---prepare-and-deploy-logic-apps-recommended) for more details). 
2.	Customers need to create a workflow automation resource in Microsoft Defender for Cloud and specify the required parameters and the Logic App that it should trigger.

### Automation options:
* **Azure Policy** (recommended)
    * [Deploy Workflow Automation for Microsoft Defender for Cloud alerts](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2fproviders%2fMicrosoft.Authorization%2fpolicyDefinitions%2ff1525828-9a90-4fcf-be48-268cdd02361e)
    * [Deploy Workflow Automation for Microsoft Defender for Cloud recommendations](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2fproviders%2fMicrosoft.Authorization%2fpolicyDefinitions%2f73d6ab6c-2475-4850-afd6-43795f3492ef)
* **[REST API](https://docs.microsoft.com/en-us/rest/api/securitycenter/automations/createorupdate)**

<br />

## Step #13 - Export data for additional reporting (optional)
Customers that want to export security alerts, security recommendations and findings, Secure Score (in preview), and Regulatory Compliance (in preview) at the subscription or management group level for external reporting can use the **Continuous export** feature in MDC. For example, Export to a Log Analytics workspace is useful if they want to create dynamic and customizable reports in PowerBI or access and query Microsoft Defender for Cloud data in Azure Monitor. In the latter case, customers can start by using one of the available [Azure Monitor workbooks](https://github.com/Azure/Microsoft-Defender-for-Cloud/tree/main/Workbooks) in the MDC GitHub repository.  
For tenant-wide reporting, customers can also use the **Microsoft Graph Security connector** of Power BI Desktop to connect to the Microsoft Graph Security API (this requires getting consent by the Azure AD global administrator). They can then build dashboards and reports to gain insights into their security-related alerts and secure scores.

### Automation options:
* **Continuous Export**
    * Azure Policy (recommended)  
    [Deploy export to Log Analytics workspace for Microsoft Defender for Cloud alerts and recommendations](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2fproviders%2fMicrosoft.Authorization%2fpolicyDefinitions%2fffb6f416-7bd2-4488-8828-56585fef2be9)
    * [REST API](https://docs.microsoft.com/en-us/rest/api/securitycenter/automations/createorupdate)
* **[Microsoft Graph Security Connector](https://docs.microsoft.com/en-us/power-bi/connect-data/desktop-connect-graph-security)**

<br />

## Step #14 - Export Microsoft Defender for Cloud data to other SIEM or ITSM solutions (optional)
If customers want to export Microsoft Defender for Cloud data for tracking with other monitoring tools in their environment, they can either use the Microsoft Graph Security API or the Continuous Export feature in MDC.  
Microsoft Defender for Cloud has out-of-the-box integration with **Microsoft Graph Security API**. No configuration is required and there are no additional costs. Customers can use this API to stream alerts from their entire tenant (and data from many other Microsoft Security products) into third-party SIEMs and other popular platforms such as Splunk, ServiceNow, QRadar, and others.  
**Continuous Export** is a feature in Microsoft Defender for Cloud that lets customers fully customize what will be exported and where it will go. Exportable data types include alerts, recommendations, security findings, secure score (in preview), and regulatory compliance (in preview). Continuous Export to Azure Event Hub is useful if customers need integration with third-party SIEMs or Azure Data Explorer at the subscription or management group level.

### Automation options:
* **Microsoft Graph Security API** (recommended)  
    *	For many third-party SIEMs and other popular platforms, customers can use native connectors to ingest alerts using the Microsoft Graph Security API. Customers can check the [list of connectors from Microsoft](https://docs.microsoft.com/en-us/graph/security-integration#list-of-connectors-from-microsoft) or use one of the [connectors built by Microsoft partners](https://aka.ms/graphsecuritypartnerships).
    *	Customers can also use the [supported integration options](https://docs.microsoft.com/en-us/graph/security-concept-overview#why-use-the-microsoft-graph-security-api) like the Graph Security SDK for C#, PowerShell scripts, or the Microsoft Graph Security connector in Azure Logic Apps to create an automated workflow.
    *	[Microsoft Graph Security REST API](https://docs.microsoft.com/en-us/graph/api/resources/security-api-overview?view=graph-rest-1.0)

* **Continuous Export to Azure Event Hub**  
    * Azure Policy (recommended)  
    [Deploy export to Event Hub for Microsoft Defender for Cloud alerts and recommendations](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2fproviders%2fMicrosoft.Authorization%2fpolicyDefinitions%2fcdfcce10-4578-4ecd-9703-530938e4abcb)
    * [Azure REST API](https://docs.microsoft.com/en-us/rest/api/securitycenter/automations/createorupdate)

<br />

## Step #15 - Set alert suppression rules (optional)
If customers are using Microsoft Defender for Cloud, they will receive security alerts in Microsoft Defender for Cloud that are triggered by advanced detections. With suppression rules customers can tune the alerts they are getting from Microsoft Defender for Cloud and stop receiving alerts that are either being triggered too often to be useful or that have been identified as false positives. Nevertheless, customers should carefully check the potential impact of any suppression rule before implementing it.

### Automation options:
* **Azure Policy** (recommended)  
[Deploy – Configure suppression rules for Microsoft Defender for Cloud](https://github.com/Azure/azure-policy/blob/master/built-in-policies/policyDefinitions/Security%20Center/ASC_SuppressionRulesForAlerts_Deploy.json)
* **[Azure REST API](https://docs.microsoft.com/en-us/rest/api/securitycenter/alertssuppressionrules/update)**  
To create an alert suppression rule via REST API, make a PUT request for the following URL and replace the placeholders with your subscription ID and a name for the alert suppression rule:
https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Security/alertsSuppressionRules/{alertsSuppressionRuleName}?api-version=2019-01-01-preview
The request body should include a JSON object with the following properties minimum:
  ```json
  {
    "properties": {
      "alertType": "<alertType>",
      "reason": "<Reason>", 
      "state": "<Enabled|Disabled>"
    }
  }
  ```

<br />

### &#8680; Congratulations on completing the last module! Not sure what to do next? Continue here: [Next Steps](../Misc/Next-Steps.md)
