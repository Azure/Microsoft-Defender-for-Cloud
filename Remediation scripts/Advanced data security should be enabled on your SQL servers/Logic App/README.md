# Logic App sample to remediate

This Logic App deployment template is provided to remediate the "Remediation scripts\Enable the built-in vulnerability assessment solution on virtual machines (powered by Qualys)" recommendation in Azure Security Center.  The workflow will enumerate all 
subscriptions via the API and enumerate all ASC Security Tasks via API.  Then for each task for this recommendation
get the security task details via API.  Lastly configure each Supported Server VA settings.  

<a
href="https://raw.githubusercontent.com/wilbug1git1/Azure-Security-Center/wilbug1-sql-data/Remediation%20scripts/Advanced%20data%20security%20should%20be%20enabled%20on%20your%20SQL%20servers/Logic%20App/azuredeploy.json" target="_blank">
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