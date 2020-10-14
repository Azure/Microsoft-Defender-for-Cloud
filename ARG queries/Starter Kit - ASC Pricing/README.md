# Starter Kit - ARG Queries for Azure Security Center Pricing
Azure Resource Graph (ARG) provides an efficient way to query at scale across a given set of subscriptions for any Azure Resource (for more information please visit https://docs.microsoft.com/en-us/azure/governance/resource-graph/). 
A useful use case is to use ARG to query, visualize or export Azure Security Center (ASC) Pricing information across your subscriptions in order to get the information that matters most to you.

This starter kit consists of a set of basic ARG queries that have been created to help you build on top of them based on your different needs and requirements.

1. **Get ASC Pricing information for your subscription(s)**
```
securityresources 
| where type == "microsoft.security/pricings"
| extend tier = trim(' ',tostring(properties.pricingTier))
| project name,tier,subscriptionId
```
2. **Get subscription ID(s) where ASC Standard is not or not fully enabled**
```
securityresources
 | where type == "microsoft.security/pricings"
 | where properties.pricingTier == "Free" 
 | distinct subscriptionId

```
3. **Get subscription ID(s) where ASC Standard is fully enabled**
```
securityresources
 | where type == "microsoft.security/pricings"
 | project name, pricingTier=properties.pricingTier, subscriptionId
 | summarize count() by subscriptionId, tostring(pricingTier)
 | where pricingTier == 'Standard' and count_ == 8
 | project subscriptionId

```
