# Regulatory Compliance Assessments State
Azure Resource Graph (ARG) provides an efficient way to query at scale across a given set of subscriptions for any Azure Resource (for more information please visit https://docs.microsoft.com/en-us/azure/governance/resource-graph/). This query returns regulatory compliance assessments state per compliance standard and control.



```
securityresources
| where type == "microsoft.security/regulatorycompliancestandards/regulatorycompliancecontrols/regulatorycomplianceassessments"
| extend assessmentName=properties.description,
    complianceStandard=extract(@"/regulatoryComplianceStandards/(.+)/regulatoryComplianceControls",1,id),
    complianceControl=extract(@"/regulatoryComplianceControls/(.+)/regulatoryComplianceAssessments",1,id),
    skippedResources=properties.skippedResources,
    passedResources=properties.passedResources,
    failedResources=properties.failedResources,
    state=properties.state
| project tenantId, subscriptionId, id, complianceStandard, complianceControl, assessmentName, state, skippedResources, passedResources, failedResources

```
