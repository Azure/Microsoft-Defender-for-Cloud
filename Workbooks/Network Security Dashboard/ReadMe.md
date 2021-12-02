# Network Security Dashboard for Security Center

The new network security dashboard for Security Center provides you a unified view and full visibility to your network security and networking resources in Azure. If you have been actively using Security Center and Network Security features in Azure, this workbook is for you!

Our newly dashboard is based on Azure Resource Graph (ARG) queries and divided to several sections such as:

-	**Overview:** summary view of all your network security and networking resources for selected subscription(s)
-	**Public IPs & exposed ports:** ports exposed to the internet and mapping of public IPs to asset types
-	**Network security services:** DDoS protections plans, Azure Firewall and Firewall policies, Azure WAF policies and NSG views
-	**Internal networking mapping:** network interfaces, route tables, private links and virtual networks with DDoS protection status (including subnets and peering)
-	**Gateway and VPN services:** consolidated view of Bastion hosts, VPN gateways, Virtual Network Gateways and Express Route circuits
-	**Traffic Manager** details of all your traffic manager profiles
-	**Virtual WAN (vWAN)** consolidated view of Virtual WANs (inlcuding VPN/ExpressRoute/P2S)
-	**Security Center recommendations:** filtered view of all ASC network related recommendations including resource count, severity, and security control
-	**PaaS Services:** ipRules, virtualNetworkRules and privateEndpointConnections for Databases & Storage Accounts & Web Apps and Key Vaults

Informational options: using the action bars at the top section, select FAQ button to show the frequently asked questions. You can also see recent changes documented on the change log option.

## Try it on the Azure Portal

To deploy the new workbook into your Security Center console, click on *Deploy to Azure* for Azure Public cloud or *Deploy to Azure Gov* for government cloud.
During the deployment, you must select a subscription and resource group to store the report. Once the workbook is successfully deployed, however to Security Center to start using it.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmain%2FWorkbooks%2FNetwork%2520Security%2520Dashboard%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmain%2FWorkbooks%2FNetwork%2520Security%2520Dashboard%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazuregovbutton"/></a>

![Dashboard demo](netsec.gif)

### Upcoming changes

* Application Security Group (ASG) and Outbound rules on Azure Firewall will be added in future.
