# Keep track of resource exemptions 
**Author: Tom Janetscheck**

With the new resource exemption feature in Azure Security Center, you can make sure that a particular security recommendation is not applied to a given resource in case the recommendation does not fit to your environment. With this automation playbook, you can notify stakeholders when a new resource exemption has been created and additionally export the exemption information to a Log Analytics workspace.
The template in this folder will deploy a LogicApp and three connections to the Office 365, Log Analytics, and ASC Assessment APIs. We have published a corresponding article about this automation artifact on our [TechCommunity blog](https://techcommunity.microsoft.com/t5/azure-security-center/how-to-keep-track-of-resource-exemptions/ba-p/1770580).

***

You can deploy the main template by clicking on the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FNotify-ResourceExemption%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FNotify-ResourceExemption%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a> 

Once you have deployed all resources, you need to authorize the Office 365 API connection. In addition to that, the Logic App uses a system-assigned Managed Identity to query the APIs used in this playbook. To enable the Logic App for this step, you need to grant the Managed Identity at least Reader rights.

To grant the Managed Identity access rights to the respective scope:
1. Make sure your account has User Access Administrator or Owner permissions for this scope.
2. Go to the subscription/management group page.
3. Press 'Access Control (IAM)' on the navigation bar.
4. Press '+Add' and 'Add role assignment'.
5. Choose Security Reader role.
6. Assign access to Logic App.
7. Choose the subscription where the logic app was deployed.
8. Choose 'Request-ResourceExemption' Logic App.
9. Press 'save'.

To authorize the API connection:
1. Go to the Resource Group you have used to deploye the template resources.
2. Select the Office365 API connection and press 'Edit API connection'.
3. Press the 'Authorize' button.
4. Make sure to authenticate against Azure AD.
5. Press 'save'.

***