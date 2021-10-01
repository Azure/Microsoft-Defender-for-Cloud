###############################################################################################
# This script creates custom Role for Azure Security Center Just-in-time access.              #
# Purposed for those wish to have users to be able to request access to VMs                   #
# but not any other permissions.                                                              #
# Usage:                                                                                      #
# Set-JitLeastPrivilegedRole                                                                  #
#	-subscriptionId <Mandatory: subscription ID>                                              #
#	-roleName <Optional: default is "JIT Access Role">                                        #
#	-forApiOnly <Optional: if the requests are meant to initiate only from powershell/REST API#
###############################################################################################

param (
		[parameter(Mandatory=$true)]
		[string] $subscriptionId,
		[string] $roleName = "JIT Access Role",
		[switch] $forApiOnly
)
#PREREQUISITES
# Check powershell version
if ($host.Version.Major -lt 5)
	{
		Write-Host "Supported Windows versions are Server 2016/Windows 10 or above"
		break
	}

#Check if Az installed, install if not
$AzModule = Get-InstalledModule -Name Az -ErrorAction SilentlyContinue
if ($AzModule -eq $null) 
{
	Write-Warning "Azure PowerShell module not found"
	#check for Admin Privleges
	$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

	if (-not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)))
		{
		#No Admin, install to current user
		Write-Warning -Message "Can not install Az Module.  You are not running as Administrator"
		Write-Warning -Message "Installing Az Module to Current User Scope"
		Install-Module Az -Scope CurrentUser -Force
		Install-Module Az.Security -Scope CurrentUser -Force
		Install-Module Az.Accounts -Scope CurrentUser -Force
		}
	Else
		{
		#Admin, install to all users
		Write-Warning -Message "Installing Az Module to all users"
		Install-Module -Name Az -AllowClobber -Force
		Import-Module -Name Az.Accounts -Force
		Import-Module -Name Az.Security -Force
		}
}

#Check Azure subscription context
$subIdContext = (Get-AzContext).Subscription.Id 
if ($subIdContext -ne $subscriptionId)
	{
		$setSub = Set-AzContext -SubscriptionName $subscriptionId -ErrorAction SilentlyContinue
		if ($setSub -eq $Null) 
			{
				Write-Host "$subscriptionId is not set, please login and try again"
				Login-AzAccount
				break
			}
	}

#Create the role
$role = Get-AzRoleDefinition "Virtual Machine Contributor"
$role.Id = $null
$role.Name = $roleName
$role.Description = "Users that can enable access to Virtual Machines."
$role.Actions.Clear()
$role.Actions.Add("Microsoft.Security/locations/jitNetworkAccessPolicies/read")
$role.Actions.Add("Microsoft.Security/locations/jitNetworkAccessPolicies/initiate/action")
$role.Actions.Add("Microsoft.Security/policies/read")
if (!($forApiOnly))
{
	$role.Actions.Add("Microsoft.Compute/virtualMachines/read")
	$role.Actions.Add("Microsoft.Network/*/read")
}
$role.AssignableScopes.Clear()
$role.AssignableScopes.Add("/subscriptions/$subscriptionId")
$newRole = New-AzRoleDefinition -Role $role
if  ($newRole -eq $Null) 
{
    Write-Host "Fail to create $roleName" -ForegroundColor Red
}
else
{
Write-Host "$roleName successfully created" -ForegroundColor Green
Get-AzRoleDefinition -Name "$roleName"
}