# Starter Kit - ARG Queries for Azure Security Center Pricing
Azure Resource Graph (ARG) provides an efficient way to query at scale across a given set of subscriptions for any Azure Resource (for more information please visit https://docs.microsoft.com/en-us/azure/governance/resource-graph/). 
A useful use case is to use ARG to query, visualize or export Azure Security Center (ASC) Pricing information across your subscriptions in order to get the information that matters most to you.

This starter kit consists of a set of basic ARG queries that have been created to help you build on top of them based on your different needs and requirements.

1. **How many subscriptions do I have?**
```
resourcecontainers
| where type == 'microsoft.resources/subscriptions'
| count
```

2. **How many of these subscriptions have been onboarded to ASC?**
```
securityresources
| where type == "microsoft.security/pricings"
| distinct subscriptionId
| count
```

3. **How many of these subscriptions have not yet been onboarded to ASC?**
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

4. **Which subscriptions have not yet been onboarded to ASC?**
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

5. **Which subscriptions are using ASC with Azure Defender fully enabled?**
```
securityresources
 | where type == "microsoft.security/pricings"
 | project name, pricingTier=properties.pricingTier, subscriptionId
 | summarize count() by subscriptionId, tostring(pricingTier)
 | where pricingTier == 'Standard' and count_ == 10
 | project subscriptionId

```

6. **Which subscriptions are using ASC without Azure Defender fully enabled?**
```
securityresources
| where type == "microsoft.security/pricings"
| where properties.pricingTier == "Free" 
| distinct subscriptionId
```

7.  **What is the coverage (On | On (partial) | Off) for Azure Defender across all of my subscriptions?**
```
securityresources
| where type == "microsoft.security/pricings"
| summarize count() by subscriptionId,  pricingTier=tostring(properties.pricingTier)
| extend Azure_Defender = case(
                  pricingTier == 'Standard' and count_ == 10, "On", 
                  pricingTier == 'Standard', "On (partial)", 
                  pricingTier == 'Free' and count_ == 10, "Off", 
                  '')
| project subscriptionId, Azure_Defender
| where isnotempty(Azure_Defender)
| sort by Azure_Defender
```

8. **Which Azure Defender plans (Azure Defender for VMs, Azure Defender for KeyVaults, etc.) are enabled across all of my subscriptions?**
```
securityresources 
| where type == "microsoft.security/pricings"
| extend tier = trim(' ',tostring(properties.pricingTier))
| project name,tier,subscriptionId
```
