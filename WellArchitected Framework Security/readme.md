# Well Architected Framework Security Assessment -Technical Controls Evaluation 

 This workbook assists in answering the Well Architected Framework (WAF) Security Assessment survey, mainly for Technical Controls. It is designed to verify the deployment status of the selected technical controls mentioned in the Security Assessment. Also, This will enable the Security team to gain the visibility of their cloud security posture. This Workbook utlizes Azure Resource Graph (ARG) queries to show the security recommendations based on Azure Security Benchmark standard and to provide the inventory of related resources. It also uses Azure AD Logs and Security Alerts to cover the sections under AzureAD Logs tab. It enables the security team to confirm if the specified best practice is deployed or not based on the recommedation's compliance state and available resources as applicable. Note the WAF assessment questionnaire is available in https://aka.ms/assessments and this workbook covers only technical controls as applicable.


Our newly dashboard is based on Azure Resource Graph (ARG) queries and divided to several sections such as:

-	**Threat Analysis:**  filtered view of recommendations related to Threat protection enablement status and securescore  
-	**Compliance and Governance:** View of deployed Azure Policies, Tags and Resource Locks
-	**Security Update:** filtered view of recommendations related to Vulnerability Assessment solution/Findings status, View of  VMs with missing System Updates and deployed CDN and Playbooks  
-	**Network:** filtered view of recommendations related to Public access protection, NSGs usage, management access to virtual machines, DDoS protection 
-	**Encryption:** filtered view of recommendations related to Data in transit, Data at rest encryption, VM Disk encryption, Managed disks, Secret/Key rotation
-	**Identity:** filtered view of recommendations related to MFA, Privileged access, Custom RBAC, API Keys, Managed Identity 
-	**AzureAD Logs:** Log Events realted to Conditiional Access Policy, Legacy Authentication protocols, Azure AD PIM, Identity Protection Alerts 

Informational options: using the action bars at the top section, select FAQ button to show the frequently asked questions. You can also see recent changes documented on the change log option.

## Try it on the Azure Portal

To deploy the new workbook into your Microsoft Defender for Cloud console, click on *Deploy to Azure* for Azure Public cloud or *Deploy to Azure Gov* for government cloud.
During the deployment, you must select a subscription and resource group to store the report. 

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmain%2FWorkbooks%2FWellArchitected%2520Framework%2520Security%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmain%2FWorkbooks%2FWellArchitected%2520Framework%2520Security%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazuregovbutton"/></a>

![Dashboard demo](./wafsa.GIF)

### Upcoming changes

* DevOps and API realted recommendations will be added in future.
