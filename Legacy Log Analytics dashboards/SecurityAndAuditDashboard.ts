SecurityAndAuditDashboard = {
    SecurityDomains: { 
        SecurityLineChartTile: "SecurityEvent | order by TimeGenerated ",
        AntimalwareDomainTile:
            "ProtectionStatus \
            | summarize Result = dcount(Computer), Delta = 0",
        UpdateAssessmentDomainTile:
            "Update \
            | where UpdateState == 'Needed' \
            | summarize Result = dcount(Computer), Delta = 0",
        NetworkDomainTile:
            "WireData \
            | summarize Result = dcount(RemoteIP), Delta = 0",
        IdentityDomainTile:
            "SecurityEvent \
            | where AccountType == 'User' and EventID in (4624, 4625) \
            | summarize Result = dcount(tolower(Account)), Delta = 0",
        ComputersDomainTile:
        {
            NavigationQuery: 
                "union SecurityEvent, LinuxAuditLog, ProtectionStatus, SecurityBaselineSummary, SecurityDetection, CommonSecurityLog | where isnotempty(Computer) | summarize by Computer",
            Query: 
                "union SecurityEvent, LinuxAuditLog, ProtectionStatus, SecurityBaselineSummary, SecurityDetection, CommonSecurityLog \
                | where isnotempty(Computer) \
                | summarize Result = dcount(Computer), Delta = 0"
        },
        BaselineAssessmentDomainTile:
        //Day and 10 min
            "SecurityBaseline \
            | where TimeGenerated >= ago(1450m) \
            | where AnalyzeResult == 'Failed' and RuleSeverity == 'Critical'\
            | summarize Result = dcount(BaselineRuleId), Delta = 0",
        ThreatIntelligenceDomain: 
            "let schemaColumns = datatable(RemoteIPCountry:string)[]; \
            union isfuzzy= true schemaColumns, W3CIISLog, DnsEvents, WireData, WindowsFirewall, CommonSecurityLog \
            | where isnotempty(MaliciousIP) and (isnotempty(MaliciousIPCountry) or isnotempty(RemoteIPCountry))" +
            "| summarize Result = count(), Delta = 0",
    },
    Detections: {
        DetectionsTimeline: "SecurityDetection | where AlertSeverity == 'High' or AlertSeverity == 'Medium' or AlertSeverity == 'Low' | order by TimeGenerated",
        DetectionsList: {
            Query: "SecurityDetection | where AlertSeverity == 'High' or AlertSeverity == 'Medium' or AlertSeverity == 'Low' | summarize Count = count() by AlertSeverity, AlertTitle",
            NavigationQuery: "SecurityDetection | where AlertSeverity == '{0}' and AlertTitle == '{1}'"
        }
    },
    ThreatIntelligence: {
        ThreatTypesDonut: "let schemaColumns = datatable(RemoteIPCountry:string)[]; \
        union isfuzzy= true schemaColumns, W3CIISLog, DnsEvents, WireData, WindowsFirewall, CommonSecurityLog \
        | where isnotempty(MaliciousIP) and (isnotempty(MaliciousIPCountry) or isnotempty(RemoteIPCountry))" + "| summarize Value = count() by IndicatorThreatType",
        ServersWithOutboundTile: {
            Query:                 
            "union isfuzzy=true \
            (WireData | where Direction == 'Outbound' | extend Country=RemoteIPCountry), \
            (WindowsFirewall | where CommunicationDirection == 'SEND' | extend Country=MaliciousIPCountry), \
            (CommonSecurityLog | where CommunicationDirection == 'Outbound' | extend Country=MaliciousIPCountry) \
            | where isnotempty(MaliciousIP) and isnotempty(Country) \
            | summarize dcount(Computer)",
            NavigationQuery: "union isfuzzy=true (WireData | where Direction == 'Outbound' | extend Country=RemoteIPCountry), (WindowsFirewall | where CommunicationDirection == 'SEND' | extend Country=MaliciousIPCountry), (CommonSecurityLog | where CommunicationDirection == 'Outbound' | extend Country=MaliciousIPCountry) | where isnotempty(MaliciousIP) and isnotempty(Country) | summarize by Computer"
        }
    }
};
