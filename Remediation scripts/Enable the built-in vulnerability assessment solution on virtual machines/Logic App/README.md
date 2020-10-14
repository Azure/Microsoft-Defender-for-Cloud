# Logic App sample to remediate

This Logic App deployment template is provided to remediate the "A vulnerability assessment solution should be enabled on your virtual machines" recommendation in Azure Security Center.  
The workflow runs every week and query all subscriptions and their recommendations via API. Then, it will query resource IDs from “A vulnerability assessment solution should be enabled on your virtual machines” recommendation and deploy the integrated vulnerability assessment solution powered by Qualys.

>> To deploy VA solution on a VM using this Logic App, you must have Reader permissions to query subscriptions list permissions to deploy VM extension on the resource. To do so, you can use managed identity and assign Security Admin role. This role can be assigned on a management group level for the (preferred) or for each one of the subscriptions you want to get data on.

>> You can change your Log App to run in a different interval by modifying the first step in the workflow.

### Assign security admin role on for Managed Identity on a specific scope:

1. Make sure you have User Access Administrator or Owner permissions for this scope.
2.	Go to the **Subscription/Management Group** page.
3.	Click on **Access Control (IAM)** on the navigation bar.
4.	Click **+Add** and Add role assignment.
5.	Select **Security Admin** role.
6.	Assign access to **Logic App**.
7.	Select the subscription where the logic app was deployed to.
8.	Select **ASC-Install-VAExtention** Logic App instance.
9.	Click **Save**.

## Try on Portal
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FRemediation%2520scripts%2FEnable%20the%20built-in%20vulnerability%20assessment%20solution%20on%20virtual%20machines%2FLogic%2520App%2Ftemplate.json" target="_blank">
<img src="https://aka.ms/deploytoazurebutton"/></a>

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.