# ASC Regulatory Compliance
Author: Dharani Dharan Mariappan

This LogicApp leverages the Microsoft.Security/regulatoryComplianceStandards REST API to get a regulatory compliance snapshot and send the results Azure SQL Table.

The ARM template will create the LogicApp which runs in recurrence with a frequency of once a week. The workflow will pick up the compliance data from every subscription in an Azure Tenant and the feed into a SQL Table. In every iteration the SQL table will be dropped and created with recent data. Later the data can be used for PowerBI to feed in so it can be visualised. In order to be able to deploy the resources, your user account needs to be granted Contributor rights on the target Resource Group. The LogicApp uses a system-assigned Managed Identity to access data from the ARG API. You need to make sure to grant the Managed Identity 'Security Reader' rights to all Azure subscriptions you want to export compliance data from and 'SQL Server contributor' on the Azure SQL Server in which the database will be residing and also appropriate permissions to perform DB operations.

Click on the **Deploy to Azure** button to create the Logic App in a target resource group.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FRegulatory%20Compliance%2FASC%20Regulatory%20Compliance.json" target="_blank">
<img src="https://aka.ms/deploytoazurebutton"/></a>

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FRegulatory%20Compliance%2FASC%20Regulatory%20Compliance.json" target="_blank">
<img src="https://aka.ms/deploytoazuregovbutton"/></a>
 
**To assign Managed Identity to specific scope:**

Make sure you have User Access Administrator permissions for this scope.
Go to the subscription/management group page.
Press 'Access Control (IAM)' on the navigation bar.
Press '+Add' and 'Add role assignment'.
Choose 'Security Reader' and 'SQL Server Contributor' role.
Assign access to Logic App.
Choose the subscription where the logic app was deployed.
Choose 'GetComplianceState' Logic App.
Press 'save'.

**Prerequisites:**
Azure SQL Server with DB and Table.