# Request resource exemption from a particular security recommendation
**Author: Tom Janetscheck**

Please make sure to also read the [corresponding article](https://techcommunity.microsoft.com/t5/azure-security-center/resource-exemption-in-azure-security-center/ba-p/1703052) in the Azure Security Center TechCommunity.

With the new resource exemption feature in Azure Security Center, you can make sure that a particular security recommendation is not applied to a particular resource in case the recommendation does not fit to your environment. In order to be able to create a resource exemption, you need to have elevated access rights. With this automation playbook, you can _request a resource exemption_ directly from Azure Security Center, even if you're not allowed to directly create the exemption yourself. The template will deploy a LogicApp and three connections to the Office 365, MS Teams, and ASC Assessment APIs. When remediating recommendations, users can select a resource and trigger the Logic App from the recommendation details page.

![Trigger exemption request](https://raw.githubusercontent.com/Azure/Azure-Security-Center/master/Workflow%20automation/Request-ResourceExemption/TriggerExemptionRequest.png)

The Logic App will then automatically send an email and Teams message to the email addresses that are configured as [Security Contacts](https://docs.microsoft.com/en-us/azure/security-center/security-center-provide-security-contact-details) on the subscriptions.

![Email template](https://raw.githubusercontent.com/Azure/Azure-Security-Center/master/Workflow%20automation/Request-ResourceExemption/EmailTemplate.png)

***

You can deploy the main template by clicking on the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FRequest-ResourceExemption%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FRequest-ResourceExemption%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a> 

Once you have deployed all resources, you need to authorize both, the Office 365 and MS Teams API connections. In addition to that, the Logic App uses a system-assigned Managed Identity to query the security contacts' email addresses from our ASC Security Contacts API. To enable the Logic App for this step, you need to grant the Managed Identity at least [Security Reader](https://docs.microsoft.com/en-us/azure/security-center/security-center-permissions) rights.

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

To authorize the API connections:
1. Go to the Resource Group you have used to deploye the template resources.
2. Select the Office365 API connection and press 'Edit API connection'.
3. Press the 'Authorize' button.
4. Make sure to authenticate against Azure AD.
5. Press 'save'.
6. Repeat these steps for the MSTeams API connection.

***
