# Disable AAD Account (non Admin) and revoke all Auth Tokens
author: Giulio Astori

Once an account is compromised either by its credential password or by its authentication token, it can be used for many malicious additional activities that will allow the intruder to escalate the privileges, moving laterally, etc. <br>
Open-source tools such as MicroBurst or PowerZure, developed for research objectives, are also used maliciously simply by weaponize them. <br>
These tools allow a malicious actor to assess and exploit resources within Microsoft cloud platforms by leveraging a compromised Azure Active Directory account and/or its token. <br>

Open-source tools such as MicroBurst or PowerZure, developed for research objectives, are also used maliciously simply by weaponize them. <br>
These tools allow a malicious actor to assess and exploit resources within Microsoft cloud platforms by leveraging a compromised Azure Active Directory account and/or its token. <br>
Azure Resource Manager (ARM) is the deployment and management service for Azure. <br>
It provides the management layer that enables you to create, update, and delete resources in your Azure account. <br>
It can be leveraged either via Azure Portal, via Rest API or using PowerShell, Azure CLI and SDKs. Read more about Azure Resource Manager here https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview.

This management layer is crucial; therefore, it is important to protect it. <br>
Microsoft Defender for Resource Manager protects against potential attacks including the use of exploitation tools like MicroBurst or PowerZure which will leverage compromised account and their tokens to authenticate and exploit the environment for privilege escalation, lateral movement, persistence, and more. Read more about the Microsoft Defender for Resource Manager here https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-resource-manager-introduction. <br>
The authentication bearer token is an access token that contains claims that you can use in Azure Active Directory to identify the granted permissions to your API. <br>
Once an attack is detected by Defender for Resource Manager, if an Azure Active Directory (Azure AD) Account has been utilized, you will need to act promptly and mitigate the compromised account. <br>
Of course, you can do it manually, but automated response will ensure that the proper mitigation is indeed applied. <br>
If an account is compromised you would disable the account temporarily, revoke all the associated authentication token, and reset the password. To automate this process, you can use this Azure Logic App we have developed to disable the account, revoke all the active tokens and notify the account’s manager if it exists or simply to a designated email address.
You can deploy the Azure Logic App in your Subscription and use it with the Defender for Cloud Workflow Automation configured for Alerts generated from the Defender for Resource Manager.


Note: This Log App will not be able to disable users if they are eligible or have active admin roles.<br>



<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FDisable-AAD-Account-Revoke-Tokens%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FDisable-AAD-Account-Revoke-Tokens%2Fazuredeploy.gov.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

**Additional Post Install Notes:**

The Logic App creates and uses a Managed System Identity (MSI) to authenticate and authorize against management.azure.com (or management.usgovcloudapi.net if in Azure Gov) to obtain PrincipalIDs assigned to the Azure Resource. The MSI is also used to authenticate and authorize against graph.windows.net to obtain RBAC Objects by PrincipalIDs. 

1. Assign API permissions to the managed identity so that we can search for user's manager. You can find the managed identity object ID on the Identity blade under Settings for the Logic App. If you don't have Azure AD PowerShell module, you will have to install it and connect to Azure AD PowerShell module. https://docs.microsoft.com/powershell/azure/active-directory/install-adv2?view=azureadps-2.0
```powershell
$MIGuid = "<Enter your managed identity guid here>"
$MI = Get-AzureADServicePrincipal -ObjectId $MIGuid

$GraphAppId = "00000003-0000-0000-c000-000000000000"
$PermissionName1 = "User.Read.All"
$PermissionName2 = "User.ReadWrite.All"
$PermissionName3 = "Directory.Read.All"
$PermissionName4 = "Directory.ReadWrite.All"

$GraphServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$GraphAppId'"
$AppRole1 = $GraphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName1 -and $_.AllowedMemberTypes -contains "Application"}
New-AzureAdServiceAppRoleAssignment -ObjectId $MI.ObjectId -PrincipalId $MI.ObjectId `
-ResourceId $GraphServicePrincipal.ObjectId -Id $AppRole1.Id

$AppRole2 = $GraphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName2 -and $_.AllowedMemberTypes -contains "Application"}
New-AzureAdServiceAppRoleAssignment -ObjectId $MI.ObjectId -PrincipalId $MI.ObjectId `
-ResourceId $GraphServicePrincipal.ObjectId -Id $AppRole2.Id

$AppRole3 = $GraphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName3 -and $_.AllowedMemberTypes -contains "Application"}
New-AzureAdServiceAppRoleAssignment -ObjectId $MI.ObjectId -PrincipalId $MI.ObjectId `
-ResourceId $GraphServicePrincipal.ObjectId -Id $AppRole3.Id

$AppRole4 = $GraphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName4 -and $_.AllowedMemberTypes -contains "Application"}
New-AzureAdServiceAppRoleAssignment -ObjectId $MI.ObjectId -PrincipalId $MI.ObjectId `
-ResourceId $GraphServicePrincipal.ObjectId -Id $AppRole4.Id

2. Open the playbook in the Logic App Designer and authorize Azure AD and Office 365 Outlook Logic App connections<br><br>
