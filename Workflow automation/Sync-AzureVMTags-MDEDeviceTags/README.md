# Sync-AzureVMTags-MDEDeviceTags

author: Nathan Swift, Matt Egen

This Logic App can be set to run daily,weekly. Upon scheduled trigger it will match Azure VMs to MDE Devices and Sync the Azure VM tags to the MDE Device Tags on the Server in MDE. This can be useful to help with reporting in MDE portal and MDE Tags can also be tied to a Device Group so you can Separate Permissions to Servers and also set Automation Investigation & Remediation (AIRs) to none, Semi, or Full for the Servers onboarded to MDE from Defender for Servers P1/P2.

NOTES:

In the deployment set the paramater to the Tag you want to be applied

In the deployment set the paramater to how matching occurs:

- name - match by server name between Azure and MDE
- namepriv - match by server name and private ip address
- nameprivpublic - match by server name, private ip address, and public ip address

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FSync-AzureVMTags-MDEDeviceTags%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FSync-AzureVMTags-MDEDeviceTags%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

**Additional Post Install Notes:**

The Logic App creates and uses a Managed System Identity (MSI) to authenticate and authorize against management.azure.com and api.securitycenter.windows.com to obtain azure resource information, MDE Device information and write a tag to the MDE Device.

Assign RBAC 'Reader' role to the Logic App at the MG or Subscription level.

- **For Gov Only** You will need to update the HTTP action URL to the correct URL documented [here](https://docs.microsoft.com/microsoft-365/security/defender-endpoint/gov?view=o365-worldwide#api)
- You will need to grant Ti.ReadWrite permissions to the managed identity. Run the following code replacing the managed identity object id. You find the managed identity object id on the Identity blade under Settings for the Logic App.

```powershell
$MIGuid = "<Enter your managed identity guid here>"
$MI = Get-AzureADServicePrincipal -ObjectId $MIGuid

$MDEAppId = "fc780465-2017-40d4-a0c5-307022471b92"
$PermissionName1 = "Machine.ReadWrite.All"
$PermissionName2 = "AdvancedQuery.Read.All"

$MDEServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$MDEAppId'"
$AppRole1 = $MDEServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName1 -and $_.AllowedMemberTypes -contains "Application"}
$AppRole2 = $MDEServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName2 -and $_.AllowedMemberTypes -contains "Application"}

New-AzureAdServiceAppRoleAssignment -ObjectId $MI.ObjectId -PrincipalId $MI.ObjectId `
-ResourceId $MDEServicePrincipal.ObjectId -Id $AppRole1.Id

New-AzureAdServiceAppRoleAssignment -ObjectId $MI.ObjectId -PrincipalId $MI.ObjectId `
-ResourceId $MDEServicePrincipal.ObjectId -Id $AppRole2.Id
```
