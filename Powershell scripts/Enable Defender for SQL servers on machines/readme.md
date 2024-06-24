# Enable Defender for Databases’ “SQL Servers on Virtual Machines” at scale: 

Microsoft Defender for Databases offers extensive security for SQL servers on virtual machines. To safeguard your databases, it is essential to implement the Azure Monitoring Agent (AMA) to thwart attacks and identify configuration errors. The plan’s auto provisioning process is automatically enabled with the plan and is responsible for the configuration of all of the agent components required for the plan to function. This includes installation and configuration of AMA, workspace configuration, and the installation of the plan’s VM extension/solution. For more information, please refer to the following information.  

This guide outlines the process for enabling Microsoft Defender for Databases’ auto-provisioning across multiple subscriptions simultaneously. It is applicable to SQL servers hosted on Azure Virtual Machines, on-premises environments, and Azure Arc-enabled SQL servers. 

### This guide introduces additional functionalities that accommodate a variety of configurations, including: 

* Custom Data Collection Rules (DCR) 
* Custom Identity Management 
* Default Workspace Integration 
* Custom Workspace Configuration 

## Before you begin
* Learn more about [Server on Virtual Machines](https://azure.microsoft.com/services/virtual-machines/sql-server/SQL).
* For on-premises SQL servers, you can learn more about [SQL Server enabled by Azure Arc](https://learn.microsoft.com/en-us/sql/sql-server/azure-arc/overview) and how to [install Log Analytics agent on Windows computers without Azure Arc](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/agent-windows), and how to [migrate to AMA](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-migration) in case the log analytics agent is already installed. 
* For multicloud SQL servers: 
    * [Connect your AWS accounts to Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/defender-for-cloud/quickstart-onboard-aws)
    * [Connect your GCP project to Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/defender-for-cloud/quickstart-onboard-gcp)

## Prerequisites
* The user must have an owner permissions on the subscription.
* Install the following Powershell modules: 
    * Az.Resources 
    * Az.OperationalInsights 
    * Az.Accounts 
    * Az 
    * Az.PolicyInsights 
    * Az.Security 

## Deployment overview

The following Powershell script enables Microsoft Defender for SQL on Machines on a given subscription. 

### Parameters:

* `SubscriptionId`: [Required] The Azure subscription ID that you want to enable Defender for SQL servers on machines for. 

* `RegisterSqlVmAgnet`: [Required] A flag indicating whether to register the SQL VM Agent in bulk. For more information: https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/sql-agent-extension-manually-register-vms-bulk?view=azuresql 

* `WorkspaceResourceId`: [Optional] The resource ID of the Log Analytics workspace, if you want to use a custom one and not the default one. 

* `DataCollectionRuleResourceId`: [Optional] The resource ID of the data collection rule, if you want to use a custom one and not the default one. 

* `UserAssignedIdentityResourceId`: [Optional] The resource ID of the user-assigned identity, if you want to use a custom one and not the default one. 

### Examples: 

For using a default Log Analytics workspace, data collection rule and managed identity:
```
Write-Host "------ Enable Defender for SQL on Machines example ------" 
$SubscriptionId = "5320f111-d736-4793-acfb-64451ae625de" 
$RegisterSqlVmAgnet = "false" 
.\EnableDefenderForSqlOnMachines.ps1 -SubscriptionId $SubscriptionId -RegisterSqlVmAgnet $RegisterSqlVmAgnet 
```

For using a custom Log Analytics workspace, data collection rule and managed identity: 
```
Write-Host "------ Enable Defender for SQL on Machines example ------" 
$SubscriptionId = "5320f111-d736-4793-acfb-64451ae625de" 
$RegisterSqlVmAgnet = "false" 
$WorkspaceResourceId = "/subscriptions/5320f111-d736-4793-acfb-64451ae625de/resourceGroups/someResourceGroup/providers/Microsoft.OperationalInsights/workspaces/someWorkspace" 
$DataCollectionRuleResourceId = "/subscriptions/5320f111-d736-4793-acfb-64451ae625de/resourceGroups/someOtherResourceGroup/providers/Microsoft.Insights/dataCollectionRules/someDcr" 
$UserAssignedIdentityResourceId = "/subscriptions/5320f111-d736-4793-acfb-64451ae625de/resourceGroups/someElseResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/someManagedIdentity" 
.\EnableDefenderForSqlOnMachines.ps1 -SubscriptionId $SubscriptionId -RegisterSqlVmAgnet $RegisterSqlVmAgnet -WorkspaceResourceId $WorkspaceResourceId -DataCollectionRuleResourceId $DataCollectionRuleResourceId -UserAssignedIdentityResourceId $UserAssignedIdentityResourceId 
```