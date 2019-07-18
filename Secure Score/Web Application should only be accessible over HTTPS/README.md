# Samples for remediating "Web Application should only be accessible over HTTPS"
These samples provide various ways to resolve the "*Web Application should only be accessible over HTTPS*" recommendation in Azure Security Center. There are four samples:
* **PowerShell script** - will loop through and remediate each instance 
    * Requires the Azure (Az) PowerShell module
* **Logic App Playbook** - uses the REST API to enumerate and remediate each instance 
    * Will create a managed service principal. This will need to be added to the subscription with the appropriete access
* **Azure Policy** definitions
    * Deny Policy - This will prevent someone from changing the HTTPS setting back to disabled and prevents the creation of new instances which are not using HTTPS
    * deployIfNotExist Policy - This allows to run a remediation task

