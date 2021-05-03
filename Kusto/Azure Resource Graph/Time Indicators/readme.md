# Time Indicators
Azure Resource Graph (ARG) provides an efficient way to query at scale across a given set of subscriptions for any Azure Resource (for more information please visit https://docs.microsoft.com/en-us/azure/governance/resource-graph/). This query leverages time indicator fields (*firstEvalutationDate* and *statusChangeDate*) to show resources that recently changed their assessment status to unhealthy.

```Kusto
securityresources
| where type =~ "microsoft.security/assessments"
| extend assessmentStatusCode = tostring(properties.status.code)
| where assessmentStatusCode =~ "unhealthy"
| extend firstEvaluationDate = todatetime(properties.status.firstEvaluationDate)
| extend statusChangeDate = todatetime(properties.status.statusChangeDate)
| where statusChangeDate > firstEvaluationDate
```
