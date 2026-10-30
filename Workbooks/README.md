# Azure  Workbooks for Microsoft Defender for Cloud

![GitHub](https://img.shields.io/github/license/azure/Microsoft-Defender-for-Cloud?label=License&style=plastic)

This project contains **Azure Workbook templates** you can use to create custom dashboards within Microsoft Defender for Cloud. The workbooks can be deployed as ARM templates to your Defender for Cloud environment.

## Defender for APIs cost estimation

The [Defender for APIs cost estimator](./Microsoft%20Defender%20for%20APIs%20Cost%20Estimation/README.md)
uses Storage-style scope selectors with coverage, API inventory and cost
estimation together on one page.
Import [D4ApisDeployment.json](./Microsoft%20Defender%20for%20APIs%20Cost%20Estimation/D4ApisDeployment.json)
directly, or deploy [armTemplate.json](./Microsoft%20Defender%20for%20APIs%20Cost%20Estimation/armTemplate.json).
All live coverage, API inventory and 30-day plan queries are embedded, with optional
Log Analytics for multi-service comparisons. No PowerShell, build step or uploaded
snapshot is required. The
[PowerShell estimator](../Powershell%20scripts/Defender%20APIs%20Cost%20Estimator/d4apis_cost_estimator_v1.ps1)
is an independent, optional CSV/JSON reporting tool.

## Contributing

Anyone can contribute, you don't need to be a pro. You have an interesting query or workbook? Then fork this repository, add your content to your fork and submit a pull request. See our [Contribution Guideline](../Contributing.md) for more details.

In addition to the overall contribution guideline, please make sure to adhere to the following aspects when submitting a new workbook:

1. Add a **screenshot** of the workbook
2. Ensure all steps have **meaningful names**
3. Ensure all parameters and grid columns have **display names** set so they can be localized
4. Ensure that parameter ID values are **unique**
5. Ensure that steps names are **unique**
6. Grep /subscription/ and ensure that your parameters don't have **any hardcoded resourceIds**
7. Add the fromTemplateId property to the workbook's gallery template and include your workbook name. for example: Network Security Dashboard should be: ```"fromTemplateId": "NetworkSecurityDashboard"```.



## How to create a .workbook file

There are three ways of creating a template:

- Create a new template based on an empty workbook.
- Create a new template based on an existing template. You can modify or enhance the existing template.
- Create a new template from an existing report. You can modify or enhance the existing report.

### Create from an empty workbook

1. Go to <https://portal.azure.com>
2. Select Microsoft Defender for Cloud from the navigation menu
3. Select "Workbooks"
4. Select the Empty workbook in the Quick Start section.
    ![Image of default template](./Images//emptyTemplate.png)
5. Modify report as you wish and click "Advanced Editor" button from the menu.
    ![Image of toolbar](./Images/toolbar-advancedEditor.png)
6. Use the download button or copy all contents and create a file like `your custom template name.workbook`.
   Make sure the filename ends with `.workbook` and avoid using any special characters (like `/\&?`) in your filename.
    ![advanced editor](./Images/advancedEditor.png)

### Create from an existing template

1. Go to <https://portal.azure.com>
2. Select Microsoft Defender for Cloud from the navigation bar.
3. Select "Workbooks"
4. Select a template you are interested in editing.
5. Modify as you wish and click "Advanced Editor" button from the menu.
6. Use the download button, or copy contents and create a file like `your custom template name.workbook`.
   Make sure the filename ends with `.workbook` and avoid using any special characters (like `/\&?`) in your filename.

### Create from a saved workbook

1. Go to <https://portal.azure.com>
2. Select Microsoft Defender for Cloud from the navigation bar.
3. Select "Workbooks"
4. Click on the Open icon from the menu.
   ![Image of the toolbar](./Images/openWorkbook.png)
5. Select a desired saved workbook you want to start with.
6. Modify the workbook as you wish and click the "Advanced Editor" button from the menu.
7. Use the download button, or copy contents and create a file like `your custom template name.workbook`. Make sure the filename ends with `.workbook` and avoid using any special characters (like `/\&?`) in your filename.
