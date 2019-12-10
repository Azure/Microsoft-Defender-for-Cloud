# Workflow automation and continuous export data types schemas

When using Azure Security Center's [Continuous export](https://docs.microsoft.com/azure/security-center/continuous-export) or [Workflow automation](https://docs.microsoft.com/azure/security-center/workflow-automation) features [programmatically](https://docs.microsoft.com/rest/api/securitycenter/automations), you'll need to have the data types (recommendations or alerts) schemas in order to know on which fields to define your set of filtering rules on.

In addition, when exporting to an Event Hub or when triggering Workflow automation with generic HTTP connectors, you could use the schemas to properly [parse the JSON objects](https://docs.microsoft.com/azure/logic-apps/logic-apps-perform-data-operations#parse-json-action). 

## Recommendations objects schema

The recommendations JSON schema is available in the included [Recommendation.schema.json](./Recommendation.schema.json) file. It includes list of mandatory fields and their types, along with sample values for each field.

### Sample JSON event

Below is a sample JSON representing an assessment (which can be healthy or unhealthy. In the latter case, it will be surfaced as a recommendation in Security Center), as would be read from Event Hub (in case of configuring continuous export) or as will be passed to Logic App instances (when using workflow automation).

```
{
  "AssessmentEventDataEnrichment": {
    "Action": "Insert",
    "ApiVersion": "2019-01-01"
  },
  "id": "/subscriptions/a27e854a-8578-4395-8eaf-6fc7849f3050/providers/Microsoft.Security/assessments/151e82c5-5341-a74b-1eb0-bc38d2c84bb5",
  "name": "151e82c5-5341-a74b-1eb0-bc38d2c84bb5",
  "type": "Microsoft.Security/assessments",
  "properties": {
    "resourceDetails": {
      "source": "Azure",
      "id": "/subscriptions/a27e854a-8578-4395-8eaf-6fc7849f3050"
    },
    "displayName": "Enable MFA for Azure Management App accounts with read permissions on your subscription",
    "status": {
      "code": "Unhealthy",
      "cause": "N/A",
      "description": "N/A"
    },
    "additionalData": {
      "usersWithNoMfaObjectIdList": [
        "4da84f70-3bf5-4537-ab16-01100fd5c378",
        "271edb6b-4bfd-44dc-bde7-25286a2e1dc1"
      ]
    },
    "metadata": {
      "displayName": "Enable MFA for Azure Management App accounts with read permissions on your subscription",
      "assessmentType": "BuiltIn",
      "policyDefinitionId": "/providers/Microsoft.Authorization/policyDefinitions/760a85ff-6162-42b3-8d70-698e268f648c",
      "description": "N/A",
      "remediationDescription": "N/A",
      "severity": "Low"
    },
    "links": {
      "azurePortal": "https://ms.portal.azure.com/?fea#blade/Microsoft_Azure_Security/RecommendationsBlade/assessmentKey/01b1ed4c-b733-4fee-b145-f23236e70cf3"
    }
  }
}
```

### Log Analytics table schema (recommendations)

With the [Continuous export](https://docs.microsoft.com/azure/security-center/continuous-export) you can continuously export Security Center's recommendation to a Log Analytics workspace, under the _SecurityRecommendation_ data type (available under the 'Security and Audit'('Security') or 'SecurityCenterFree' solutions):

```
- AgentId - unused
- AssessedResourceId - The Azure resource ID the assessment pertains to
- Description - Description text for the recommendation
- DeviceId - unused
- DiscoveredTimeUTC - UTC timestamp on which the assessment took place (Security Center's scan time. Identical to the TimeGenerated field)
- NotApplicableReason - In case the assessment is not applicable to the resource, details the reason why this is the case
- PolicyDefinitionId - The associated Azure Policy definition identifier based on which the assessment was evaluated
- ProviderName - constant ('AzureSecurityCenter')
- RecommendationAdditionalData - unused at this point. May be populated with additional data that is relevant for each individual recommendation
- RecommendationDisplayName - The display name of the assessment, as seen in Azure Security Center
- RecommendationId - unique identifier of the assessment
- RecommendationName - Identical to RecommendationDisplayName
- RecommendationSeverity - the severity of the assessment
- RecommendationState - the state of the assessment (Healthy/Unhealthy/Removed/NotApplicable)
- RemediationDescription - details of remediation steps needed to remediate the assessment
- ResolvedTimeUTC - 
    In case the assessment's state is Unhealthy or NotApplicable, this will be set to DateTime.MinTime (1/1/1, 12:00:00.000 AM).
    In case it is healthy, this will be set to the time Security Center's detected the assessment to be healthy (UTC timezone).
    In case the assessment is removed (e.g. resource deleted), will be set to DateTime.MinTime
- ResourceRegion - unused
- ResourceTenantId - unused
- SourceSystem - constant ('Security')
- TenantId - the identifier of the parent Azure Active directory tenant of the subscription under which the scanned resource resides
- TimeGenerated - UTC timestamp on which the assessment took place (Security Center's scan time) (identical to DiscoveredTimeUTC)
- Type - constant ('SecurityRecommendation')
```

## Security alerts objects schema

The security alerts JSON schema is available in the included [SecurityAlert.schema.json](./SecurityAlert.schema.json) file. It includes list of mandatory fields and their types, along with sample values for each field.

### Sample JSON event

Below is a sample JSON representing an alert, as would be read from Event Hub (in case of configuring continuous export) or as will be passed to Logic App instances (when using workflow automation)

```
{
  "VendorName": "Microsoft",
  "AlertType": "SUSPECT_SVCHOST",
  "StartTimeUtc": "2016-12-20T13:38:00.000Z",
  "EndTimeUtc": "2019-12-20T13:40:01.733Z",
  "ProcessingEndTime": "2019-09-16T12:10:19.5673533Z",
  "TimeGenerated": "2016-12-20T13:38:03.000Z",
  "IsIncident": false,
  "Severity": "High",
  "Status": "New",
  "ProductName": "Azure Security Center",
  "SystemAlertId": "2342409243234234_F2BFED55-5997-4FEA-95BD-BB7C6DDCD061",
  "AzureResourceId": "/subscriptions/86057C9F-3CDD-484E-83B1-7BF1C17A9FF8/resourceGroups/backend-srv/providers/Microsoft.Compute/WebSrv1",
  "AzureResourceSubscriptionId": "86057C9F-3CDD-484E-83B1-7BF1C17A9FF8",
  "WorkspaceId": "077BA6B7-8759-4F41-9F97-017EB7D3E0A8",
  "WorkspaceSubscriptionId": "86057C9F-3CDD-484E-83B1-7BF1C17A9FF8",
  "WorkspaceResourceGroup": "omsrg",
  "AgentId": "5A651129-98E6-4E6C-B2CE-AB89BD815616",
  "CompromisedEntity": "WebSrv1",
  "Intent": "Execution",
  "AlertDisplayName": "Suspicious process detected",
  "Description": "Suspicious process named ‘SVCHOST.EXE’ was running from path: %{Process Path}",
  "RemediationSteps": ["contact your security information team"],
  "ExtendedProperties": {
    "Process Path": "c:\\temp\\svchost.exe",
    "Account": "Contoso\\administrator",
    "PID": 944,
    "ActionTaken": "Detected"
  },
  "Entities": [],
  "ResourceIdentifiers": [
		{
			Type: "AzureResource",
			AzureResourceId: "/subscriptions/86057C9F-3CDD-484E-83B1-7BF1C17A9FF8/resourceGroups/backend-srv/providers/Microsoft.Compute/WebSrv1"
		},
		{
			Type: "LogAnalytics",
			WorkspaceId: "077BA6B7-8759-4F41-9F97-017EB7D3E0A8",
			WorkspaceSubscriptionId: "86057C9F-3CDD-484E-83B1-7BF1C17A9FF8",
			WorkspaceResourceGroup: "omsrg",
			AgentId: "5A651129-98E6-4E6C-B2CE-AB89BD815616",
		}
  ]
}
```

### Kill chain intent

At times, you may wish to use the kill chain intent to categorize alerts or act on alerts of specific category.
The currently supported kill chain intents are:

|Intent|Meaning|
|------|-------|
|Unknown|Unknown alert intent is the default value for the KillChainIntent enumeration. <br>Some alert providers won't tag alerts at first stage with intents, so having a default unknown values helps make this field optional in the SecurityAlert schema.|
|Probing|Probing could be either an attempt to access a certain resource regardless of a malicious intent, or a failed attempt to gain access to a target system to gather information prior to exploitation. This step is usually detected as an attempt, originating from outside the network, to scan the target system and find a way in.|
|Exploitation|Exploitation is the stage where an attacker manages to get foothold on the attacked resource. This stage is applicable not only for compute hosts, but also for resources such as user accounts, certificates etc.  Adversaries will often be able to control the resource after this stage.|
|Persistence|Persistence is any access, action, or configuration change to a system that gives an adversary a persistent presence on that system. Adversaries will often need to maintain access to systems through interruptions such as system restarts, loss of credentials, or other failures that would require a remote access tool to restart or alternate backdoor for them to regain access|
|PrivilegeEscalation|Privilege escalation is the result of actions that allow an adversary to obtain a higher level of permissions on a system or network. Certain tools or actions require a higher level of privilege to work and are likely necessary at many points throughout an operation. User accounts with permissions to access specific systems or perform specific functions necessary for adversaries to achieve their objective may also be considered an escalation of privilege.|
|DefenseEvasion|Defense evasion consists of techniques an adversary may use to evade detection or avoid other defenses. Sometimes these actions are the same as or variations of techniques in other categories that have the added benefit of subverting a particular defense or mitigation.|
|CredentialAccess|Credential access represents techniques resulting in access to or control over system, domain, or service credentials that are used within an enterprise environment. Adversaries will likely attempt to obtain legitimate credentials from users or administrator accounts (local system administrator or domain users with administrator access) to use within the network. With sufficient access within a network, an adversary can create accounts for later use within the environment.|
|Discovery|Discovery consists of techniques that allow the adversary to gain knowledge about the system and internal network. When adversaries gain access to a new system, they must orient themselves to what they now have control of and what benefits operating from that system give to their current objective or overall goals during the intrusion. The operating system provides many native tools that aid in this post-compromise information-gathering phase.|
|LateralMovement|Lateral movement consists of techniques that enable an adversary to access and control remote systems on a network and could, but does not necessarily, include execution of tools on remote systems. The lateral movement techniques could allow an adversary to gather information from a system without needing additional tools, such as a remote access tool. An adversary can use lateral movement for many purposes, including remote Execution of tools, pivoting to additional systems, access to specific information or files, access to additional credentials, or to cause an effect.|
|Execution|The execution tactic represents techniques that result in execution of adversary-controlled code on a local or remote system. This tactic is often used in conjunction with lateral movement to expand access to remote systems on a network.|
|Collection|Collection consists of techniques used to identify and gather information, such as sensitive files, from a target network prior to exfiltration. This category also covers locations on a system or network where the adversary may look for information to exfiltrate.|
|Exfiltration|Exfiltration refers to techniques and attributes that result or aid in the adversary removing files and information from a target network. This category also covers locations on a system or network where the adversary may look for information to exfiltrate.|
|CommandAndControl|The command and control tactic represents how adversaries communicate with systems under their control within a target network.|
|Impact|The impact intent primary objective is to directly reduce the availability or integrity of a system, service, or network; including manipulation of data to impact a business or operational process. This would often refer to techniques such as ransom-ware, defacement, data manipulation and others.|

### Log Analytics table schema (alerts)

With the [Continuous export](https://docs.microsoft.com/azure/security-center/continuous-export) you can continuously export Security Center's alerts to a Log Analytics workspace, under the _SecurityAlert_ data type (available under the 'Security and Audit'('Security') or 'SecurityCenterFree' solutions):

```
- AlertName - Alert display name
- Severity - The alert severity (High/Medium/Low/Informational)
- AlertType - unique alert identifier
- ConfidenceLevel - (Optional) The confidence level of this alert (High/Low)
- ConfidenceScore - (Optional) Numeric confidence indicator of the security alert
- Description - Description text for the alert
- DisplayName - The alert's display name
- EndTime - The impact end time of the alert (the time of the last event contributing to the alert)
- Entities - A list of entities related to the alert. This list can hold a mixture of entities of diverse types
- ExtendedLinks - (Optional) A bag for all links related to the alert. This bag can hold a mixture of links for diverse types
- ExtendedProperties - A bag of additional fields which are relevant to the alert
- IsIncident - Determines if the alert is an incident or a regular alert. An incident is a security alert that aggregates multiple alerts into one security incident
- ProcessingEndTime - UTC timestamp in which the alert was created
- ProductComponentName - (Optional) The name of a component inside the product which generated the alert.
- ProductName - constant ('Azure Security Center')
- ProviderName - unused
- RemediationSteps - Manual action items to take to remediate the security threat
- ResourceId - Full identifier of the affected resource
- SourceComputerId - a unique GUID for the affected server (if the alert is generated on the server)
- SourceSystem - unused
- StartTime - The impact start time of the alert (the time of the first event contributing to the alert)
- SystemAlertId - Unique identifier of this security alert instance
- TenantId - the identifier of the parent Azure Active directory tenant of the subscription under which the scanned resource resides
- TimeGenerated - UTC timestamp on which the assessment took place (Security Center's scan time) (identical to DiscoveredTimeUTC)
- Type - constant ('SecurityAlert')
- VendorName - The name of the vendor that provided the alert (e.g. 'Microsoft')
- VendorOriginalId - unused
- WorkspaceResourceGroup - in case the alert is generated on a VM, Server, VMSS or App Service instance that reports to a workspace, contains that workspace resource group name
- WorkspaceSubscriptionId - in case the alert is generated on a VM, Server, VMSS or App Service instance that reports to a workspace, contains that workspace subscriptionId
```