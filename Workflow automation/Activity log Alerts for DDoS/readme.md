Activity Log Alerts For DDoS 
Author: Dharani Dharan Mariappan

This LogicApp leverages the Resource Management, Application Insights and Azure Resource Graph REST APIs to get all subscriptions under the tenant and checks for the VNet and PublicIPAlert on each subscription and creates alert if not found. Enables the alert if it is disabled.

The ARM template will create the LogicApp which will run in recurrence with frequency of 30 minutes. The workflow picks up specific administrative signals from Azure Activity log associated to Vnet and Public Ip Address in every valid subscriptions. Based on the signal it creates Alerts if it is not created earlier or Enables the alert if it is disabled. In order to be able to deploy the resources, your user account needs to be granted Contributor rights on the target Resource Group. The LogicApp uses a system-assigned Managed Identity to access data from API. You need to make sure to grant the Managed Identity 'Security Admin' and 'Monitoring Contributor' rights to all Azure subscriptions.

To assign Managed Identity to specific scope:

Make sure you have User Access Administrator permissions for this scope.
Go to the subscription/management group page.
Press 'Access Control (IAM)' on the navigation bar.
Press '+Add' and 'Add role assignment'.
Choose 'Security Admin' and 'Monitoring Contributor'.
Assign access to Logic App.
Press 'save'.

