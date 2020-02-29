# Azure Security Center
Welcome to the Azure Security Center community repository. This repository contains:
- Security recommendations that are in private preview
- Programmatic remediation tools for security recommendations
- PowerShell scripts for programmatic management
- Azure Policy custom definitions for at-scale management via Azure Policy
- Logic App templates that work with Security Center's Logic App connectors (to automate response to Security alerts and recommendations)

All of the above will help you work programmatically at scale with Azure Security Center and provide you additional security value to secure your environment, some of which has not yet been embedded into the product. You can submit any questions or requests [here](https://github.com/Azure/Azure-Security-Center/issues). 

For questions and feedback, please contact [asc_community@microsoft.com](asc_community@microsoft.com).

# Additional resources

Please visit the following additional resources to learn more about Azure Security and participate in discussions: 

- [Azure Security Center Forum](https://techcommunity.microsoft.com/t5/Azure-Security-Center/bd-p/AzureSecurityCenter)
- [Azure Security Center Blog](https://techcommunity.microsoft.com/t5/Azure-Security-Center/bg-p/AzureSecurityCenterBlog)
- [Azure Security Center Feature suggestion](https://feedback.azure.com/forums/347535-azure-security-center)
- [Azure Security Center documentation](https://docs.microsoft.com/en-us/azure/security-center/security-center-intro)
- [Azure Security Center API documentation](https://docs.microsoft.com/en-us/rest/api/securitycenter/)

# Logic App Playbooks
## Instructions for templatizing a playbook
Once you have created a playbook that you want to export to share, go to the Logic App resource in Azure.
> Note: this is the generic instructions there may be other steps depending how complex or what connectors are used for the playbook.
1. Click Export Template from the resource menu
2. Copy the contents of the template
3. Usig VS code, create a new JSON file
4. Paste the code into the new file
5. In the parameters section, you can remove all parameters and add the following:
```json
    "parameters": {
        "PlaybookName": {
            "defaultValue": "PlaybookName",
            "type": "string"
        },
        "UserName": {
            "defaultValue": "<username>@<domain>",
            "type": "string"
        }
    },
```
* You need a playbook name and username that will be used for the connections.
6. In the variables section, you will need to create a variable for each connection the playbook is using like,
```json
    "variables": {
        "AzureADConnectionName": "[concat('azuread-', parameters('PlaybookName'))]",
        "AzureSentinelConnectionName": "[concat('azuresentinel-', parameters('PlaybookName'))]"
    },
```
* The variables will be the connection names.  Here we are creating a connection name using the connection (AzureAD) and "-" and the playbook name.
7. Next,, you will need to add resources to be created for each connection.
```json
   "resources": [
        {
            "type": "Microsoft.Web/connections",
            "apiVersion": "2016-06-01",
            "name": "[variables('AzureADConnectionName')]",
            "location": "[resourceGroup().location]",
            "properties": {
                "displayName": "[parameters('UserName')]",
                "customParameterValues": {},
                "api": {
                    "id": "[concat('/subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Web/locations/', resourceGroup().location, '/managedApis/azuread')]"
                }
            }
        },
```
* The name is using the variable we created.  The location is using the resource group that was selected as part of the deployment.  The displayname is using the Username parameter. Lastly, you can build the string for the id using strings plus properties of the subscription and resource group. Repeat for each connection needed.
8. In the `Microsoft.Logic/workflows` resource under `paramters / $connections`, there will be a `value` for each connection.  You will need to update each like the following.
```json
"parameters": {
                    "$connections": {
                        "value": {
                            "azuread": {
                                "connectionId": "[resourceId('Microsoft.Web/connections', variables('AzureADConnectionName'))]",
                                "connectionName": "[variables('AzureADConnectionName')]",
                                "id": "[concat('/subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Web/locations/', resourceGroup().location, '/managedApis/azuread')]"
                            },
                            "azuresentinel": {
                                "connectionId": "[resourceId('Microsoft.Web/connections', variables('AzureSentinelConnectionName'))]",
                                "connectionName": "[variables('AzureSentinelConnectionName')]",
                                "id": "[concat('/subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Web/locations/', resourceGroup().location, '/managedApis/azuresentinel')]"
                            }
                        }
                    }
                }

```
* The connectionId will use a string and variable.  The Connection name is the variable/.  The id is the string we used early for the id when creating the resource.
9.  Save the JSON and contribute to the repository.



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
