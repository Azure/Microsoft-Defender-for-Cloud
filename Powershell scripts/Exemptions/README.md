# Microsoft Defender for Cloud - Recommendations Exemption removal script.

## Description  
   This script is purposed to remove Azure Policy exemptions under a subscription.
   It can remove all exemptions under a subscription or single Recommendation exemptions from subscription scope.
   This script can remove all the exemptions for all recommendations in a subscription or one Recommendation exemption - use with care!


## Usage
**PARAMETER** ***subscriptionId***  
  The subscription Id in context
  
**PARAMETER** ***referenceId***  
  Recommendation Policy Id to remove its exemption.
  
  To find a Policy reference ID go to Azure Policy, locate the relevant initiative (e.g. Azure Security Benchmark), open it and look for the policy to exempt, find it under Reference ID column.
  
**PARAMETER** ***deleteExemptionsFromAllRecommendations***  
  Indicate this flag to clear out all the exemptions from the subscription.
  Use with care!
  
**EXAMPLE 1**  
  `Remove-MDFCPolicyExemptions.md -SubscriptionId {subId} -referenceId {policyReferenceId}`  
  Remove the exemption for single policy 
  
**EXAMPLE 2**  
  `Remove-MDFCPolicyExemptions.md -SubscriptionId {subId} -deleteExemptionsFromAllRecommendations`  
  Remove all the exemptions from a subscription

**Important Note**  
   It is recommended to list the existing exemptions before running this script by using [https://docs.microsoft.com/en-us/rest/api/policy/policy-exemptions/list](https://docs.microsoft.com/en-us/rest/api/policy/policy-exemptions/list)   

