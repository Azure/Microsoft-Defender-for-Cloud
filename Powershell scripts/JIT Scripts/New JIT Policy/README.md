# New-JITPolicy.ps1
   Azure Defender Just-in-Time (JIT) VM access policy script.

## Description  
  JIT is Azure Defender feature. This script uses Az.Security Powershell cmdlet Set-AzJitNetworkAccessPolicy.
  If no subscriptionID indicated, the current subscription will be selected (Get-AzContext).
  
## Important notes:
  1. The script passes these are the hard coded defaults:
     - Allowed source IP address = Any ("*")
     - Ports = 3389 and 22
     - protocol = Any
  **If different value required, edit them in the script body.**
  
  2. Prerequisites:
	   - Az Module: `Install-module Az`
	   - Az.Security module : `Install-module Az.security`

## Usage
  **PARAMETER** ***SubscriptionId***  
  [Optional]  
  The subscriptionID of the Azure Subscription in which the VM created.  
  This script will not override existing policy with the same name.  

**PARAMETER** ***VmName***  
  [mandatory]  
  The VM name to configure  

**PARAMETER** ***PolicyName***  
  [mandatory]  
  Policy name. Can be unique.  
  Note: When configuring JIT policy from Azure Portal it defines an arrayed policy under the name 'default'.  
  Creating a policy with the same name under the same RG as an existing policy will override it without any option to undo!  

**PARAMETER** ***AccesDuration***
  [optional]  
  Access request duration limit in hours. Default is 3 hours.
  
## Usage
  Set-JITPolicy -SubscriptionId <Mandatory> -VmName <Mandatory> -PolicyName <Mandatory> -AcceDuration <optional, default is 3 hours>  
  
## Example
  `$vm = Get-AzVM  -Name <myVm>`
  `.\New-JITPolicy.ps1 -VmName $vm.Name -PolicyName MayVmJitPolicy -AccesDuration 4`

## Credits
Author: Eli Sagie - ASC EEE  
Created on: August 1st, 2021
