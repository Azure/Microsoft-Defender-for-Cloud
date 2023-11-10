# API Management should disable public network access to the service configuration endpoints  
Author: Vasavi Pasula

The ARM template will create the LogicApp to configure API Management to disable public network access to the service configuration endpoints.
The LogicApp uses a system-assigned Managed Identity to update the API Management.You need to make sure to grant the Logic App a System Assigned Managed Identity with a role "API Management Service Contributor" at the Azure subscription scope.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FWorkflow%20automation%2FDefender%20for%20API%2FDisable-public-access-to-the-service-configuration-endpoints%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FWorkflow%20automation%2FDefender%20for%20API%2FDisable-public-access-to-the-service-configuration-endpoints%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

**To assign Managed Identity to the Logic App:**
Make sure you have User Access Administrator permissions for this scope.
- Go to the Logic App deployed.
- Under 'settings' select 'Identity' 
- Select 'System Assigned'.
- Press 'Azure role assignments'.
- Select '+Add role Assignment'
- Select the scope as 'Subscription' and under subscription select your subscription
- Under Role select 'API Management Service Contributor' and click 'Save'

