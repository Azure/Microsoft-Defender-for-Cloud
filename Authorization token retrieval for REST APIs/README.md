# Authorization token retrieval for REST APIs

Often times, when invoking REST commands to Azure directly from PowerShell (with `Invoke-RestMethod`) or via REST clients, you'll need to have the Azure authorization token to query Azure Resource Manager. to do so , the following PowerShell snippet may assist in retrieving the token:

```
$subscriptionId = '212f9889-769e-45ae-ab43-6da33674bd26'
$rmAccount = Add-AzureRmAccount -SubscriptionId $subscriptionId
$tenantId = (Get-AzureRmSubscription -SubscriptionId $subscriptionId).TenantId
$tokenCache = $rmAccount.Context.TokenCache
$cachedTokens = $tokenCache.ReadItems() `
        | where { $_.TenantId -eq $tenantId } `
        | Sort-Object -Property ExpiresOn -Descending
$accessToken = $cachedTokens[0].AccessToken
$requestHeader = @{
  "Authorization" = "Bearer " + $accessToken
  "Content-Type" = "application/json"
}
```
With the above, you can use `$requestHeader` as the HTTP request headers as part of `Invoke-RestMethod`.

For more information, please view [Azure API Management REST API Authentication](https://docs.microsoft.com/en-us/rest/api/apimanagement/apimanagementrest/azure-api-management-rest-api-authentication).
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
