# Time indicators - notify about new stale resources
**Author: Tom Janetscheck**

With the new time indicator fields *firstEvaluationDate* and *statusChangeDate*, Azure Security Center helps you to react on unhealthy resources. This playbook will run once a week and send a notification email that will inform you about all unhealthy resources including the open recommendations that have been found during the last 7 days.

![Notification mail](.//notificationMail.png)

The template in this folder will deploy a LogicApp and and API connections to Office 365.

***

You can deploy the main template by clicking the button below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FNotify-StaleResources%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>

Once you have deployed all resources, you need to authorize the Office 365 API connection. In addition to that, the Logic App uses a system-assigned Managed Identity to query the APIs used in this playbook. To enable the Logic App for this step, you need to grant the Managed Identity at least Reader or Security Reader access rights.

To grant the Managed Identity access rights to the respective scope:

1. Make sure your account has User Access Administrator or Owner permissions for this scope.
2. Go to the subscription/management group page.
3. Press 'Access Control (IAM)' on the navigation bar.
4. Press '+Add' and 'Add role assignment'.
5. Select Reader or Security Reader role.
6. Assign access to Logic App.
7. Select the subscription where the logic app was deployed.
8. Select the 'Notify-StaleResources' Logic App.
9. Press 'save'.

To authorize the API connection:

1. Go to the Resource Group you have used to deploy the template resources.
2. Select the Office365 API connection and press 'Edit API connection'.
3. Press the 'Authorize' button.
4. Make sure to authenticate against Azure AD.
5. Press 'save'.

***
Make sure to manually trigger the playbook once you've met all prerequisites. It will then automatically be triggered every 7 days.
