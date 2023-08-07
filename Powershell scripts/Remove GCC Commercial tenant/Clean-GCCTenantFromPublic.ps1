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

# Check if the user is logged in
if (-not (Get-AzContext)) {
    Write-Host "You are not logged in. Please run 'Connect-AzAccount' to log in."
    exit
}

# Get the current user's object ID
$currentUserObjectId = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account.Id).Id

# Get the current user's role assignments in the specified subscription
$roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId"

																	

$hasRequiredRole = $false

foreach ($assignment in $roleAssignments) {
    if ($assignment.ObjectId -eq $currentUserObjectId) {
        $role = $assignment.RoleDefinitionName
		  
        if ($role -eq "Owner" -or $role -eq "Contributor") {
			Write-Verbose "Current user ID: $currentUserObjectId, Role: $role, Assignment Object Id - $($assignment.ObjectId)"
            $hasRequiredRole = $true
            break  # Exit the loop as soon as Owner or Contributor role is found
        }
    }
}

if (-not $hasRequiredRole) {
    Write-Host "You do not have Owner or Contributor role in the specified subscription."
    exit
}

# Get authentication token using Get-AzAccessToken
$token = Get-AzAccessToken -ResourceUrl "https://management.azure.com/"

$accessToken = $token.Token

# Construct the URI
$apiUri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Security/mdeOnboardings/RemoveTenantFromGccPublic?api-version=2021-10-01-preview"


# Display the PUT command
$putCommand = "Invoke-RestMethod -Uri $apiUri -Method Put -Headers @{""Authorization"" = ""Bearer $accessToken""}"
Write-Verbose "Final PUT Command: $putCommand"

# Invoke the PUT command
$headers = @{
    "Authorization" = "Bearer $accessToken"
}

$response = Invoke-RestMethod -Uri $apiUri -Method Put -Headers $headers

# Output the response
write-host "Response: $response"
$response