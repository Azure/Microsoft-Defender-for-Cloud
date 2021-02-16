# Azure  Workbooks for Azure Security Center

![GitHub](https://img.shields.io/github/license/azure/azure-security-center?label=License&style=plastic)

This project contains **Azure Workbook templates** you can use to create custom dashboards within Azure Security Center. The workbooks can be deployed as ARM templates to your Azure Security Center environment.

## Contributing

Anyone can contribute, you don't need to be a pro. You have an interesting query or workbook? Then fork this repo, add your content to your fork and submit a pull request. See our [Contribution Guideline](../Contributing.md) for more details.

In addition to the overall contribution guideline, please make sure to adhere to the following aspects when submitting a new workbook:

1. Add a **screenshot** of the workbook
2. Ensure all steps have **meaningful names**
3. Ensure all parameters and grid columns have **display names** set so they can be localized
4. Ensure that parameters id values are **unique**
5. Ensure that steps names are **unique**
6. Grep /subscription/ and ensure that your parameters don't have **any hardcoded resourceIds**
7. Remove **fallbackResourceIds** and **fromTemplateId** fields from your template workbook
