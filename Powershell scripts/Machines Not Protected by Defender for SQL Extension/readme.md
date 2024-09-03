# Machines Not Protected by Defender for SQL Extension

## Overview

This script identifies SQL VMs and Arc machines that are not protected by Defender for SQL extension within a specified subscription.
Defender for SQL is compatible with SQL VMs and SQL Arc machines running the Windows OS.
Therefore, the script will exclude the following resources:

- Machines without SQL Server
- Linux machines
- Deallocated or disconnected machines

## Examples

```powershell
.\List-notProtectedMachinesDefenderforSQL.ps1 -SubscriptionId 'ada06e68-4678-4210-443a-c6cacebf41c5'
```
