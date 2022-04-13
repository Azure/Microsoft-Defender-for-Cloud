# Module 2 - Roles & Permissions

## Step #1 - Create a central team that will be responsible for tracking and/or enforcing security on your Azure environment
To manage Microsoft Defender for Cloud organization-wide, it is necessary that customers have named a team who is responsible for monitoring and governing their Azure environment from a security perspective.  
Depending on the responsibility model in the organization, we most commonly see one of the following two options how a central security team operates within an organization.

### Option A - Security controls are deployed  by a central team
Deploying security controls is done by a central team. The central security team decides which security policies will be implemented in the organization and who has permissions to control the policy set. They may also have the power to remediate non-compliant resources, and enforce resource isolation in case of a security threat or configuration issue. Workload owners on the other hand are mainly responsible for managing their cloud workloads, but need to follow the security  policies that the central team has deployed.

| Action |	Workload owners	| Central IT Security team
| --- | :---: | :---:
Manage a cloud workload and its related resources |	&#10003; |	&#10005;
Define, monitor and enforce the company’s security policies to ensure the appropriate protections are in place |&#10003; <br /> (Only in addition to what the central team defines)|	&#10003;
Need to understand the company’s security posture across workloads |	&#10005; |	&#10003;
Need to be informed of major attacks and risks |	&#10005;|	&#10003;
Auto-remediate non-compliant resources |	&#10005; |	&#10003;

Option A is most suitable for companies with a high level of automation, to ensure automated response processes to vulnerabilities and threats and maintain a high level of service availability.

### Option B – Security controls are deployed by workload owners
Deploying security controls is done by the workload owners, they own the policy set and can therefore decide which security policies are applicable to their resources. They need be aware of, understand and act upon security alerts and recommendations for their own resources. The central security team on the other hand only acts as a controlling entity, without write access to any of the workload subscriptions or resources. However, they have insights into the overall security posture of the organization and they may hold the workload owners accountable for improving their security posture.

| Action |	Workload owners	| Central IT Security team
| --- | :---: | :---:
Manage a cloud workload and its related resources |	&#10003; |	&#10005;
Define, monitor and enforce the company’s security policies to ensure the appropriate protections are in place |&#10003;|	&#10005;
Need to understand the company’s security posture across workloads |	&#10005; |	&#10003;
Need to be informed of major attacks and risks |	&#10003;|	&#10003;
Depending on the criticality of the workload, they may be responsible for 24/7 operations |	&#10003; |	&#10005;

Option B is most suitable for organizations that need visibility into their overall security posture, but at the same time want to keep responsibility for security with the workload owners.


> &#x26A0;  
> This section is intended to give customers an idea of the responsibility models we see at both ends of the spectrum. These are by no means the only options; various combinations of these two options are possible and may even be more appropriate in a specific organization setup. Often customers will choose
<br />

## Step #2 - Assign the necessary RBAC permissions to the central security team
Customers need to make sure that the central security team has been assigned the necessary RBAC rights on the appropriate scope to follow the deployment steps in this document. We recommend to follow the principle of least privilege when assigning permissions and suggest to assign the following built-in roles:

| Action |	RBAC Role	| Option A) | Option B)
| --- | :---: | :---: | :---:
Need to view configurations, update the security policy, and dismiss recommendations and alerts in Microsoft Defender for Cloud.	| **Security Admin** on Root MG*	|	&#10003; |	&#10003;
Need to have read and write access to Azure resources for remediation (this includes assigning the appropriate permission to the managed identity used by a deployIfNotExists or modify policy)	| **Contributor** on Root MG*	|	&#10003; |	&#10005;
Need to have read only access to Azure resources for investigation. (This does not include read access to secrets or data plane details)	| **Reader** on Root MG*	|	&#10005; |	&#10003;
> *Depending on the customer’s management group structure, an assignment lower in the management group hierarchy may be more appropriate.*

In addition to the roles that need to be assigned to the central security team, other personas in the customer’s organization like security auditors or a central SOC team may also need to have read access to the company’s security state. In this case, we recommend to grant them **Security Reader** permissions on the appropriate MG scope.

### Automation options
* **[ARM Template]()**
    * For Option A
    * For Option B
* **[Azure CLI]()**
    * For Option A
      * `az role assignment create --role 'Security Admin' --assignee-object-id '{AD-Group-ObjectID}' --scope '/providers/Microsoft.Management/managementGroups/{MG-ID}'`
      * `az role assignment create --role 'Contributor' --assignee-object-id '{AD-Group-ObjectID}' --scope '/providers/Microsoft.Management/managementGroups/{MG-ID}'`
    * For Option B
      * `az role assignment create --role 'Security Admin' --assignee-object-id '{ AD-Group-ObjectID}' --scope '/providers/Microsoft.Management/managementGroups/{MG-ID}'`
      * `az role assignment create --role 'Reader' --assignee-object-id '{AD-Group-ObjectID}' --scope '/providers/Microsoft.Management/managementGroups/{MG-ID}'` 
* **[Azure PowerShell]()**
    * For Option A
      * `New-AzRoleAssignment - ObjectId '{AD-Group-ObjectID}' -RoleDefinitionName ' Security Admin'  -Scope '/providers/Microsoft.Management/managementGroups/{MG-ID}'` 
      * `New-AzRoleAssignment - ObjectId '{AD-Group-ObjectID}' -RoleDefinitionName 'Contributor'  -Scope '/providers/Microsoft.Management/managementGroups/{MG-ID}'`
    * For Option B
      * `New-AzRoleAssignment - ObjectId '{AD-Group-ObjectID}' -RoleDefinitionName ' Security Admin'  -Scope '/providers/Microsoft.Management/managementGroups/{MG-ID}'`
      * `New-AzRoleAssignment - ObjectId '{AD-Group-ObjectID}' -RoleDefinitionName 'Reader'  -Scope '/providers/Microsoft.Management/managementGroups/{MG-ID}'`
* **[REST API]()**

<br />

### &#8680; Continue with the next steps: [Module 3 - Policy Management](./3-Policy-Management.md)
