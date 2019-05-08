ThreatIntelligenceDashboard = {
    ThreatBreakdown: {
        ThreatTypesDonut: "let schemaColumns = datatable(RemoteIPCountry:string)[]; \
        union isfuzzy= true schemaColumns, W3CIISLog, DnsEvents, WireData, WindowsFirewall, CommonSecurityLog \
        | where isnotempty(MaliciousIP) and (isnotempty(MaliciousIPCountry) or isnotempty(RemoteIPCountry))" + "| summarize Value = count() by IndicatorThreatType",
        CountryList: {
            Query: 
            "let schemaColumns = datatable(RemoteIPCountry:string)[]; \
            union isfuzzy= true schemaColumns, W3CIISLog, DnsEvents, WireData, WindowsFirewall, CommonSecurityLog \
            | where isnotempty(MaliciousIP) and (isnotempty(MaliciousIPCountry) or isnotempty(RemoteIPCountry))" +
            "| extend Country = iff(isnotempty(MaliciousIPCountry), MaliciousIPCountry, iff(isnotempty(RemoteIPCountry), RemoteIPCountry, '')) \
             | summarize Count=count() by Country \
             | top 10 by Count",
            ListItemNavigationQuery:
            "let schemaColumns = datatable(RemoteIPCountry:string)[]; \
            union isfuzzy= true schemaColumns, W3CIISLog, DnsEvents, WireData, WindowsFirewall, CommonSecurityLog \
            | where isnotempty(MaliciousIP) and (isnotempty(MaliciousIPCountry) or isnotempty(RemoteIPCountry))" +
            "| extend Country = iff(isnotempty(MaliciousIPCountry), MaliciousIPCountry, iff(isnotempty(RemoteIPCountry), RemoteIPCountry, '')) \
             | where {selected item}"
        }
    },
    ThreatLocation: {
        Query:
        "union \
        ((union isfuzzy=true \
        (WireData | where Direction == 'Outbound' | extend Country=RemoteIPCountry, Latitude=RemoteIPLatitude, Longitude=RemoteIPLongitude), \
        (WindowsFirewall | where CommunicationDirection == 'SEND' | extend Country=MaliciousIPCountry, Latitude=MaliciousIPLatitude, Longitude=MaliciousIPLongitude), \
        (CommonSecurityLog | where CommunicationDirection == 'Outbound' | extend Country=MaliciousIPCountry, Latitude=MaliciousIPLatitude, Longitude=MaliciousIPLongitude, Confidence=ThreatDescription, Description=ThreatDescription)) \
        | where isnotempty(MaliciousIP) and isnotempty(Country) and isnotempty(Latitude) and isnotempty(Longitude) \
        | summarize Count= count() by MaliciousIP, IndicatorThreatType, Country, Latitude, Longitude, Confidence, Description, ReportReferenceLink, LayerId='outgoing-traffic' \
        | top 150 by Count), \
        ((union isfuzzy=true \
        (W3CIISLog | extend Country=RemoteIPCountry, Latitude=RemoteIPLatitude, Longitude=RemoteIPLongitude), \
        (DnsEvents | extend Country= RemoteIPCountry, Latitude = RemoteIPLatitude, Longitude = RemoteIPLongitude), \
        (WireData | where Direction != 'Outbound' | extend Country=RemoteIPCountry, Latitude=RemoteIPLatitude, Longitude=RemoteIPLongitude), \
        (WindowsFirewall | where CommunicationDirection != 'SEND' | extend Country=MaliciousIPCountry, Latitude=MaliciousIPLatitude, Longitude=MaliciousIPLongitude), \
        (CommonSecurityLog | where CommunicationDirection != 'Outbound' | extend Country=MaliciousIPCountry, Latitude=MaliciousIPLatitude, Longitude=MaliciousIPLongitude, Confidence=ThreatDescription, Description=ThreatDescription)) \
        | where isnotempty(MaliciousIP) and isnotempty(Country) and isnotempty(Latitude) and isnotempty(Longitude) \
        | summarize Count= count() by MaliciousIP, IndicatorThreatType, Country, Latitude, Longitude, Confidence, Description, ReportReferenceLink, LayerId='incoming-traffic' \
        | top 150 by Count)",
        IncomingMaliciousTrafficNavigationQuery: 
        "union isfuzzy=true W3CIISLog, DnsEvents, (WireData | where Direction != 'Outbound'), (WindowsFirewall | where CommunicationDirection != 'SEND'), (CommonSecurityLog | where CommunicationDirection != 'Outbound') | where MaliciousIP == '{0}'",
        OutgoingMaliciousTrafficNavigationQuery: 
        "union isfuzzy=true (WireData | where Direction == 'Outbound'), (WindowsFirewall | where CommunicationDirection == 'SEND'), (CommonSecurityLog | where CommunicationDirection == 'Outbound') | where MaliciousIP == '{0}'",

    }
};