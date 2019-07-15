# PowerShell script to remediate

This sample script is provided to remediate the "Enable auditing on SQL Server" 
recommendation in Azure Security Center.  The script will enumerate the task from Security Center
and loop through each resource and set SQL Server auditing.  The script will prompt for which type
of stoage, Log A or Event Hub.
