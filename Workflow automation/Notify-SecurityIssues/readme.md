# Notify resource owner of outstanding security issues
### Author: Lior Arviv

### Overview
The Logic App allows you to notify resource owner/s of outstanding security issues (unhealthy recommendations).
[Asset inventory dashboard](https://docs.microsoft.com/en-us/azure/security-center/asset-inventory) in Azure Security Center, allows you to trigger Logic App automation on selected resource/s right from the top menu bar.
Once triggered, the resource owner (RBAC role) gets email message summarizes all active/unhealthy recommendations along with a direct link to resource security heath blade – so resource owner can review the recommendations and resolve all the issues.
After a successful deployment, you must grant the required permissions for the Logic App to run and authorize Office 365 connector to generate valid access tokens for authenticating your credentials – detailed instructions below.

![Trigger Logic App](.//trigger-logic-app.gif)

### Instructions

1. Click on the **Deploy to Azure** button to create the Logic App in a target resource group:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FNotify-SecurityIssues%2Fazuredeploy.json" target="_blank">
<img src="https://aka.ms/deploytoazurebutton"/></a>

<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FNotify-SecurityIssues%2Fazuredeploy.json" target="_blank">
<img src="https://aka.ms/deploytoazuregovbutton"/></a>

2. Grant *Reader* (built-in role) to the Logic App's Managed Identity on all subscriptions or management groups you want to monitor and manage resources in using this Logic App:

    * Go to the subscription/management group page.
    * Select **Access Control (IAM)** on the navigation bar.
    * Select **+Add** and **Add role assignment**.
    * Select the respective role **Reader** (built-in).
    * Assign access to Logic App.
    * Select the subscription where the logic app was deployed and then select `Notify-SecurityIssues` Logic App.
    * Select **Save**.

> 💡 You can assign permissions only if your account has been assigned as Owner or User Access Administrator roles on on the relevant Azure management scope.

3. Grant *Directory Readers* role in Azure Active Directory:

    * Open Azure Active Directory [role and administrators page](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RolesAndAdministrators).
    * From the administrative roles list, select **Directory readers** role.
    * Select **+Add assignments**.
    * The **Add assignments** window opens, search and select *Notify-SecurityIssues*. Select **Add**.
    * You should now see `Notify-SecurityIssues` service principal listed.

> 💡 You can assign permissions only if your account has Global Administrator or Privileged Role Administrator permissions in Azure Active Directory (Azure AD).

4. Authorize Logic App connection: *Office365-Notify-SecurityIssues*:

    * From the Logic App’s sidebar, select **API connections**.
    * Select **Office365-Notify-SecurityIssues** connection.
    * From the sidebar, select **Edit API connection**.
    * Select **Authorize** and authenticate using your credentials.
    * Select **Save** to apply your changes.