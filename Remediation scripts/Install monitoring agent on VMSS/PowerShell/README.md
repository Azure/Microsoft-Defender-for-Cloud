# PowerShell script to remediate

This sample script is provided to remediate the "Monitoring agent should be installed on virtual machine scale sets" 
recommendation in Azure Security Center.  The script will except as input workspaceKey and Workspace ID
and loop through each VMSS and install MMA agents on it.
