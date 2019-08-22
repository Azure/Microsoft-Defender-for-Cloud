# Security Event collection tier

This sample snippet provides you with the ability to configure Azure Security Center's security event collection tier. To learn more about data collection in Security Center, please visit the [documentation page](https://docs.microsoft.com/en-us/azure/security-center/security-center-enable-data-collection).

*The below snippets require retrieving an Azure Authorization token. To do via PowerShell, please see visit the following [article](../Authorization%20token%20retrieval%20for%20REST%20APIs/README.md).*


## Users of Security Center's default (managed) workspaces
In case you're collecting data to [default workspaces](https://docs.microsoft.com/azure/security-center/security-center-enable-data-collection#using-a-workspace-created-by-security-center) (Security Center's managed Log Analytics workspaces), you can use the following code snippet:

```
Connect-AzAccount

# Set Subscription ID, Workspace Name and Resource Group Name as required

$subscriptionId = "<SubscriptionId>"
 
# Set Security Event Collection Tier to "None", "Minimal", "Recommended" or "All"
 
$securityEventCollectionTier = "Minimal"
 
$properties = @{"Tier" = $securityEventCollectionTier}
$body = @{}
$body.Add("properties",$properties)
 
$jsonBody = $body | ConvertTo-Json
 
$RESTURI = "https://management.azure.com/subscriptions/" + $subscriptionId + "providers/Microsoft.Security/policies/default/securityEventCollection/defaultSecurityEventCollection?api-version=2015-06-01-preview"

Invoke-RestMethod -Uri $RESTURI -Method PUT -Headers $requestHeader -Body $jsonBody
```

(`requestHeader` should be generated via this [article](../Authorization%20token%20retrieval%20for%20REST%20APIs/README.md))

## Users of an existing user workspace
In case you're collecting data to an existing [user workspace](https://docs.microsoft.com/azure/security-center/security-center-enable-data-collection#using-an-existing-workspace), please use the following code snippet:

```
Connect-AzAccount

# Set Subscription ID, Workspace Name and Resource Group Name as required

$subscriptionId = "<SubscriptionId>"
$workspaceName = "<WorkspaceName>"
$workspaceResourceGroup = "<ResourceGroupName>"
 
# Set Security Event Collection Tier to "None", "Minimal", "Recommended" or "All"
 
$securityEventCollectionTier = "Minimal"
 
$properties = @{"Tier" = $securityEventCollectionTier, "TierSetMethod" = "Custom"}
$body = @{kind = "SecurityEventCollectionConfiguration"}
$body.Add("properties",$properties)
 
$jsonBody = $body | ConvertTo-Json
 
$RESTURI = "https://management.azure.com/subscriptions/" + $subscriptionId + `
    "/resourcegroups/" + $workspaceResourceGroup + "/providers/Microsoft.OperationalInsights/Workspaces/" + $workspaceName + `
    "/datasources/SecurityEventCollectionConfiguration?api-version=2015-11-01-preview"

Invoke-RestMethod -Uri $RESTURI -Method PUT -Headers $requestHeader -Body $jsonBody
```

(`requestHeader` should be generated via this [article](../Authorization%20token%20retrieval%20for%20REST%20APIs/README.md))

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
