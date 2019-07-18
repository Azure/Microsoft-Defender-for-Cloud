
# Reset security configurations customization

## Background

In July 31, 2019, Azure Security Center will retire the ability to edit security configurations for security policies (the ability to customize the default OS security configuration rules in Security Center) ([learn more](https://docs.microsoft.com/azure/security-center/security-center-features-retirement-july2019)).

Security Center is planned to support the Guest configuration agent. Such an update will allow a much richer feature set, including support for more operating systems and integration of Azure in-guest policies for guest configurations. After these changes are enabled, you'll also have the ability to control configurations at scale and apply them to new resources automatically.

Following the deprecation date (July 31, 2019), you will no longer be able to modify or reset you OS security configuration via Azure Security Center in the Azure Portal. You can reset your already-customized configuration to the default, by following the steps below.

## Retrieve authorization token

To retrieve Authorization token for Azure Resource Manager API, please follow the steps detailed here: [Azure authorization token retrieval](../Authorization&#32;token&#32;retrieval&#32;for&#32;REST&#32;APIs/README.md).

## Resetting customized security configurations

In order to reset your already customized configuration on a given Azure subscription, please invoke the following REST API (by Powershell or via any REST client):

```
$properties = @{"policyLevel" = "Subscription"}
$properties.Add("name", "defaultBaselineConfiguration")
$properties.Add("configurationStatus", "Default")
$body = @{}
$body.Add("properties", $properties)
$jsonBody = $body | ConvertTo-Json

$requestHeader = @{
  "Authorization" = "AUTHORIZATION_TOKEN"
  "Content-Type" = "application/json"
}

$subscriptionId = "SUBSCRIPTION_ID"
$restUri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/Microsoft.Security/policies/default/baselineconfigurations/defaultBaselineConfiguration?api-version=2015-06-01-preview"

Invoke-RestMethod -Uri $restUri -Method 'Put' -Headers $requestHeader -Body $jsonBody
```

Alternatively, invoke the following REST API directly:

**URL:** https://management.azure.com/subscriptions/SUBSCRIPTION_ID_HERE/providers/Microsoft.Security/policies/default/baselineconfigurations/defaultBaselineConfiguration?api-version=2015-06-01-preview

**Request type:** PUT

**Request body:**
```
{
	"properties": {
		"policyLevel": "Subscription",
		"name": "defaultBaselineConfiguration",
		"configurationStatus": "Default"
	}
}
```

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
