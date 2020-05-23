# Logic App sample to Sql Advanced Data Security

This Logic App deployment template is provided to remediate the "Advanced data security should be enabled on your SQL servers" recommendation in Azure Security Center.  The workflow will enumerate all 
subscriptions via the API and enumerate all ASC Security Tasks via API.  Then for each task for this recommendation
get the security task details via API.  Lastly configure enable Sql Data security for all Sql Servers.  

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FRemediation%2520scripts%2FAdvanced%2520data%2520security%2520should%2520be%2520enabled%2520on%2520your%2520SQL%2520servers%2FLogic%2520App%2Fazuredeploy.json" target="_blank">
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