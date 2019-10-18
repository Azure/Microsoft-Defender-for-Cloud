# Samples for remediating "Enable transparent data encryption on SQL databases"
These samples provide various ways to resolve the "*Enable transparent data encryption on SQL databases*" recommendation in Azure Security Center. There are four samples:
* **PowerShell script** - will loop through and remediate each instance 
    * Requires the Azure (Az) PowerShell module
* **Logic Apps Playbook** - uses the REST API to enumerate and remediate each instance 
    * Will create a managed service principal. This will need to be configured post deployment with the appropriate permissions
* **Azure Policy** definitions
    * Deny Policy - This will prevent someone from deploying a Azure SQL database without transparent data encryption
    * deployIfNotExist Policy - This allows to run a remediation task

