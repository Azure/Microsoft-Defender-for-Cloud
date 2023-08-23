# Azure PowerShell Script for Invoking REST API

This PowerShell script allows you to invoke a REST API against an Azure subscription. The script prompts for the subscription ID, checks the user's roles, and then uses an authentication token to invoke a PUT command against a specified URI.

## Prerequisites

- PowerShell 7 or later
- Azure PowerShell Modules (Az, Az.Accounts, Az.Resources).  
  If missing, you can install them using:
  `Install-Module -Name Az -Scope CurrentUser`
  `Install-Module -Name Az.Accounts -Scope CurrentUser`
  `Install-Module -Name Az.Resources -Scope CurrentUser`

## Usage

1. Open a PowerShell terminal.

2. Run the script:  
`.\Migrate-GCCTenantFromPublic.ps1 -SubscriptionId "<Your_Subscription_ID>"`

   - **Mandatory**: Replace `<Your_Subscription_ID>` with the actual ID of the subscription you want to target.   
   - If the required modules are not installed, stop the script and install them as instructed above.

4. Follow the prompts and enter your Azure credentials if needed.

5. The script will verify your role in the specified subscription and then invoke the PUT command against the specified REST API.

## Notes

- Make sure you have the necessary permissions to perform the operation specified by the REST API.
- Security credentials should be handled carefully. Consider using more secure methods like Azure Managed Identities or Azure Key Vault for credential management.
- The script checks for the "Owner" or "Contributor" roles. Ensure you have either of these roles in the specified subscription.
