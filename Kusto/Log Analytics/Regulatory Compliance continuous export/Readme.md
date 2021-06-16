# Continuous Export of Regulatory Compliance - sample queries
With Continuous Export of Regulatory Compliance, you can stream changes of [Regulatory Compliance assessments](https://docs.microsoft.com/en-gb/rest/api/securitycenter/regulatorycomplianceassessments) in real-time . This will enable you to track your Regulatory Compliance over time and build dynamic reports, export your Regulatory Compliance data to SIEM, and integrate this data types with any processes you might already be using to monitor Regulatory Compliance in your organization.

## Sample queries for Log Analytics workspace 
When consuming regulatory compliance data from a Log Analytics workspace, you might like to further analyze the data. Below are a few common queries. You can follow the steps below to use them:
 
1. In Azure Portal, navigate to the Log Analytics workspace to which you enabled continuous export. 
2. Click on Logs. 
3. Copy and paste a query from the samples described below. 
4. Set the desired Time range. 
5. Click Run. 

### Sample queries

```
//Summarize resource health per compliance standard, control and recommendation 
SecurityRegulatoryCompliance  
| summarize sum(SkippedResources), sum(PassedResources), sum(FailedResources) by RegulatoryComplianceSubscriptionId, RecommendationName, ComplianceStandard, ComplianceControl 
```

```
//Get remediation description, portal link, severity and additional information per recommendation, by resource 
SecurityRegulatoryCompliance  
| extend SubscriptionId=RegulatoryComplianceSubscriptionId 
| join kind=inner (SecurityRecommendation 
| extend SubscriptionId=(extract(@"/subscriptions/(.+)/resourceGroups", 1, AssessedResourceId) 
)) on SubscriptionId, RecommendationId 
| project TenantId, TimeGenerated, AssessedResourceId, RecommendationId, RecommendationName, State, ComplianceStandard, ComplianceControl,Description, RemediationDescription, RecommendationAdditionalData, RecommendationSeverity, RecommendationState, RecommendationLink 
```

```
//Timechart to track non-compliant resources by subscription and compliance standard 
SecurityRegulatoryCompliance  
| summarize sum(FailedResources) by bin(TimeGenerated,1d),RegulatoryComplianceSubscriptionId, ComplianceStandard 
| render timechart
```