# KQL queries used in the workbook:

## Workspaces
    resources
    | where type =~ 'microsoft.operationalinsights/workspaces'
    | project id

## Total assessed resources
    securityresources
    | where type =~ "microsoft.security/assessments"
    | extend source =tostring(properties.resourceDetails.Source)
    | extend resourceId = trim(" ", tolower(tostring(case(source =~ "azure", properties.resourceDetails.Id,
                                                                                source =~ "aws", properties.resourceDetails.AzureResourceId,
                                                                                source =~ "gcp", properties.resourceDetails.AzureResourceId,
                                                                                ""))))
    |distinct resourceId
    |summarize Count=count()

## Current Secure Score
    SecurityResources 
    | where type == 'microsoft.security/securescores' 
    | extend CurrentScore = properties.score.current
    | project  CurrentScore

## Max score
    SecurityResources 
    | where type == 'microsoft.security/securescores' 
    | extend MaxScore = todouble(properties.score.max)
    | project  MaxScore

## Percentage secure score
    SecurityResources 
    | where type == 'microsoft.security/securescores' 
    | extend Current_Score = properties.score.current, Max_Score = todouble(properties.score.max)
    | project Percentage = ((Current_Score / Max_Score)*100)

## Total unhealthy resources
    securityresources
    | where type == 'microsoft.security/assessments' 
    | extend RecommendationState=properties.status.code
    | where  RecommendationState=='Unhealthy'
    |distinct tolower(tostring(properties.resourceDetails.Id))
    |summarize Count=count() 

## Total no. of recommendations
    securityresources
    | where type == 'microsoft.security/assessments'
    | extend RecommendationName=properties.displayName, RecommendationState=properties.status.code
    | summarize Count=count()

## Total no. of active security alerts
      securityresources
      | where type =~ 'microsoft.security/locations/alerts'
      | where properties.Status in ('Active')
      | where properties.Severity in ('Low', 'Medium', 'High')
      | summarize Count=count()

## Current secure score over time
    SecureScores
    | extend Percent=PercentageScore*100,CurrentScore
    | extend Day = startofday(TimeGenerated) 
    |summarize avg(CurrentScore) by Day

## Percentage secure score over time
    SecureScores
    | extend Percent=PercentageScore*100
    | extend Day = startofday(TimeGenerated) 
    |summarize avg(Percent) by Day

## Resource Health against secure control
    SecureScoreControls
    | extend ResourceName = (tostring(split(AssessedResourceId, "/")[8]))
    | extend ResourceGroupName = (tostring(split(AssessedResourceId, "/")[4]))//
    | summarize arg_max(TimeGenerated, *) by ControlName
    | project  ControlName,
                HealthyResources,
                UnhealthyResources,
                NotApplicableResources

## Number of resources under a recommendation
    securityresources
    | where type == 'microsoft.security/assessments'
    | extend resourceId=id,
        recommendationName=properties.displayName,
        recommendationState=properties.status.code
    | summarize numberOfResources=count(resourceId) by tostring(recommendationName), tostring(recommendationState)


## Descriptive analysis of recommendations 
    securityresources
    | where type == 'microsoft.security/assessments'
    | extend RecommendationName=properties.displayName,
        RecommendationState=properties.status.code,
        Description=properties.metadata.description,
        RemediationDescription=properties.metadata.remediationDescription,
        RecommendationSeverity=properties.metadata.severity,
        id=properties.resourceDetails.Id,
        Category=properties.metadata.categories
    | project  RecommendationName,ResourceName=tolower(tostring(properties.resourceDetails.Id)), RecommendationState, RecommendationSeverity,Category,RemediationDescription

## Standards applied on a selected subscription
    securityresources
        | where type == "microsoft.security/regulatorycompliancestandards/regulatorycompliancecontrols/regulatorycomplianceassessments"
        | extend ComplianceStandard = replace( "-", " ", extract(@'/regulatoryComplianceStandards/([^/]*)', 1, id))
      |distinct ComplianceStandard

  ## Compliance state per compliance standard
    securityresources
    | where type == 'microsoft.security/regulatorycompliancestandards'
    | extend complianceStandard=name,
        state=properties.state,
        passedControls=toint(properties.passedControls),
        failedControls=toint(properties.failedControls),
        skippedControls=toint(properties.skippedControls),
        unsupportedControls=toint(properties.unsupportedControls)
    | project complianceStandard, passedControls, failedControls, skippedControls, unsupportedControls

## Descriptive analysis of compliance assessments
    securityresources
    | where type == "microsoft.security/regulatorycompliancestandards/regulatorycompliancecontrols/regulatorycomplianceassessments"
    | extend complianceStandardId = replace( "-", " ", extract(@'/regulatoryComplianceStandards/([^/]*)', 1, id))
    | extend failedResources = toint(properties.failedResources), passedResources = toint(properties.passedResources),skippedResources = toint(properties.skippedResources)
    | where failedResources + passedResources + skippedResources > 0 or properties.assessmentType == "MicrosoftManaged"
    | join kind = leftouter(
    securityresources
    | where type == "microsoft.security/assessments") on subscriptionId, name
    | extend complianceState = tostring(properties.state)
    | extend resourceSource = tolower(tostring(properties1.resourceDetails.Source))
    | extend recommendationId = iff(isnull(id1) or isempty(id1), id, id1)
    | extend resourceId = trim(' ', tolower(tostring(case(resourceSource =~ 'azure', properties1.resourceDetails.Id,
                                                        resourceSource =~ 'gcp', properties1.resourceDetails.GcpResourceId,
                                                        resourceSource =~ 'aws', properties1.resourceDetails.AwsResourceId,
                                                        extract('^(.+)/providers/Microsoft.Security/assessments/.+$',1,recommendationId)))))
    | extend regexResourceId = extract_all(@"/providers/[^/]+(?:/([^/]+)/[^/]+(?:/[^/]+/[^/]+)?)?/([^/]+)/([^/]+)$", resourceId)[0]
    | extend resourceType = iff(regexResourceId[1] != "", regexResourceId[1], iff(regexResourceId[0] != "", regexResourceId[0], "subscriptions"))
    | extend resourceName = tostring(regexResourceId[2])
    | extend recommendationName = name
    | extend recommendationDisplayName = tostring(iff(isnull(properties1.displayName) or isempty(properties1.displayName), properties.description, properties1.displayName))
    | extend description = tostring(properties1.metadata.description)
    | extend remediationSteps = properties1.metadata.remediationDescription
    | extend severity = tostring(properties1.metadata.severity)
    | extend state = tostring(properties1.status.code)
    | extend notApplicableReason = tostring(properties1.status.cause)
    | extend azurePortalRecommendationLink = tostring(properties1.links.azurePortal)
    | extend complianceStandardId = replace( "-", " ", extract(@'/regulatoryComplianceStandards/([^/]*)', 1, id))
    | extend complianceControlId = extract(@"/regulatoryComplianceControls/([^/]*)", 1, id)
    | project complianceStandardId, complianceControlId, complianceState, resourceName, recommendationDisplayName, remediationSteps, severity, state
    | join kind = leftouter (securityresources
    | where type == "microsoft.security/regulatorycompliancestandards/regulatorycompliancecontrols"
    | extend complianceStandardId = replace( "-", " ", extract(@'/regulatoryComplianceStandards/([^/]*)', 1, id))
    | extend  controlName = tostring(properties.description)
    | project controlId = name, controlName
    | distinct  *) on $right.controlId == $left.complianceControlId
     | project complianceStandardId, complianceControlId, controlName,resourceName, complianceState,severity, state,  recommendationDisplayName, tostring(remediationSteps)
    | distinct *
 
        
  ## Alerts descriptive analysis
      securityresources
      | where type =~ 'microsoft.security/locations/alerts'
      | where properties.Status in ('Active')
      | extend SeverityRank = case(
        properties.Severity == 'High', 3,
        properties.Severity == 'Medium', 2,
        properties.Severity == 'Low', 1,
        0
        )
    |extend ResourceType=properties.Entities[0].HostName,RemediationSteps=properties.RemediationSteps,Alert= properties.AlertDisplayName,TimeGenerated=properties.TimeGeneratedUtc
    | sort by  SeverityRank desc, tostring(properties.SystemAlertId) asc
    | project Alert,TimeGenerated,ResourceType,properties.Severity, RemediationSteps


## Unhealthy machines under vulnerabilities assessments
    securityresources
    | where type == "microsoft.security/assessments/subassessments"
    | extend assessmentKey = extract(".*assessments/(.+?)/.*",1,  id)
    //Vulnerabilities in your virtual machines should be remediated
    | where assessmentKey == "1195afff-c881-495e-9bc5-1486211ae03f"
    | project ResourceType=tostring(split(id,"/").[6]), ResourceName=tostring(properties.resourceDetails.id)
    | summarize Count=dcount(ResourceName) by ResourceType

## Unhealthy container registries under vulnerabilities assessments
    securityresources
    | where type == "microsoft.security/assessments/subassessments"
    | extend assessmentKey = extract(".*assessments/(.+?)/.*",1,  id)
    | where assessmentKey == "dbd0cb49-b563-45e7-9724-889e799fa648"
    | project ResourceType=tolower(split(id,"/").[6]), resourceName=tolower(split(id,"/").[8]), Status = tostring(properties.status.code)
    | where Status == 'Unhealthy'
    | summarize Count=dcount(resourceName) by ResourceType

## Unhealthy SQL resources under vulnerabilities assessments
    securityresources
     | where type == "microsoft.security/assessments"
     | where name == "f97aa83c-9b63-4f9a-99f6-b22c4398f936" or name == "82e20e14-edc5-4373-bfc4-f13121257c37"
     | project ResourceType=tolower(split(id,"/").[6]), resourceName=tolower(split(id,"/").[8])
     | summarize Count=dcount(resourceName) by ResourceType
 
 ## Resource health under system updates
     securityresources
    | where type == "microsoft.security/assessments"
    | where name == "4ab6e3c5-74dd-8b35-9ab9-f61b30875b27"
    | project state = tostring(properties.status.code)
    | summarize ResourcesCount = count() by tostring(state)

## Count of Unhealthy machines by Operating System Type
     securityresources
    | where type == "microsoft.security/assessments"
    | where name == "4ab6e3c5-74dd-8b35-9ab9-f61b30875b27"
    | extend ResourceId = extract("^(.+)/providers/Microsoft.Security/assessments/.+$",1,id)
    | project state = tostring(properties.status.code), ResourceId = tolower(tostring(ResourceId))
    | where state == "Unhealthy"
    | join kind=inner (
        securityresources 
        | where type == "microsoft.security/assessments/subassessments"
    | extend Name = extract(".*assessments/(.+?)/.*",1,  id) 
    | where Name == "4ab6e3c5-74dd-8b35-9ab9-f61b30875b27" 
    | extend State = tostring(properties.status.code), ResourceId = tolower(tostring(properties.resourceDetails.id)), OsType = tostring(properties.additionalData.data.OsType)) on ResourceId
    | summarize UnhelathyMachinesByOperatingSystemCount = dcount(ResourceId) by OsType

## Count of Missing Updates by Severity
    securityresources
    | where type == "microsoft.security/assessments/subassessments"
    | extend assessmentKey = extract(".*assessments/(.+?)/.*",1,  id), severity = tostring(properties.status.severity)
    | where assessmentKey == "4ab6e3c5-74dd-8b35-9ab9-f61b30875b27" and properties.status.code == "Unhealthy"
    | summarize AssessmentsCount = count() by severity

## List of Missing System Updates
    securityresources
    | where type == "microsoft.security/assessments/subassessments"
    | extend assessmentKey = extract(".*assessments/(.+?)/.*",1,  id)
    | where assessmentKey == "4ab6e3c5-74dd-8b35-9ab9-f61b30875b27"
    | project   Severity = tostring(properties.status.severity),
                Resource = iif(isempty(properties.resourceDetails.id),strcat(split(properties.resourceDetails.workspaceId, '/')[8]), properties.resourceDetails.id),
                ResourceGroup = toupper(substring(id, 0, indexof(id, '/providers'))),
          Source = tostring(properties.resourceDetails.source),
          Description = tostring(properties.description),
          OperatingSystem = tostring(properties.additionalData.data.OperatingSystem),
          OsType = tostring(properties.additionalData.data.OsType),
                Remediation = properties.remediation,
                state = tostring(properties.status.code)
    |where state=='Unhealthy' and Severity in ({Severity})
    | order by Severity asc
