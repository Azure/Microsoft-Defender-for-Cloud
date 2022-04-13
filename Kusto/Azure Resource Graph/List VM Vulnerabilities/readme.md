Azure Resource Graph (ARG) provides an efficient way to query at scale across a given set of subscriptions for any Azure Resource (for more information please visit https://docs.microsoft.com/en-us/azure/governance/resource-graph/). 

This query returns all General Vulnerabilities for your Virtual Machines. 
```
securityresources
| where type =~ "microsoft.security/assessments/subassessments"
| extend assessmentKey=extract("providers/Microsoft.Security/assessments/([^/]*)", 1, id), subAssessmentId=tostring(properties.id)
| where assessmentKey == "4ab6e3c5-74dd-8b35-9ab9-f61b30875b27"
| extend subAssessmentName=tostring(properties.displayName), resourceId = tostring(properties.resourceDetails.id)
| project
	resourcedId = properties.resourceDetails.id,
	subAssessmentName = properties.displayName,
	cve = properties.additionalData.data.CVENumbers,
	category = properties.category,
	severity = properties.status.severity,
	remediation = properties.remediation
| order by tostring(severity) asc
```

This query returns all Server Vulnerabilities for your Virtual Machines.
```
securityresources
| where type =~ "microsoft.security/assessments/subassessments"
| extend assessmentKey=extract("providers/Microsoft.Security/assessments/([^/]*)", 1, id), subAssessmentId=tostring(properties.id)
| where assessmentKey == "1195afff-c881-495e-9bc5-1486211ae03f"
| extend subAssessmentName=tostring(properties.displayName), resourceId = tostring(properties.resourceDetails.id)
| project
	resourcedId = properties.resourceDetails.id,
	subAssessmentName = properties.displayName,
	threat = properties.additionalData.threat,
	severity = properties.status.severity,
	remediation = properties.remediation
| order by tostring(severity) asc
```

This query returns all SqlServer Vulnerabilities.
```
securityresources
| where type =~ "microsoft.security/assessments/subassessments"
| extend assessmentKey=extract("providers/Microsoft.Security/assessments/([^/]*)", 1, id), subAssessmentId=tostring(properties.id)
| where assessmentKey == "82e20e14-edc5-4373-bfc4-f13121257c37"
| extend subAssessmentName=tostring(properties.displayName), resourceId = tostring(properties.resourceDetails.id)
| project
	resourcedId = properties.resourceDetails.id,
	subAssessmentName = properties.displayName,
	category = properties.category,
	severity = properties.status.severity,
	impact = properties.impact,
	remediation = properties.remediation
| order by tostring(severity) asc
```

If you wonder what the AssessmentId's mean/do, check below table:

| AssessmentId                         | Assessed ResourceType  |
| ------------------------------------ | ---------------------- |
| 1195afff-c881-495e-9bc5-1486211ae03f | ServerVulnerability    |
| 4ab6e3c5-74dd-8b35-9ab9-f61b30875b27 | GeneralVulnerability   |
| 82e20e14-edc5-4373-bfc4-f13121257c37 | SqlServerVulnerability |
