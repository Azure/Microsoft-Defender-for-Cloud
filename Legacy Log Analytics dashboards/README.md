
# Legacy Log Analytics dashboards

In July 31, 2019, Azure Security Center will retire 3 legacy Log Analytics' dashboards ([learn more](https://docs.microsoft.com/azure/security-center/security-center-features-retirement-july2019)).

The following files provide the Log Analytics' queries used to populate the retired dashboards, in case you'd like to reproduce the data visualized in these dashboards. You're encouraged to review the [retirement documentation](https://docs.microsoft.com/azure/security-center/security-center-features-retirement-july2019) to learn more on suggested alternatives.

- [Identity and access dashboard](./IdentityDashboard.ts)
- [Threat intelligence dashboard (Security events map)](./ThreatIntelligenceDashboard.ts)
- [Security & audit dashboard](./SecurityAndAuditDashboard.ts)

Provided files are in Typescript (.ts) format, which can be opened with any text editor. You can copy the applicable queries from these files to custom dashboards you'll create.

In addition, the notable events dashboard queries are available under "Saved searches" in your workspace. They appear in 3 categories:

- Security Critical Notable Issues
- Security Warning Notable Issues
- Security Info Notable Issues

You can either copy the relevant queries from the "Saved searches" page in your workspace, or visit the [following](./NotableEventsQueries.md) page to view them.

# Questions
You can submit any questions or requests [here](https://github.com/Azure/Azure-Security-Center/issues). Please also refer to our [Wiki](https://github.com/Azure/Azure-Security-Center/wiki#resources), as it will provide you with further information.

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
