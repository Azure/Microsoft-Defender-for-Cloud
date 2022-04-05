# Microsoft Defender for Cloud exempt and disabled recommendations
Azure Resource Graph (ARG) provides an efficient way to query at scale across a given set of subscriptions for any Azure Resource (for more information please visit https://docs.microsoft.com/en-us/azure/governance/resource-graph/). This query returns a list of the Azure Resources that have recommendations that are Exempt due to Waiver or Mitigation and also Policy being disabled. Can be used as a quick report for auditors or tracking down exemptions and disabled policies for review.



```
securityresources
        | where type == "microsoft.security/assessments"
        | extend source = tostring(properties.resourceDetails.Source)
        | extend resourceId =
            trim(" ", tolower(tostring(case(source =~ "azure", properties.resourceDetails.Id,
                                            source =~ "aws", properties.resourceDetails.AzureResourceId,
                                            source =~ "gcp", properties.resourceDetails.AzureResourceId,
                                            extract("^(.+)/providers/Microsoft.Security/assessments/.+$",1,id)))))
        | extend status = trim(" ", tostring(properties.status.code))
        | extend cause = trim(" ", tostring(properties.status.cause))
        | extend assessmentKey = tostring(name)
		| where cause == "Exempt" or cause == "OffByPolicy"
		| extend ResourceName = tostring(split(resourceId,'/')[8]), RecommendationName = tostring(properties.displayName), Source = properties.resourceDetails.Source, StatusCause = tostring(properties.status.cause), StatusDescription = properties.status.description, RecommendationSeverity = tostring(properties.metadata.severity)
		| project RecommendationName, RecommendationSeverity, ResourceName, StatusCause, StatusDescription, resourceGroup, Source, subscriptionId
		| sort by RecommendationSeverity, RecommendationName
```
