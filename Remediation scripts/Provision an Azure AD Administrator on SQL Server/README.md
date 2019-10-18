# Samples for remediating "Provision an Azure AD Administrator on SQL Server"
These samples provide various ways to resolve the "*Provision an Azure AD Administrator on SQL Server*" recommendation in Azure Security Center. There are four samples:
* **PowerShell script** - will loop through and remediate each instance 
    * Requires the Azure (Az) PowerShell module
* **Logic App Playbook** - uses the REST API to enumerate and remediate each instance 
    * Will create a managed service principal. This will need to be added to the subscription with the appropriete access
* **Azure Policy definitions**
    * Deny policy - This will prevent someone from changing the HTTPS setting back to disabled and prevents the creation of new instances which are not using HTTPS
    * deployIfNotExist policy - This allows to run a remediation task


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
