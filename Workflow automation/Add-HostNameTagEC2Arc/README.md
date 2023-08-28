# Add-HostNameTagEC2Arc

author: Nathan Swift

Some cloud admin teams want to filter and search in the Aure Portal and MDC via AWS EC2 hostname rather than by instance name. This Logic App can be set to run daily,weekly. Upon scheduled trigger it will search the Azure Resource Graph for AWS Arc Connected EC2 instances that are connected within the last 3 days and that do not have a Azure Tag for Host name. This will add the EC2 instance host name and fqdn as an additional tag. The tag can then be used in Defender for Cloud Inventory view to filter by hostname. The tag also can be used to search and filter in the Arc - Connected Servers blade of the Arc service. 


<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FAdd-HostNameTagEC2Arc%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FAdd-HostNameTagEC2Arc%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

**Additional Post Install Notes:**

The Logic App creates and uses a Managed System Identity (MSI) to authenticate and authorize against management.azure.com to obtain azure arc resource information and add a Azure tag to the Arc server.

Assign RBAC 'Reader' role to the Logic App at the MG or Subscription level.

Assign RBAC 'Tag Contributor' role to the Logic App at the MG or Subscription level.

![Trigger Logic App](./Images/mdcinv.png)

![Trigger Logic App](./Images/arcs.png)

## Logic App Workflow
![Trigger Logic App](./Images/laarch.png)