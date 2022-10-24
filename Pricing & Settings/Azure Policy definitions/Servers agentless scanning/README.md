# Servers Agentless scanning enablement
The policy enables Microsoft Defender for Cloud [servers agentless scanning](https://learn.microsoft.com/en-us/azure/defender-for-cloud/concept-agentless-data-collection) mode on subscription level.

**Agentless scanning for servers is part of the Defender CSPM and/or Servers P2 bundle**

## Policy actions
1. Assigns 'VM Scanner Operator' role definition to 'Microsoft Defender for Cloud Servers Scanner Resource Provider' enterprise application, which is the application used by Microsoft Defender for Cloud to orchestrate the scanning process on the scanned subscription. Use the PowerShell script below to get the object ID of 'Microsoft Defender for Cloud Servers Scanner Resource Provider' enterprise application.

2. Creates a new Microsoft.Security/vmScanner ARM resource on the subscription remediated by the policy


## How to use
1. Get 'Microsoft Defender for Cloud Servers Scanner Resource Provider' enterprise application object ID, which is unique per Azure AD tenant and a required parameter by the policy using the following Azure CLI command: *az ad sp show --id '0c7668b5-3260-4ad0-9f53-34ed54fa19b2' --query '{objectId: id || objectId, displayName: displayName}'*

2. Assign the policy to a management group / the subscriptions you would like to enable at scale, the object ID retrieved in step 1 should be set as the *mdcObjectId* policy parameter value. Optionally - set the exclusionTags parameter as well, which is a dictionary of string key-value pairs representing the tags used to exclude resources from being scanned (e.g. { "businessUnit": "Finance" }).

**Alternative - click the button below to deploy the policy to management group**

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FPricing%2520%2526%2520Settings%2FAzure%2520Policy%2520definitions%2FServers%2520agentless%2520scanning%2FManagementGroupDeployment%2Fazuredeploy.json)
