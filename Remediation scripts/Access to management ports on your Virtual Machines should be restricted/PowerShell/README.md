# PowerShell Script to Remediate Management Port

This sample script is provided to remediate the "Access to management ports on your Virtual Machines should be restricted" recommendation in Azure Security Center.  Update the script with the following parameters:

- $SubscriptionId="\<subscriptionId>"
- $ResourceGroupName="\<resourceGroupName>"
- $NetworkSecurityGroupName="\<nsgName>"
- $InboundRuleName="\<nsgRuleName>"
- $ManagementPort="\<managementPort>"
