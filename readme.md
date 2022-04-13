# Compute Security Dashboard for Microsoft Defender for Cloud

The new compute security dashboard for Microsoft Defender for Cloud provides you a unified view and full visibility to your virtual machine resources in Azure. If you have been actively using Azure virtual machines with  Microsoft Defender for Cloud in Azure, this workbook is for you!

Our newly dashboard is based on Azure Resource Graph (ARG) queries and divided to several sections such as:

-	**Virtual Machine Inventory:** summary view of all your virtual machine resources for selected subscription(s) with OS, size, powerstate, SKU details 
-	**Orphaned Assets:** Orphaned VM components like Disks, NICs, Availability Sets, Public IPs, NSGs (not attached to any VMs) 
-	**Virtual Machine Status:** VMs not having Managed Disks, VMs with pending reboot status, VMs shut down with their compliance status, List of extension in VMs, VMs with missing System Updates 
-	**Security Center recommendations:** filtered view of all Microsoft Defender for Cloud compute related recommendations including resource count, severity, and security control
-	**System Updates:** VMs missing system updates and filtered view of missing update details for selected VM
-	**System Baseline:** VMs missing security baseline configurations and filtered view of missing configuration details for selected VM
-	
Informational options: using the action bars at the top section, select FAQ button to show the frequently asked questions. You can also see recent changes documented on the change log option.

## Try it on the Azure Portal

To deploy the new workbook into your Microsoft Defender for Cloud console, click on *Deploy to Azure* for Azure Public cloud or *Deploy to Azure Gov* for government cloud.
During the deployment, you must select a subscription and resource group to store the report. 

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmain%2FWorkbooks%2FCompute%2520Security%2520Dashboard%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmain%2FWorkbooks%2FCompute%2520Security%2520Dashboard%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazuregovbutton"/></a>



### Upcoming changes

* Identification of VMs shut down for more than 30 days, AWS EC2 Security center recommendations will be added in future.