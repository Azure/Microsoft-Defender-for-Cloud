# Module 4 - Onboarding ASC Features

## Step #7 - Enable all Azure Defender plans (recommended)
For maximum protection of their resources, we recommend customers to enable all Azure Defender plans on their subscriptions. Azure Defender onboarding is already **audited** by Security Center’s default initiative and counted towards the Secure Score. Subscription owners can therefore easily onboard their subscriptions to Azure Defender by using the Quick Fix remediation available in the Security Center portal experience.  
It is recommended though to **enforce** Azure Defender for some or all of the plans, so that workload owners cannot override the settings. This can be done on the Root management group (or a different management group for higher granularity).

### Automation options
* **Azure Policy (recommended)**  
[Enable Azure Defender plans](https://github.com/Azure/Azure-Security-Center/tree/master/Pricing%20%26%20Settings/Azure%20Policy%20definitions/Azure%20Defender%20Plans)  
You can use DeployIfNotExists (DINE) policies to enforce one or more of the Azure Defender plans. If customers choose to deploy more than one of these policies, it makes sense to group them into a custom policy initiative and assign them to the appropriate scope. The appropriate scope could be the Root MG, to apply the policies to the whole subscription hierarchy, or a sub-MG to e.g. only deploy the policies to production subscriptions. In addition to that, customers can always define exclusions.  
To enable these plans on newly created subscriptions, customers have to create a remediation task for the policy. Again, customers may choose to use automation for this and create the remediation task through one of the following options:
    * [Azure CLI](https://docs.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources#create-a-remediation-task-through-azure-cli)
    * [Azure PowerShell](https://docs.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources%22%20/l%20%22create-a-remediation-task-through-azure-powershell)
    * [Azure REST API](https://docs.microsoft.com/en-us/rest/api/policy-insights/remediations/createorupdateatmanagementgroup)
* **[REST API]()**  
To enable Azure Defender using Security Center’s REST API, make a PUT request with the following request body  
   ```json
   {
     "properties": {
       "pricingTier": "Standard"
     }
   }
   ```
   for the following URL and add the relevant subscription ID and the pricingName:
https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Security/pricings/{pricingName}?api-version=2018-06-01  
Note that {pricingName} can be any of the following:  
    * VirtualMachines
    * SqlServers
    * AppServices
    * StorageAccounts
    * SqlServerVirtualMachines
    * KubernetesService
    * ContainerRegistry
    * KeyVaults
    * Dns
    * Arm
* **[Azure PowerShell]()**  
Use the following Azure PowerShell command to enable Azure Defender, e.g. for virtual machines:  
`Set-AzSecurityPricing -Name "virtualmachines" -PricingTier "Standard"`
* **[Azure CLI]()**  
Use the following Azure CLI command to enable Azure Defender, e.g. for virtual machines:  
`az security pricing create -n VirtualMachines --tier 'standard'`
* **[ARM Template]()**  
To create a *Microsoft.Security/pricings* resource, add the following JSON to the resources section of your ARM template, e.g for virtual machines:  
   ```json
   {
     "name": " VirtualMachines",
     "type": "Microsoft.Security/pricings",
     "apiVersion": "2018-06-01",
     "properties": {
        "pricingTier": "Standard"
     }
   }
   ```

* **Logic App**  
Customers can deploy a scheduled LogicApp with write permissions to all subscriptions in scope and calls the API/PS to enable Azure Defender plans. 

> *See the [Scheduled automation](../Misc/Scheduled-Automation.md) table for further implementation details*

<br />

## Step #8 - Set security contact & email settings (recommended)
To receive notifications when ASC detects compromised resources, we advise that customers provide their contact information in ASC. Customers should decide – depending on their responsibility model – whether the security contact is the workload owner, the central IT security team, or both. They can specify multiple security contacts by separating them with a comma.  
The built-in policy definition in ASC only **audits** the existence of the setting. If customers instead would like to **enforce** the setting, they need to configure this by using one of the available options below. 

### Automation options
* **Azure Policy** (recommended)  
Use the following Azure Policy: [ASC email contact](https://github.com/Azure/Azure-Security-Center/blob/master/Pricing%20%26%20Settings/Azure%20Policy%20definitions/ASC%20email%20contact/AscEmailContact-deployIfNotExists.json)
* **[Azure PowerShell](https://docs.microsoft.com/en-us/powershell/module/az.security/set-azsecuritycontact?view=azps-5.0.0)**  
Use the following Azure PowerShell command to set the security contact for a subscription:  
`Set-AzSecurityContact -Name "default1" -Email "john@contoso.com" -Phone "(214)275-4038" -AlertAdmin -NotifyOnAlert`
* **[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/security/contact?view=azure-cli-latest)**  
Use the following Azure CLI command to set the security contact for a subscription:
`az security contact create -n "default1" --email 'john@contoso.com' --phone '(214)275-4038' --alert-notifications 'on' --alerts-admins 'on'`
* **[Azure REST API](https://docs.microsoft.com/en-us/rest/api/securitycenter/securitycontacts/create)**  
To create a security contact for your subscription using Security Center’s REST API, make a PUT request for the following URL and add the relevant subscription ID and a name for the security contact:
https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Security/securityContacts/{securityContactName}?api-version=2017-08-01-preview  
The request body should include a JSON object with the following properties:  
   ```json
   {
     "properties": {
       "email": "john@contoso.com",
       "phone": "(214)275-4038",
       "alertNotifications": "On",
       "alertsToAdmins": "On"
     }
   }
   ```

* **[ARM Template](https://docs.microsoft.com/en-us/azure/templates/microsoft.security/2017-08-01-preview/securitycontacts)**  
To create a *Microsoft.Security/securityContacts* resource, add the following JSON to the resources section of your ARM template:
   ```json
   {
     "name": "default1",
     "type": "Microsoft.Security/securityContacts",
     "apiVersion": "2017-08-01-preview",
     "properties": {
       "email": "john@contoso.com",
       "phone": "(214)275-4038",
       "alertNotifications": "On",
       "alertsToAdmins": "On"
     }
   }
   ```

> *See the [Scheduled automation](../Misc/Scheduled-Automation.md) table for further implementation details*

<br />

## Step #9 - Deploy required agents (recommended)
Azure Security Center uses the Log Analytics agent to collect security data from virtual machines and to store it in a Log Analytics workspace(s). We recommend that customers automate the provisioning by e.g. using the Auto Provisioning functionality in ASC, so that the Log Analytics agent (for Windows or Linux) is automatically installed on all supported Azure VMs, and on any new ones that are created. Customers need to decide whether agents should be installed by the central security team or whether this is a task that the workload owners should perform. This decision may also depend on the Log Analytics workspace model that the customer chose. In case of a central workspace, it can also make sense to roll out the agent deployment in a centralized manner.   
Either way, customers have two options to enable auto-provisioning: they can either use the Auto Provisioning feature in ASC or they can use Azure Policy. In both cases the customer needs to specify the Log Analytics workspace ID where the agent data should be sent to. If the customer chooses an existing workspace, they should make sure that the workspace has the Security Center solution already installed on it.
The following agents are available to be deployed via ASC’s auto provisioning feature:


Agent name |	Description	| CSPM |	CWPP
| :---     |    :----     | :---: | :---: |
Log Analytics agent for Azure VMs (sometimes referred to as the Microsoft Monitoring agent) |	Collects security-related configurations and event logs from the machine and stores the data in your Log Analytics workspace for analysis. Azure Security Center depends on this agent for detecting security vulnerabilities and threats.	| Required |	Required
Dependency agent |	Collects and stores network traffic data and process dependencies. Is required to use Azure Monitor for VMs and the Service Map. Requires the Log Analytics agent to be installed on the same VM.	| Recommended | Recommended
Policy Add-on for Kubernetes (Open Policy Agent)	| Extends Gatekeeper v3, to apply at-scale enforcements and safeguards on your clusters in a centralized, consistent manner. Requires Kubernetes v1.14 or later.	| Required | 	Not required


### Automation options
*	**[Azure Policy](https://github.com/Azure/azure-policy/blob/master/built-in-policies/policyDefinitions/Security%20Center/ASC_Deploy_auto_provisioning_log_analytics_monitoring_agent_custom_workspace.json)** (recommended)  
Customers can use the built-in *DeployIfNotExists* policy to install the agent on any VM. The policy can be applied to an appropriate scope, so this option is preferred in case the customer needs to specify exclusions (in contrast, Auto Provisioning would automatically reinstall the agent on a VM even if somebody removed it manually).
*	**Auto Provisioning in ASC**  
Customers can enable Auto Provisioning and configure the workspace in the Security Center Data Collection settings by using any of the following automation options: 
    *	Azure PowerShell
    *	Azure CLI
    *	Azure REST API

<br />

### &#8680; Continue with the next steps: [Module 5 - Management](./5-Management.md)

