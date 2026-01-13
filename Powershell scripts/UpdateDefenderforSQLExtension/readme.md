# Microsoft Defender for Cloud - Defender for SQL on machines extension: update extension at scale
Author: Ofir Haviv, Yura Lee

**Deployment overview:**
This powershell script, 'Update-VMDefenderExtension' provides a way for you to update the Defender for SQL on machines extension at scale. 
Once updated, a log file will be created: $logfile

**Requirements:**
This powershell script will also import required modules: 
1. Az.Accounts
2. Az.Compute

**Parameters:**
SubscriptionId: **Required** - The Azure subscription ID for the machines that you want to update the extensions for at scale. 

