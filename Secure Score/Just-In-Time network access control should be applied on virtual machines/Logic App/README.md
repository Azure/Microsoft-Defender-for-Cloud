# Logic Apps sample playbook to remediate

This logic app will find all Security Score recommendations for JIT VM Access and create access policies for each VM for ports 22 and 3389.

The playbook leverages a "Managed Identity" which needs to be configured after deployment. This "Managed Identity" also requires the appropriete subscription permissions (contributor) on the resources (subscriptions, tasks, and VMs) that you would like to remediate.

<a
href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FSecure%2520Score%2FJust-In-Time%2520network%2520access%2520control%2520should%2520be%2520applied%2520on%2520virtual%2520machines%2FLogic%2520App%2FEnable-JIT.json" target="_blank">
    <img src="https://azuredeploy.net/deploybutton.png"/>
</a>

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
