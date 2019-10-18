# PowerShell script to remediate

This sample script is provided to remediate the "DDoS Protection Standard should be enabled" 
recommendation in Azure Security Center.  The script will enumerate the task from Security Center
and loop through each resource and add DDOS.  If not DDOS Plan exists it will create one.
