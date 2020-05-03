# Export-ASCRecommendationsToCSV
author: Nicholas DiCola

This Logic App will run weekly and export ASC recommendations and status to a csv file which is stored in a SharePoint site.

NOTE:  You do not need to configure workflow automation for this.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FExport-ASCRecommendationsToCSV%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FExport-ASCRecommendationsToCSV%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

**Additional Post Install Notes:**

The Logic App creates and uses a Managed System Identity (MSI) to authenticate and authorize against management.azure.com. 

Assign RBAC 'Security Reader' role to the Logic App at the Subscription level.

After template deployment, you will need to update the SharePoint create file action and Office send email action witht the site/folder information.