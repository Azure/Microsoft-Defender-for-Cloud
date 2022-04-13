# Starter Kit - ARG Queries for Microsoft Defender for Cloud Pricing
Azure Resource Graph (ARG) provides an efficient way to query at scale across a given set of subscriptions for any Azure Resource (for more information please visit https://docs.microsoft.com/en-us/azure/governance/resource-graph/). 
A useful use case is to use ARG to query, visualize or export Microsoft Defender for Cloud Pricing information across your subscriptions in order to get the information that matters most to you.

This starter kit consists of a set of basic ARG queries that have been created to help you build on top of them based on your different needs and requirements.

1. **How many subscriptions do I have?**
```
resourcecontainers
| where type == 'microsoft.resources/subscriptions'
| count
```

2. **How many of these subscriptions have been onboarded to Defender for Cloud?**
```
securityresources
| where type == "microsoft.security/pricings"
| distinct subscriptionId
| count
```

3. **How many of these subscriptions have not yet been onboarded to Defender for Cloud?**
```
resourcecontainers
| where type == 'microsoft.resources/subscriptions'
| project subscriptionId
| join kind=leftouter (
        securityresources
            | where type == "microsoft.security/pricings"
            | distinct subscriptionId
                ) on subscriptionId 
                | where isempty(subscriptionId1)
                | count
```

4. **Which subscriptions have not yet been onboarded to Defender for Cloud?**
```
resourcecontainers
| where type == 'microsoft.resources/subscriptions'
| project subscriptionId
| join kind=leftouter (
        securityresources
            | where type == "microsoft.security/pricings"
            | distinct subscriptionId
                ) on subscriptionId 
                | where isempty(subscriptionId1)
                | project subscriptionId
```

5. **Which subscriptions are using Defender for Cloud without the Defender plans fully enabled?**
```
securityresources
| where type == "microsoft.security/pricings"
| where properties.pricingTier == "Free" 
| distinct subscriptionId
```

6.  **What is the coverage (On | On (partial) | Off) for Defender for Cloud across all of my subscriptions?**
```
securityresources
| where type =~ "microsoft.security/pricings"
| extend  planSet = pack(name,pricingTier = properties.pricingTier)
| summarize defenderPlans = make_bag(planSet) by subscriptionId
| extend Defender_for_Cloud = case(  
    defenderPlans.VirtualMachines == 'Standard' and 
        defenderPlans.AppServices == 'Standard' and
        defenderPlans.SqlServers == 'Standard' and
        defenderPlans.SqlServerVirtualMachines == 'Standard' and 
        defenderPlans.OpenSourceRelationalDatabases == 'Standard' and 
        defenderPlans.CosmosDbs == 'Standard' and 
        defenderPlans.StorageAccounts == 'Standard' and  
        defenderPlans.Containers == 'Standard' and  
        defenderPlans.KeyVaults == 'Standard' and 
        defenderPlans.Arm == 'Standard' and 
        defenderPlans.Dns == 'Standard', "On",
     defenderPlans.VirtualMachines == 'Standard' or 
        defenderPlans.AppServices == 'Standard' or
        defenderPlans.SqlServers == 'Standard' or
        defenderPlans.SqlServerVirtualMachines == 'Standard' or 
        defenderPlans.OpenSourceRelationalDatabases == 'Standard' or 
        defenderPlans.CosmosDbs == 'Standard' or 
        defenderPlans.StorageAccounts == 'Standard' or  
        defenderPlans.Containers == 'Standard' or  
        defenderPlans.KeyVaults == 'Standard' or 
        defenderPlans.Arm == 'Standard' or 
        defenderPlans.Dns == 'Standard', "On (partial)",
      defenderPlans.VirtualMachines == 'Free' and
        defenderPlans.AppServices == 'Free' or
        defenderPlans.SqlServers == 'Free' or
        defenderPlans.SqlServerVirtualMachines == 'Free' and
        defenderPlans.OpenSourceRelationalDatabases == 'Free' and
        defenderPlans.CosmosDbs == 'Free' and
        defenderPlans.StorageAccounts == 'Free' and 
        defenderPlans.Containers == 'Free' and 
        defenderPlans.KeyVaults == 'Free' and
        defenderPlans.Arm == 'Free' and
        defenderPlans.Dns == 'Free', "Off",
    '')
| project subscriptionId, Defender_for_Cloud
```

7. **Which Defender plans (Microsoft Defender for Servers, Microsoft Defender for Key Vaults, etc.) are enabled across all of my subscriptions?**
```
securityresources 
| where type == "microsoft.security/pricings"
| extend tier = trim(' ',tostring(properties.pricingTier))
| project name,tier,subscriptionId
```
