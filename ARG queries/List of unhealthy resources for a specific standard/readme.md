# List of unhealthy resources for a specific standard
Azure Resource Graph (ARG) provides an efficient way to query at scale across a given set of subscriptions for any Azure Resource (for more information please visit https://docs.microsoft.com/en-us/azure/governance/resource-graph/). This query returns the list of unhealthy resources for a specific standard, in this case Azure-CIS-1.1.0-(New).



```

securityresources
    | where type == "microsoft.security/regulatorycompliancestandards/regulatorycompliancecontrols/regulatorycomplianceassessments"
    | parse id with * "/regulatoryComplianceStandards/" standard "/regulatoryComplianceControls/" controlId "/regulatoryComplianceAssessments/" assessmentKey
    | where standard =~ "Azure-CIS-1.1.0-(New)"
       | where properties.state == "Failed"
    | distinct controlId, assessmentKey
    | join kind=inner (
       securityresources
       | where type == "microsoft.security/assessments"
       | parse id with * "/Microsoft.Security/assessments/" assessmentKey
       | extend resourceId = tolower(properties.resourceDetails.Id)
       | extend assessmentName = tolower(properties.displayName)
       | distinct assessmentKey, resourceId, assessmentName
    ) on assessmentKey
    | distinct controlId, assessmentKey, resourceId, assessmentName


```
