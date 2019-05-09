# Azure Policy - Deny
This Azure Policy definition will **deny** the creation of new Web Applications which do not have HTTPS enabled. Also it will prevent someone from changing the setting from HTTPS to HTTP for existing resources. <br><br>
After deployment you need to assign it and set the desired scope.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fgithub.com%2FAzure%2FAzure-Security-Center%2Fblob%2Fmaster%2FSecure%2520Score%2FWeb%2520Application%2520should%2520only%2520be%2520accessible%2520over%2520HTTPS%2FAzure%2520Policy%2520-%2520deny%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
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
