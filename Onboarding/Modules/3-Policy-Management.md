# Module 3 - Policy Management

## Step #3 - Assign and customize the ASC default policy
To view their security posture across their entire Azure environment, customers need to activate Security Center on every subscription in their hierarchy. Activating Security Center means that customers need to register their subscriptions to the Security Center Resource Provider *'Microsoft.Security'*. This action also triggers the assignment of the Azure Security Benchmark policy initiative (id: `1f3afdf9-d0c9-4c3d-847f-89da613e70a8`) on the subscription, if the Azure Security Benchmark policy initiative has not already been assigned neither to the subscription itself nor to a management group higher up in the hierarchy.
We recommend that customers review each of the security recommendations in this default initiative to determine whether they are appropriate for the various subscriptions and resource groups in their organization. A list of the built-in policies and the available effect(s) in the Azure Security Benchmark policy initiative can be found [here](https://docs.microsoft.com/en-us/azure/security-center/policy-reference).

Assigning the Azure Security Benchmark policy initiative can happen on different scopes. The scope that customers choose depends on who in the organization wants to control the policy.
* **Management Group scope**  
This scope is recommended for customers who want to centrally control the Azure Security Benchmark policy initiative ([Option A](https://github.com/martinalang/ASCOnboarding/blob/main/Onboarding/Modules/2-Roles-and-Permissions.md#option-a---security-controls-are-deployed--by-a-central-team) in the responsibility model). To assign the Azure Security Benchmark policy initiative on a management group, customers needs to perform the following steps:
    1. They need to assign the default ASC policy initiative to the management group.
See *“Assign the Azure Security Benchmark policy initiative to a management group”* in the automation options below.
    2. Because the assigned policy initiative will only be evaluated for subscriptions that have already been onboarded to Azure Security Center, customers need to onboard each subscription within the management group. The automation options for this step are shown in section *“Enable Azure Security Center on a subscription”*.
    3. Some of the subscriptions may have been onboarded to ASC in the past and thus may already have the ASC default policy assigned at the subscription level. If this is not desired, customers can use an [Azure PowerShell script](https://github.com/Azure/Azure-Security-Center/tree/master/Security policy configuration/Remove ASC Default policy assignment from Azure subcription if it exists at management group) to remove the default assignments on the subscription level. However, customers should be aware that any customizations made to the subscription level policy by the workload owners will be lost in this process.
*	**Individual subscription scope**  
This scope is recommended if workload owners are responsible for deploying their own security controls ([Option B](https://github.com/martinalang/ASCOnboarding/blob/main/Onboarding/Modules/2-Roles-and-Permissions.md#option-b--security-controls-are-deployed-by-workload-owners) in the responsibility model). To assign the Azure Security Benchmark policy initiative on the subscription level, customers should onboard their subscription to Azure Security Center by using any of the options listed for *“Enable Azure Security Center on a subscription”* in the automation section below. 
*	**Management and individual subscription scope**  
It is possible to assign the ASC default initiative on both a management group and on individual subscriptions. For example, workload owners can decide to assign the default initiative to their subscription in addition to what a centrally governed policy initiative may define. In this case, Azure Security Center shows a list of aggregated recommendations and alerts, however subscription controls cannot override management group controls.

### Automation options
* Assign the Azure Security Benchmark policy initiative to a management group
    * [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azpolicyassignment?view=azps-5.3.0)  
` $definition = Get-AzPolicySetDefinition -Name 1f3afdf9-d0c9-4c3d-847f-89da613e70a8
New-AzPolicyAssignment -Name 'ASCDefault' -PolicySetDefinition $definition`
    * [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/policy/assignment?view=azure-cli-latest#az_policy_assignment_create)  
`az policy assignment create --name ‘ASCDefault’ –policy-set-definition 1f3afdf9-d0c9-4c3d-847f-89da613e70a8`
    * [ARM Template](https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/policyassignments)  
To create a *Microsoft.Authorization/policyAssignments* resource, add the following JSON to the resources section of your ARM template:  
        ```json
        {  
          "type": " Microsoft.Authorization/policyAssignments",  
          "name": "ASCDefault",  
          "apiVersion": "2019-09-01",  
          "properties": {  
            "policyDefinitionId": "1f3afdf9-d0c9-4c3d-847f-89da613e70a8"  
          }  
        }
        ```
    * [Azure REST API](https://docs.microsoft.com/en-us/rest/api/resources/policyassignments/create)  
Make a PUT request to https://management.azure.com/{scope}/providers/Microsoft.Authorization/policyAssignments/{policyAssignmentName}?api-version=2020-09-01
with the following request body  
      ```json
      {
        "properties": {
          "policyDefinitionId": "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8",
        }
      }
      ```

* Enable Azure Security Center on a subscription 
    * Azure Policy: [Enable Azure Security Center on your subscription](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2Fac076320-ddcf-4066-b451-6154267e8ad2)  
To register **existing** subscriptions to the free pricing tier that are currently not monitored by ASC, customers need to assign this  built-in policy to the appropriate scope, e.g. to the Root management group.
To register **newly created** subscriptions, customers have to create a remediation task for the policy. This is because subscriptions are not a top-level ARM resource (yet), so they currently do not trigger a policy evaluation when they are created.
Depending on how often the organization creates new subscriptions, this is something that customers may want to automate and run on a regular basis. They can create the remediation task through
        * [Azure CLI](https://docs.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources#create-a-remediation-task-through-azure-cli)
        * [Azure PowerShell](https://docs.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources#create-a-remediation-task-through-azure-powershell)
        * [Azure REST API](https://docs.microsoft.com/en-us/rest/api/policy-insights/remediations/createorupdateatmanagementgroup)
    * [Azure PowerShell](https://docs.microsoft.com/en-us/azure/security-center/security-center-powershell-onboarding)
    * [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/provider?view=azure-cli-latest#az_provider_register)
    * [Azure REST API](https://docs.microsoft.com/en-us/rest/api/resources/providers/register)

> *See the [Scheduled automation](../Misc/Scheduled-Automation.md) table for further implementation details*

<br />

## Step #4 - Choose standards for your compliance dashboard (recommended)
With the regulatory compliance dashboard in ASC, customers can compare the configuration of their resources with requirements in industry standards, regulations, and benchmarks. We recommend to select the highest scope for which the standard is applicable – e.g., the Root MG - so that compliance data is aggregated and tracked for all nested resources. In essence, a regulatory standard is a set of policies that is applied to the customer’s chosen scope upon assignment.  
Since assigning a regulatory compliance standard is normally a one-time task, most customers use the Azure Portal to do the assignment. Assigning a regulatory compliance standard with automation tools is possible, but while some of these built-in standards come with default parameters, some also require mandatory parameters that customers then need to specify in their scripts. An example can be found below.

### Automation options

* Azure Policy: Assign the appropriate policy via
    * [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azpolicyassignment?view=azps-5.3.0)  
` $definition = Get-AzPolicySetDefinition -Name 1f3afdf9-d0c9-4c3d-847f-89da613e70a8
New-AzPolicyAssignment -Name 'ASCDefault' -PolicySetDefinition $definition`
    * [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/policy/assignment?view=azure-cli-latest#az_policy_assignment_create)  
`az policy assignment create --name ‘ASCDefault’ –policy-set-definition 1f3afdf9-d0c9-4c3d-847f-89da613e70a8`
    * [Azure REST API](https://docs.microsoft.com/en-us/rest/api/resources/policyassignments/create)  
Make a PUT request to https://management.azure.com/{scope}/providers/Microsoft.Authorization/policyAssignments/{policyAssignmentName}?api-version=2020-09-01
with the following request body  
      ```json
      {
        "properties": {
          "policyDefinitionId": "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8",
        }
      }
      ```
    * [ARM Template](https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/policyassignments)  
To create a *Microsoft.Authorization/policyAssignments* resource, add the following JSON to the resources section of your ARM template:  
        ```json
        {  
          "type": " Microsoft.Authorization/policyAssignments",  
          "name": "ASCDefault",  
          "apiVersion": "2019-09-01",  
          "properties": {  
            "policyDefinitionId": "1f3afdf9-d0c9-4c3d-847f-89da613e70a8"  
          }  
        }
        ```

<br />

## Step #5 - Ensure resources are secure by default through Azure Policy and Azure Blueprints (recommended)
Customers should aim to improve their overall Secure Score by continuously driving security posture enhancements in their environment. This also includes provisioning new resources that are secure by default to prevent frequent fluctuations in the secure score. Having a solid Azure Governance enables customers to ensure that new resources that are deployed are going to have certain standards, patterns and configurations. To ensure proper governance, customers should leverage Azure Policy and Azure Blueprints. This will allow them to enforce policies (*DeployIfNotExists* policies) and reject deployments (Deny policies) of resources that are not following certain standards.  
New subscriptions that are being provisioned in the organization should also be correctly configured by default. They should be created in the correct management group to inherit the appropriate policy set.

<br />

## Step #6 - Assign custom policies (optional)
Customers can use Azure Policy to create custom policy definitions and receive recommendations if their environment doesn’t follow the policies they have created. We recommend to create the following resources on the widest scope required, e.g. the Root MG or any other suitable management group.

The steps to create custom policies in ASC are as follows:
1.	Create one or more policy definitions with the *metadata/securityCenter* property and validate that they work as intended. An example of how to define a policy with this property can be found [here](https://docs.microsoft.com/en-us/azure/security-center/custom-security-policies#enhance-your-custom-recommendations-with-detailed-information).
2.	Create a policy initiative that includes the created policy/policies and the `metadata` property with the value `{"ASC": "true"}`.
3.	Assign the policy initiative.

After some time, ASC will detect the policies and they will appear in the recommendations as well as alongside the built-in initiatives in the regulatory compliance dashboard.

### Automation options

* **To create the policy definition(s)**
    * [REST API](https://docs.microsoft.com/en-us/rest/api/resources/policydefinitions/createorupdateatmanagementgroup)
    * [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azpolicydefinition?view=azps-5.5.0)
    * [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/policy/definition?view=azure-cli-latest#az_policy_definition_create)
    * [ARM Template](https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/policydefinitions)
* **To create the policy initiative**
    * **[Azure PowerShell](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azpolicysetdefinition?view=azps-5.5.0)**  
    ```
        New-AzPolicySetDefinition -Name '{policySetDefinitionName}' -DisplayName '{policySetDefinitionName}' -Metadata '{"ASC":"true"}' -ManagementGroupName "{MgmtGroupName}" -PolicyDefinition '[{"policyDefinitionId": "{policyDefinitionID}"}]'
    ```
    * **[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/policy/set-definition?view=azure-cli-latest#az_policy_set_definition_create)**  
    ```
        az policy set-definition create --name {policySetDefinitionName} --display-name {policySetDefinitionName} --management-group {managementGroupId} --metadata ASC=true --definitions "[ { \"policyDefinitionId\": \"{policyDefinitionID}\"}]"
    ```
    * **[REST API](https://docs.microsoft.com/en-us/rest/api/resources/policysetdefinitions/createorupdateatmanagementgroup)**  
    Make a PUT request to   https://management.azure.com/providers/Microsoft.Management/managementGroups/{managementGroupId}/providers/Microsoft.Authorization/policySetDefinitions/{policySetDefinitionName}?api-version=2020-09-01  
with the following request body
        ```json
        {
           "properties": {
              "displayName": "{policySetDefinitionName}",
              "metadata": {
                 "ASC": "true"
              },
              "policyDefinitions": [
                 {
                    "policyDefinitionId": "{policyDefinitionID}"
                 }
              ]
           }
        }
        ```
    * **[ARM Template](https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/policysetdefinitions)**  
      To create a *Microsoft.Authorization/policySetDefinitions* resource on a management group scope, use the following ARM template:
      ```json
        {
            "$schema": "https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "parameters": {},
            "resources": [
                {
                    "name": "{PolicySetDefinitionName}",
                    "type": "Microsoft.Authorization/policySetDefinitions",
                    "apiVersion": "2020-03-01",
                    "properties": {
                       "displayName": "{PolicySetDefinitionName}",
                       "metadata": {
                            "ASC": "true"
                        },
                        "policyDefinitions": [
                            {
                                "policyDefinitionId": "{PolicyDefinitionId}"
                            }
                        ]
                    }
                }
            ]
        }
        ```

* **To assign the policy initiative**
    * **[Azure PowerShell](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azpolicyassignment?view=azps-5.5.0)**  
    ```
    New-AzPolicyAssignment -Name '{AssignmentName}' -Scope '/providers/Microsoft.Management/managementGroups/{MG-ID}' -PolicySetDefinition (Get-AzPolicySetDefinition -Id '{PolicyInitiativeID}')
    ```
    * **[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/policy/assignment?view=azure-cli-latest#az_policy_assignment_create)**  
    ```
    az policy assignment create --name {AssignmentName} --scope "/providers/Microsoft.Management/managementgroups/{MG-ID}" --policy-set-definition "{PolicyInitiativeID}"
    ```
    * **[REST API](https://docs.microsoft.com/en-us/rest/api/resources/policyassignments/create)**  
    Make a PUT request to  
    https://management.azure.com/providers/Microsoft.Management/managementGroups/{MG-ID}/providers/Microsoft.Authorization/policyAssignments/{policyAssignmentName}?api-version=2020-09-01  
    with the following request body  
        ```json
        {
           "properties": {
              "policyDefinitionId": "{policyDefinitionID}"
           }
        }
        ```

    * **[ARM Template](https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/policyassignments)**  
    To create a *Microsoft.Authorization/policyAssignments* resource on a management group scope, use the following ARM template:
    ```json
        {
        "$schema": "https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {},
        "resources": [
            {
                "name": "{AssignmentName}",
                "type": "Microsoft.Authorization/policyAssignments",
                "apiVersion": "2020-03-01",
                "properties": {
                    "policyDefinitionId": "{PolicyInitiativeID}"
                }
            }
        ]
    }
    ```

<br />

### &#8680; Continue with the next steps: [Module 4 - Onboarding ASC Features](./4-Onboarding-ASC-Features.md)


