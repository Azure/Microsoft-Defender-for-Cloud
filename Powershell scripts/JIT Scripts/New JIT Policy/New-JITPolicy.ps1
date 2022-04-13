<#  
.SYNOPSIS  
   Azure Defender Just-in-Time (JIT) VM access policy script.
.DESCRIPTION  
  JIT is Azure Defender feature. This script uses Az.Security Powershell cmdlet Set-AzJitNetworkAccessPolicy.
  If no subscriptionID indicated, the current subscription will be selected (Get-AzContext).
  
  Notes:
  1. The script passes these are the hard coded defaults:
    - Allowed source IP address = Any ("*")
    - Ports = 3389 and 22
    - protocol = Any
  If different value required, edit them in the script body.
  
  2. Prerequisites:
	- Install-module Az
	- Install-module Az.security
.EXAMPLE
  Set-JITPolicy -SubscriptionId <Mandatory> -VmName <Mandatory> -PolicyName <Mandatory> -AcceDuration <optional, default is 3 hours>
.PARAMETER SubscriptionId
  [Optional]
  The subscriptionID of the Azure Subscription in which the VM created.
  This script will not override existing policy with the same name.
.PARAMETER VmName
  [mandatory] 
  The VM name to configure
.PARAMETER PolicyName
  [mandatory] 
  Policy name. Can be unique.
  Note: When configuring JIT policy from Azure Portal it defines an arrayed policy under the name 'default'.
  Creating a policy with the same name as any existing policy will override it without any option to undo!
.PARAMETER AccesDuration
  [optional]
  Access request duration limit in hours. Default is 3 hours.
.NOTES
 Author: Eli Sagie - ASC EEE 
 Created on: August 1st, 2021
.LINK
 This script posted to and discussed at the following locations:
 https://github.com/Azure/Azure-Security-Center/tree/master/Powershell%20scripts
#>

param
(
	[Parameter(Mandatory = $false)]
	[string]$SubscriptionId,
	[Parameter(Mandatory = $true)]
	[string]$VmName,
	[Parameter(Mandatory = $true)]
	[string]$PolicyName,
    [string]$AccesDuration = "3"
)

#Subscription login
if (!$SubscriptionId)
{
	$subContext = Get-AzContext
	$subscriptionId = $subContext.Subscription.Id
	
	if (!($subscriptionId))# -OR $subContext.Subscription.Id -ne $SubscriptionId)
	{
		write-host "`nPlease make sure you logged on to your Azure subscription using Login-AzAccount cmdlet" -ForegroundColor Yellow
		return
	}
}

if ($subContext.Subscription.Id -eq $SubscriptionId)
	{
		Write-Verbose "Subscription $SubscriptionId is in context"
	}

#Access token
$token = (Get-AzAccessToken).token
$requestHeader = @{
  "Authorization" = "Bearer " + $token
  "Content-Type" = "application/json"
}

#Variables
$vm = Get-AzVM -Name $VmName
    Write-Verbose "VM for policy: $($vm.Name)"
$resourceGroupName = $($vm.ResourceGroupName)
    write-verbose "RG Name: $resourceGroupName"
$location = $($vm.location)
    write-verbose "Location: $location"
[string[]]$ipArr=@("*")
    write-verbose "Source IP addresses: Per Request (*)"
$duration = "PT"+$AccesDuration+"H"
	write-verbose "Duration: $Duration"

# Check if exist

$currentPolicies = Get-AzJitNetworkAccessPolicy -ResourceGroupName $resourceGroupName
	
if ($currentPolicies.Name -match $PolicyName)
	{
		Write-Host "A policy with the name $PolicyName already exist in $resourceGroupName RG. `nPlease change the name or remove the existing. `nNo action was performed.`n" -ForegroundColor Magenta
		return
	}
If ($currentPolicies.VirtualMachines.id -match $VmName)
	{
		Write-Host "A $VmName already configured in a $resourceGroupName RG policy. `nPlease select different VM or remove the existing." -ForegroundColor Magenta
		Write-Host "`nNo action was performed." -ForegroundColor Yellow
		return
	}


#Body
$JitPolicy = (@{
    id="/subscriptions/$SubscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines/$VmName";
    ports=(@{
         number=22;
         protocol="*";
         allowedSourceAddressPrefix=@("*");
         maxRequestAccessDuration="$duration"},
         @{
         number=3389;
         protocol="*";
         allowedSourceAddressPrefix=@("*");
         maxRequestAccessDuration="$duration"})})

$JitPolicyArr=@($JitPolicy)


# Execute
write-debug "`n`nExecuting command`n"
	$command = Set-AzJitNetworkAccessPolicy -resourceGroupName $resourceGroupName -location $location -Name $PolicyName -VirtualMachine $JitPolicyArr -Kind "Basic"
	write-verbose "Command: + $command"
    Invoke-Command -ScriptBlock {$command}


# Check the policy
Start-Sleep 5
Write-Host "Verifying...`n"
$currentPolicies = Get-AzJitNetworkAccessPolicy

if ($currentPolicies.Name -match $PolicyName)
	{
		write-host "Created successfully: $VmName is successfully configured under $PolicyName policy." -ForegroundColor Green
	}
elseif ($currentPolicies.VirtualMachines.id -match $VmName)
	{
		write-host "Script failed: Verification could not find $PolicyName! `nPlease try again using -Verbose switch to debug." -ForegroundColor Red
	}

