# Defender for APIs Automations  

These ARM templates will create Logic Apps to automate the recommendations for [Defender for APIs](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-apis-introduction).

The Logic Apps use a system-assigned Managed Identity to update the API Management. You need to make sure to grant the Logic Apps a System Assigned Managed Identity with a role "API Management Service Contributor" at the Azure subscription scope.

**To assign Managed Identity to each Logic App:**
Make sure you have User Access Administrator permissions for this scope.
- Go to the Logic App deployed.
- Under 'settings' select 'Identity' 
- Select 'System Assigned'.
- Press 'Azure role assignments'.
- Select '+Add role Assignment'
- Select the scope as 'Subscription' and under subscription select your subscription
- Under Role select 'API Management Service Contributor' and click 'Save'
