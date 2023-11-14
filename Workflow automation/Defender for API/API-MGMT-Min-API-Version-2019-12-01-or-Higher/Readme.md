# API Management minimum API version should be set to 2019-12-01 or higher
Author: Giulio Astori

The ARM template will create the LogicApp that configures the API Management to prevent service secrets from being shared with read-only users, the minimum API version should be set to 2019-12-01 or higher.
The LogicApp uses a system-assigned Managed Identity to update the API Management.You need to make sure to grant the Logic App a System Assigned Managed Identity with a role "API Management Service Contributor" at the Azure subscription scope.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmainh%2FWorkflow%20automation%2FDefender%20for%20API%2FAPI-MGMT-Min-API-Version-2019-12-01-or-Higher%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
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
