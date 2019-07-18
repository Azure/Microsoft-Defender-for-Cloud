# Samples for remediating "Enable Auditing on SQL Server"

These samples provide various ways to resolve the "Enable Auditing on SQL Server" recommendation
in Azure Security Center.  There are four samples:

* PowerShell script - Will loop through and rememdiate each instance
    - Requires Azure (Az) PowerShell module
* Logic App - Uses the REST API to enumerate and remediate each instance
    - Will need to create a managed service principal.  This will need to be added to the 
    subscription with access
* Deny Policy - This will prevent someone from setting the auditing back to disabled.
* DeployIfNotExist Policy - This will remediate via policy.  There is a sample for each destination type.
