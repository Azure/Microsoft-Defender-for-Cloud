# Network Security Dashboard for Security Center

The new network security dashboard for Security Center provides you a unified view and full visibility to your network security resources in Azure. If you have been actively using Security Center and Network Security features in Azure, this workbook is for you!
Our newly dashboard is based on Azure Resource Graph (ARG) queries and divided to several sections such as:

-	**Overview:** summary view of all your network security resources for selected subscription(s).
-	**Public IPs & exposed ports:** ports exposed to the internet and mapping of public Ips to asset types
-	**Network security services:** DDos protections plans, Azure Firewall and Firewall policies, Azure WAF policies and NSG views
-	**Internal networking mapping:** network interfaces, route tables, private links and virtual network with DDoS protection (including subnets and peering)
-	**Gateway and VPN services:** consolidated view of Bastion hosts, VPN gateways, Virtual Network Gateways and Express Route circuits
-	**Traffic Manager**
-	**Security Center recommendations:** filtered view of all ASC network related recommendations including resource count, severity, and security control.

Informational options: using the action bars at the top section, select FAQ button to show the frequently asked question. You can also see recent changes documented on the change log option.

## Try it on the Azure Portal

To deploy the new workbook into your Security Center console, click on *Deploy to Azure* for Azure Public cloud or *Deploy to Azure Gov* for government cloud.
During the deployment, you must select a subscription and resource group to store the report. Once the workbook is successfully deployed, however to Security Center to start using it.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fpreview%2FWorkbooks%2FNetwork%2520Security%2520for%2520ASC%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fpreview%2FWorkbooks%2FNetwork%2520Security%2520for%2520ASC%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazuregovbutton"/></a>

![Dashboard demo](netsec.gif)

### Upcoming changes