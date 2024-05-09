# Azure PowerShell Script for Invoking WebRequest API

This PowerShell script allows you to invoke a WebRequest API against an Azure subscription. The script prompts for the subscription ID, checks the user's roles, and then uses an authentication token to invoke a PUT command against a specified URI.

## Prerequisites

- PowerShell 5 or later
- Azure PowerShell Modules (Az, Az.Accounts, Az.Resources).  
  If missing, you can install them now. On elevated PowerShell terminal execute:  
  `Install-Module -Name Az -Scope CurrentUser`  
  `Install-Module -Name Az.Accounts -Scope CurrentUser`  
  `Install-Module -Name Az.Resources -Scope CurrentUser`  
 - Azure subscription RBAC Role:"Owner" or "Contributor" or "Security Admin"
 

## Usage
1. `Login-AzAccount` - To log in the tenant 
2. Open an elevated PowerShell terminal.
3. Have the target **Azure subscription ID** which you have one of the require RBAC.
      - To list all Azure Subscriptions under the tenant run `Get-AzSubscription`
      - To set the subscription to work on run `Set-AzContext -SubscriptionId <subscription Id>`
5. Run the script:  
`.\Migrate-GCCTenantFromPublic.ps1 -SubscriptionId "<Your_Subscription_ID>"`
   - **Mandatory**: Replace `<Your_Subscription_ID>` with the actual ID of the subscription you want to target.   
   - If the required modules are not installed, stop the script and install them as instructed above.
6. Return output is written to the console output and to *$env:TEMP\Migrate-GCCTenantFromPublic.log* file with high verbosity.
7. The script will verify your role in the specified subscription and then invoke the PUT command against the specified REST API.



## Notes

- Make sure you have the necessary permissions to perform the operation specified by the REST API.
- The script checks for the subscription's "Owner" or "Contributor" roles. Ensure you have either of these roles in the specified subscription.
- The subscription to run the script agains must be enabled with 'Defender for Servers Plan 2'.
   - To identify such subscription use this snippet in Powershell console:
     ```
     $subscriptions = Get-AzSubscription
     foreach ($subscription in $subscriptions) {Select-AzSubscription -Subscription $subscription;     $enabledServersPlan = Get-AzSecurityPricing | Where-Object {$_.Name -eq "VirtualMachines" -and $_.PricingTier -eq "Standard"} ; if ($enabledServersPlan) {  Write-host "Subscription $subscription.Id is enabled" -ForegroundColor Green}}
     ```

