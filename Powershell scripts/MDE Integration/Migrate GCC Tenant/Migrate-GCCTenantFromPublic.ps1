<#
.SYNOPSIS
This script invokes a WebRequest API against an Azure subscription to clear the Tenant ID from the Public tenants list.

.DESCRIPTION
This PowerShell script prompts for the subscription ID, checks the user's roles, required PowerShell modules, and then uses an authentication token to invoke a PUT command against a specified URI.

.PARAMETER SubscriptionId
The ID of the Azure subscription with required RBAC role permissions.

.NOTES
File Name      : Migrate-GCCTenantFromPublic.ps1
Prerequisite   : Azure PowerShell Modules (Az, Az.Accounts, Az.Resources)
                Install using: 'Install-Module -Name Az -Scope CurrentUser'
				Azure subscription RBAC Role:"Owner" or "Contributor" or "Security Admin"

.EXAMPLE
.\Migrate-GCCTenantFromPublic.ps1 -SubscriptionId "<Your_Subscription_ID>"

Description
-----------
This example runs the script with the specified SubscriptionId. Replace <Your_Subscription_ID> with the actual ID of the subscription you want to target.

#>
param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId
)

# Check if required modules are installed
$requiredModules = @("Az", "Az.Accounts", "Az.Resources")

foreach ($module in $requiredModules) {
    if (-not (Get-InstalledModule -Name $module)) {
        Write-Host "Required module $module is not installed. Please install it using 'Install-Module $module -Scope CurrentUser' and then try again."
        exit
    }
	else
	{
		Write-Verbose "Required PowerShell module $module is installed" 
	}
}

#Subscription login
$subContext = Get-AzContext 
if (!($subContext.Subscription.Id) -OR $subContext.Subscription.Id -ne $subscriptionId)
{
	try 
	{
		Write-Verbose "Login to $SubscriptionId"
		Set-AzContext -SubscriptionId $subscriptionId 
	}
	catch
	{
		write-host Write-Host "You are not logged in. Please run 'Connect-AzAccount' to log in." 
		exit
	}
}


## Output subscription/Tenant in Context
write-host "You are successfully logged on to `n`tMicrosoft Tenant Id: `t$($subContext.Subscription.TenantId)`n`tAzure subscription Id: `t$($subContext.Subscription.Id)" -ForegroundColor Green

# Get the current user's object ID
$currentUserObjectId = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account.Id).Id

# Get the current user's role assignments in the specified subscription
$roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId"

																	

$hasRequiredRole = $false

foreach ($assignment in $roleAssignments) {
    if ($assignment.ObjectId -eq $currentUserObjectId) {
        $role = $assignment.RoleDefinitionName
		  
        if ($role -eq "Owner" -or $role -eq "Contributor" -or $role -eq "Security Admin") {
			Write-Verbose "Current user ID: $currentUserObjectId, Role: $role, Assignment Object Id - $($assignment.ObjectId)"
            $hasRequiredRole = $true
            break  # Exit the loop as soon as Owner, Contributor or Security Admin role is found
        }
    }
}

if (-not $hasRequiredRole) {
    Write-Host "You do not have Owner, Contributor or Security Admin role in the specified subscription."
    exit
}

# Get authentication token using Get-AzAccessToken
$token = Get-AzAccessToken -ResourceUrl "https://management.azure.com/"

$accessToken = $token.Token

# Construct the URI
$apiUri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/mdeOnboardings/RemoveTenantFromGccPublic?api-version=2021-10-01-preview"

# Invoke the PUT command
$headers = @{
    "Authorization" = "Bearer $accessToken"
}

# Display the PUT command
$putCommand = "Invoke-WebRequest -Uri $apiUri -Method PUT -Headers '$headers'"
Write-Verbose "`nFinal PUT Command: $putCommand`n"

try { 
	Write-Host "Executing the migration web request" -ForegroundColor yello
	$response = Invoke-WebRequest -Uri $apiUri -Method PUT -Headers $headers
	$response
	$response | ConvertTo-Json -Depth 100 | Out-File $env:TEMP\Migrate-GCCTenantFromPublic.log
	write-verbose "status code: $($response.StatusCode)" 
	if ($($response.StatusCode) -eq 200)
	{
		write-host "`nMigration request was sent successfully (Return code: $($response.StatusCode)). 
		`nLog file: $env:TEMP\Migrate-GCCTenantFromPublic.log" -ForegroundColor Green
	}
} 
catch {
	Write-Host "Exception! `nStatusCode:" $_.Exception.Response.StatusCode.value__ 
	Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription 
}