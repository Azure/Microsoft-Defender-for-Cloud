# Remove-KeyVault-AccessPolicies-RBACPermissions

**Author(s)**: Future Kortor & Bojan Magusic

**Contributor(s)**: Safeena Begum, Tom Janetschek

Most Microsoft Defender for Key vault alerts derive from a user trying to access the Key vault in a suspicious manner.  Some examples of these alerts include “Access from a suspicious IP address to a key vault” and “Unusual user accessed a key vault”. When this automation is executed it will automatically respond to these (and other) Key vault alerts, by removing the access policies and RBAC permissions the user has in Key vault.

**Logic Implemented:**

* Remove the access policies the user has in this KV
* Remove RBAC permissions the user has in this KV

**Deploy the template by clicking the respective button below.**

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FWorkflow%2520automation%2FRemove-KeyVault-AccessPolicies-RBACPermissions%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FWorkflow%2520automation%2FRemove-KeyVault-AccessPolicies-RBACPermissions%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

**Additional Post Install Notes:**

The ARM template will create the Logic App Playbook. In order to deploy the automation, your account needs to be granted **Contributor** rights on the target Subscriptions. Note that you can assign permissions only if your account has been assigned **Owner** or **User Access Administrator** roles. Also, ensure that all selected subscriptions are registered to Microsoft Defender for Cloud.

**To assign Managed Identity to specific scope:**

1. Make sure you have User Access Administrator or Owner permissions for this scope.
2. Go to the subscription/management group page.
3. Press Access Control (IAM) on the navigation bar.
4. Press +Add and Add role assignment.
5. Select the respective role.
6. Assign access to Logic App.
7. Select the subscription where the Logic App was deployed.
8. Select Remove-KeyVault-AccessPolicies-RBACPermissions Logic App.
9. Press save.