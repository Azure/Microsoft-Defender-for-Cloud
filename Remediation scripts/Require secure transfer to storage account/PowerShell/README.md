# PowerShell script to remediate

This sample script is provided to remediate the "Require secure transfer to storage account" 
recommendation in Azure Security Center.  The script will enumerate the task from Security Center
and loop through each resource and set the HTTPS Only option on the storage account.
