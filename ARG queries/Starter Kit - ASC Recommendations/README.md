# Starter Kit - ARG Queries for Azure Security Center Recommendations
Azure Resource Graph (ARG) provides an efficient way to query at scale across a given set of subscriptions for any Azure Resource (for more information please visit https://docs.microsoft.com/en-us/azure/governance/resource-graph/). 
A useful use case is to use ARG to query, visualize or export Azure Security Center (ASC) recommendations in order to get the information that matters most to you.

This starter kit consists of a set of basic ARG queries that have been created to help you build on top of them based on your different needs and requirements.

1. **Get ASC recommendations** in a useful format
```
securityresource
 | where type == "microsoft.security/assessments"
 // Get recommendations in useful format
 | project
    ['TenantID'] = tenantId,
    ['SubscriptionID'] = subscriptionId,
    ['AssessmentID'] = name,
    ['DisplayName'] = properties.displayName,
    ['ResourceType'] = tolower(split(properties.resourceDetails.Id,"/").[7]),
    ['ResourceName'] = tolower(split(properties.resourceDetails.Id,"/").[8]),
    ['ResourceGroup'] = resourceGroup,
    ['ContainsNestedRecom'] = tostring(properties.additionalData.subAssessmentsLink),
    ['StatusCode'] = properties.status.code,
    ['StatusDescription'] = properties.status.description,
    ['PolicyDefID'] = properties.metadata.policyDefinitionId,
    ['Description'] = properties.metadata.description,
    ['RecomType'] = properties.metadata.assessmentType,
    ['Remediation'] = properties.metadata.remediationDescription,
    ['RemediationEffort'] = properties.metadata.implementationEffort,
    ['Severity'] = properties.metadata.severity,
    ['Categories'] = properties.metadata.categories,
    ['UserImpact'] = properties.metadata.userImpact,
    ['Threats'] = properties.metadata.threats,
    ['Link'] = properties.links.azurePortal
```
2. **Get ASC nested recommendations** in useful format
```
securityresources
 | where type == "microsoft.security/assessments/subassessments"
 // Get recommendations in a useful format
 | project 
    ['TenantID'] = tenantId,
    ['SubscriptionID'] = subscriptionId,
    ['ParentAssessmentID'] = split(id,"/").[12],
    ['NestedAssessmentID'] = split(id,"/").[14],
    ['NestedDescription'] = properties.description,
    ['NestedDisplayName'] = properties.displayName,
    ['ResourceType'] = tolower(split(id,"/").[7]),
    ['ResourceName'] = tolower(split(id,"/").[8]),
    ['ResourceGroup'] = resourceGroup,
    ['NestedCategory'] = properties.category,
    ['TimeGenerated'] = properties.timeGenerated,
    ['NestedRemediation'] = properties.remediation,
    ['NestedImpact'] = properties.impact,
    ['NestedAdditionalData'] = properties.additionalData
```
3. **Get ASC parent + nested recommendations combined** (best to filter by resource or resource group to get less results)
```
securityresources
 | where type == "microsoft.security/assessments"
 // Get recommendations in useful format
 | project
    ['ParentAssessmentID'] = name,
    ['TenantID'] = tenantId,
    ['SubscriptionID'] = subscriptionId,
    ['DisplayName'] = properties.displayName,
    ['ResourceType'] = tolower(split(properties.resourceDetails.Id,"/").[7]),
    ['ResourceName'] = tolower(split(properties.resourceDetails.Id,"/").[8]),
    ['ResourceGroup'] = resourceGroup,
    ['StatusCode'] = properties.status.code,
    ['StatusDescription'] = properties.status.description,
    ['PolicyDefID'] = properties.metadata.policyDefinitionId,
    ['Description'] = properties.metadata.description,
    ['RecomType'] = properties.metadata.assessmentType,
    ['Remediation'] = properties.metadata.remediationDescription,
    ['RemediationEffort'] = properties.metadata.implementationEffort,
    ['Severity'] = properties.metadata.severity,
    ['Categories'] = properties.metadata.categories,
    ['UserImpact'] = properties.metadata.userImpact,
    ['Threats'] = properties.metadata.threats,
    ['Link'] = properties.links.azurePortal
    // Filter get less results
        // | where ResourceName == "ntierapp-vm-web"
    // Joining Parentassessment + Nestedassessment table
    | join kind=leftouter (
        securityresources
            | where type == "microsoft.security/assessments/subassessments"
            | extend ['ParentAssessmentID'] = tostring(split(id,"/").[12]),
                     ['ResourceName'] = tolower(split(id,"/").[8]),
                     ['NestedAssessmentID'] = tostring(split(id,"/").[14]),
                     ['NestedDescription'] = properties.description,
                     ['NestedDisplayName'] = properties.displayName,
                     ['NestedCategory'] = properties.category,
                     ['TimeGenerated'] = properties.timeGenerated,
                     ['NestedRemediation'] = properties.remediation,
                     ['NestedImpact'] = properties.impact,
                     ['NestedAdditionalData'] = properties.additionalData
                     //| where ResourceName == "ntierapp-vm-web"
        ) on ParentAssessmentID
        | project TenantID, SubscriptionID, ParentAssessmentID, NestedAssessmentID, DisplayName, NestedDisplayName, Description, NestedDescription, ResourceType, ResourceName, ResourceGroup, StatusCode, StatusDescription, RecomType, Severity, Threats, RemediationEffort, Remediation, NestedRemediation, UserImpact, NestedImpact, Categories, NestedCategory, TimeGenerated, PolicyDefID, Link
```
4. **Get ASC Current Pricing Tiers**
```
securityresources
| where type == "microsoft.security/pricings"
// Project in useful format
| project 
    ['SubscriptionID'] = subscriptionId,
    ['TenantID'] = tenantId,
    ['Service'] = name,
    ['PricingTier'] = properties.pricingTier,
    ['FreeTrialRemainingTime'] = properties.freeTrialRemainingTime
// filter by subscription
// | where SubscriptionID == '<SubscriptionID>'
```
5. **Create your own dashboards** or visualization charts

Apart from querying and exporting your results, ARG provides the ability to create charts and dashboards directly from the Azure Resource Graph Explorer console and even pin them directly into your Azure Portal.

![Image of ASCRecom-CustomDashboard](https://github.com/carlosfar/public/blob/master/Azure%20Security%20Center/ARG-Queries/ASCRecommendations-ChartCreation.png)

For this particular example, we will focus on all the recommendations that have been classified as **High Severity** and **Low Remediation Effort** by ASC in order to help prioritize work on what’s important and easy to remediate. As a starting point we have used the following ARG query:

```
securityresources
 | where type == "microsoft.security/assessments"
 // Get recommendations in useful format
 | project
    ['TenantID'] = tenantId,
    ['SubscriptionID'] = subscriptionId,
    ['AssessmentID'] = name,
    ['DisplayName'] = properties.displayName,
    ['ResourceType'] = tolower(split(properties.resourceDetails.Id,"/").[7]),
    ['ResourceName'] = tolower(split(properties.resourceDetails.Id,"/").[8]),
    ['ResourceGroup'] = resourceGroup,
    ['ContainsNestedRecom'] = tostring(properties.additionalData.subAssessmentsLink),
    ['StatusCode'] = properties.status.code,
    ['StatusDescription'] = properties.status.description,
    ['PolicyDefID'] = properties.metadata.policyDefinitionId,
    ['Description'] = properties.metadata.description,
    ['RecomType'] = properties.metadata.assessmentType,
    ['Remediation'] = properties.metadata.remediationDescription,
    ['RemediationEffort'] = properties.metadata.implementationEffort,
    ['Severity'] = properties.metadata.severity,
    ['Categories'] = properties.metadata.categories,
    ['UserImpact'] = properties.metadata.userImpact,
    ['Threats'] = properties.metadata.threats,
    ['Link'] = properties.links.azurePortal
// Filter
 | where Severity == "High"
 | where RemediationEffort == "Low"
 // | where ResourceName == "ntierapp-vm-web"
// summarize and order
 | summarize count() by tostring(Threats)
 | order by count_
 ```
By tweaking the previous query, we have been able to build different views summarizing ***threat vectors identified, type of impacted resources, list of recommendations, list of impacted resources, impacted subscriptions by threat vector, impacted resource group by threat vector.***
 
![Image of ASCRecom-CustomDashboard](https://github.com/carlosfar/public/blob/master/Azure%20Security%20Center/ARG-Queries/ASCRecommendationsCustomDashboard.png)
