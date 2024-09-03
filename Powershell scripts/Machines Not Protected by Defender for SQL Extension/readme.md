# Machines Not Protected by Defender for SQL Extension

## Overview

This script identifies SQL VMs and Arc machines that are not protected by Defender for SQL extension within a specified subscription.
Defender for SQL is compatible with SQL VMs and SQL Arc machines running the Windows OS.
Therefore, the script will exclude the following resources:

- Machines without SQL Server
- Linux machines
- Deallocated or disconnected machines

## Prerequisites
* Install the following Powershell modules:
    * Az
    * Az.Resources
    * Az.Accounts
    * Az.Compute
    * Az.ConnectedMachine
    * Az.SqlVirtualMachine

## Examples

```powershell
.\list-notProtectedMachinesDefenderforSQL.ps1 -SubscriptionId 'ada06e68-4678-4210-443a-c6cacebf41c5'
```
