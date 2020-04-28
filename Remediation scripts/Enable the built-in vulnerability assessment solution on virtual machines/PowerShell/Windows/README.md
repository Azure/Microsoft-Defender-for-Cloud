# Samples for remediating "Enable the built-in vulnerability assessment solution on virtual machines at scale"

* PowerShell script - Will loop through and rememdiate each instance
    - Requires Azure (Az) PowerShell module

### Steps:

1. Run the Check-VA-VMExtension.ps1 and it will scan all the subscriptions and look for the VA agent.  It will output the results to C:\templ\ASC-OutputFile.csv
2. Cleanup the ASC-outputFile.csv and remove any servers that you do not want the VA agent installed
3. Save the file as ASC-inputFile.csv
4. Run the Install-VA-VMExtension.ps1

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
