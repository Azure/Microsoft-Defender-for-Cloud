# Join assessment with secure score control
Azure Resource Graph (ARG) provides an efficient way to query at scale across a given set of subscriptions for any Azure Resource (for more information please visit https://docs.microsoft.com/en-us/azure/governance/resource-graph/). This query join assessment with secure score control in ARG.



```

securityresources
| where type == "microsoft.security/assessments"
| extend resourceId=id,
    assessmentKey=name,
    recommendationName=properties.displayName,
    source=properties.resourceDetails.Source,
    recommendationState=properties.status.code,
    description=properties.metadata.description,
    assessmentType=properties.metadata.assessmentType,
    remediationDescription=properties.metadata.remediationDescription,
    policyDefinitionId=properties.metadata.policyDefinitionId,
    implementationEffort=properties.metadata.implementationEffort,
    recommendationSeverity=properties.metadata.severity,
    category=properties.metadata.categories,
    userImpact=properties.metadata.userImpact,
    threats=properties.metadata.threats,
    portalLink=properties.links.azurePortal
| project tenantId, subscriptionId, resourceId, recommendationName, assessmentKey, recommendationState, recommendationSeverity, description, remediationDescription, assessmentType, policyDefinitionId, implementationEffort, userImpact, category, threats, source, portalLink
    | join kind=leftouter (
        securityresources
            | where type == "microsoft.security/securescores/securescorecontrols"
            | extend controlName = tostring(properties.displayName)
            | extend controlKey = tostring(name)
            | extend assessmentDefinitions = properties.definition.properties.assessmentDefinitions
            | mvexpand assessmentDefinitions
            | parse assessmentDefinitions with '{​​​​​​​​"id":"/providers/Microsoft.Security/assessmentMetadata/'assessmentKey'"}​​​​​​​​'
            | extend assessmentKey = tostring(assessmentKey)
            | summarize controlName= max(controlName) by controlKey, assessmentKey, subscriptionId
            | extend packControls = pack(controlName, controlKey)
            | summarize controls = make_bag(packControls) by assessmentKey,subscriptionId
                ) on assessmentKey, subscriptionId      

```
