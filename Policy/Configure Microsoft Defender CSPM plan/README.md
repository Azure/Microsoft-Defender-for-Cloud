# Configure Microsoft Defender CSPM Plan (All Extensions)

## Overview

This custom policy enables **Microsoft Defender for Cloud Security Posture Management (CSPM)** at subscription scope and exposes all 9 available CSPM extensions as independently configurable parameters.

It extends the built-in policy [Configure Microsoft Defender CSPM plan](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F72f8cee7-2937-403d-84a1-a4e3e57f3c21) (`72f8cee7-2937-403d-84a1-a4e3e57f3c21`) by adding 4 extensions that are available in the ARM API but not configurable through the built-in policy.

---

## Why This Policy Exists

The built-in CSPM policy only exposes 5 of the 9 available extensions on `Microsoft.Security/pricings/CloudPosture`. The following extensions cannot be managed at scale through the built-in policy:

| Extension | Available in ARM API | Configurable via built-in policy |
|-----------|---------------------|----------------------------------|
| SensitiveDataDiscovery | ✅ | ✅ |
| ContainerRegistriesVulnerabilityAssessments | ✅ | ✅ |
| AgentlessDiscoveryForKubernetes | ✅ | ✅ |
| AgentlessVmScanning | ✅ | ✅ |
| EntraPermissionsManagement | ✅ | ✅ |
| ApiPosture | ✅ | ❌ |
| AgentlessServerlessPosture | ✅ | ❌ |
| ServerlessContainers | ✅ | ❌ |
| DatabricksSecurityPosture | ✅ | ❌ |

This policy fills that gap, enabling organizations to govern all CSPM extension states consistently across subscriptions via a single policy assignment at Management Group scope.

---

## Policy Details

| Property | Value |
|----------|-------|
| **Display Name** | Configure Microsoft Defender CSPM plan (All Extensions) |
| **Category** | Security Center |
| **Mode** | All |
| **Resource Type** | `Microsoft.Resources/subscriptions` |
| **Deployment Target** | `Microsoft.Security/pricings/CloudPosture` |
| **Deployment Scope** | Subscription |
| **API Version** | `2024-01-01` |
| **Required Role** | Contributor (`b24988ac-6180-42a0-ab88-20f7382dd24c`) |
| **Supported Effects** | `DeployIfNotExists`, `AuditIfNotExists`, `Disabled` |

---

## Parameters

| Parameter Name | Display Name | Allowed Values | Default | Notes |
|----------------|-------------|----------------|---------|-------|
| `effect` | Effect | `DeployIfNotExists`, `AuditIfNotExists`, `Disabled` | `DeployIfNotExists` | |
| `isSensitiveDataDiscoveryEnabled` | Sensitive Data Discovery Enabled | `True`, `False` | `True` | Also in built-in policy |
| `isContainerRegistriesVulnerabilityAssessmentsEnabled` | Container Registries Vulnerability Assessments Enabled | `True`, `False` | `True` | Also in built-in policy |
| `isAgentlessDiscoveryForKubernetesEnabled` | Agentless Discovery For Kubernetes Enabled | `True`, `False` | `True` | Also in built-in policy |
| `isAgentlessVmScanningEnabled` | Agentless VM Scanning Enabled | `True`, `False` | `True` | Also in built-in policy |
| `isEntraPermissionsManagementEnabled` | Entra Permissions Management Enabled | `True`, `False` | `True` | Also in built-in policy |
| `isApiPostureEnabled` | API Posture Enabled | `True`, `False` | `True` | **Not in built-in policy** |
| `isAgentlessServerlessPostureEnabled` | Agentless Serverless Posture Enabled | `True`, `False` | `True` | **Not in built-in policy** |
| `isServerlessContainersEnabled` | Serverless Containers Enabled | `True`, `False` | `True` | **Not in built-in policy** |
| `isDatabricksSecurityPostureEnabled` | Databricks Security Posture Enabled | `True`, `False` | `False` | **Not in built-in policy** |

---

## How It Works

### Compliance Evaluation

The policy evaluates compliance by checking:

1. `Microsoft.Security/pricings/CloudPosture` exists with `pricingTier = Standard`
2. The following extensions match the configured parameter values (checked via `count` expressions):
   - `SensitiveDataDiscovery`
   - `ContainerRegistriesVulnerabilityAssessments`
   - `AgentlessDiscoveryForKubernetes`
   - `AgentlessServerlessPosture`

> **Note:** Azure Policy enforces a limit of 5 `count` expressions per `existenceCondition`. This policy validates 4 extensions in the compliance check while deploying all 9 through the ARM template. Subscriptions will be re-evaluated and remediated if any of the 4 checked extensions drift from the desired state.

### Remediation

When a subscription is found non-compliant, the policy deploys an ARM template at subscription scope that sets all 9 extensions in a single `Microsoft.Security/pricings/CloudPosture` resource PUT operation.

To remediate existing non-compliant subscriptions after assignment, create a remediation task:

```bash
az policy remediation create \
  --name "remediate-cspm" \
  --policy-assignment "<assignment-id>" \
  --resource-discovery-mode ExistingNonCompliant
```

### Required RBAC

The policy assignment's managed identity requires the **Contributor** role at the scope where it is assigned (e.g., Management Group) in order to deploy `Microsoft.Security/pricings` resources into child subscriptions.

```bash
az role assignment create \
  --role "Contributor" \
  --assignee "<assignment-principal-id>" \
  --scope "/providers/Microsoft.Management/managementGroups/<mg-id>"
```

---

## Usage Example

### Azure CLI

```bash
# Assign the policy at Management Group scope
az policy assignment create \
  --name "cspm-all-extensions" \
  --display-name "Configure Microsoft Defender CSPM plan (All Extensions)" \
  --policy "<policy-definition-id>" \
  --scope "/providers/Microsoft.Management/managementGroups/<mg-id>" \
  --location "eastus" \
  --mi-system-assigned \
  --params '{
    "effect": { "value": "DeployIfNotExists" },
    "isSensitiveDataDiscoveryEnabled": { "value": "True" },
    "isContainerRegistriesVulnerabilityAssessmentsEnabled": { "value": "True" },
    "isAgentlessDiscoveryForKubernetesEnabled": { "value": "True" },
    "isAgentlessVmScanningEnabled": { "value": "True" },
    "isEntraPermissionsManagementEnabled": { "value": "True" },
    "isApiPostureEnabled": { "value": "True" },
    "isAgentlessServerlessPostureEnabled": { "value": "True" },
    "isServerlessContainersEnabled": { "value": "True" },
    "isDatabricksSecurityPostureEnabled": { "value": "True" }
  }'
```

### Terraform

```hcl
resource "azurerm_management_group_policy_assignment" "cspm" {
  name                 = "cspm-all-extensions"
  display_name         = "Configure Microsoft Defender CSPM plan (All Extensions)"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/<mg-id>"
  policy_definition_id = azurerm_policy_definition.cspm.id
  location             = "eastus"

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    effect                                               = { value = "DeployIfNotExists" }
    isSensitiveDataDiscoveryEnabled                      = { value = "True" }
    isContainerRegistriesVulnerabilityAssessmentsEnabled = { value = "True" }
    isAgentlessDiscoveryForKubernetesEnabled             = { value = "True" }
    isAgentlessVmScanningEnabled                         = { value = "True" }
    isEntraPermissionsManagementEnabled                  = { value = "True" }
    isApiPostureEnabled                                  = { value = "True" }
    isAgentlessServerlessPostureEnabled                  = { value = "True" }
    isServerlessContainersEnabled                        = { value = "True" }
    isDatabricksSecurityPostureEnabled                   = { value = "False" }
  })
}
```

---

## Verification

After remediation completes, verify all extensions are configured correctly:

```bash
az rest --method get \
  --url "https://management.azure.com/subscriptions/<subscription-id>/providers/Microsoft.Security/pricings/CloudPosture?api-version=2024-01-01" \
  --query "properties.extensions[].{Name:name, Enabled:isEnabled}"
```

Expected output:

```json
[
  { "Name": "SensitiveDataDiscovery",                       "Enabled": "True" },
  { "Name": "ContainerRegistriesVulnerabilityAssessments",  "Enabled": "True" },
  { "Name": "AgentlessDiscoveryForKubernetes",              "Enabled": "True" },
  { "Name": "AgentlessVmScanning",                          "Enabled": "True" },
  { "Name": "EntraPermissionsManagement",                   "Enabled": "True" },
  { "Name": "ApiPosture",                                   "Enabled": "True" },
  { "Name": "AgentlessServerlessPosture",                   "Enabled": "True" },
  { "Name": "ServerlessContainers",                         "Enabled": "True" },
  { "Name": "DatabricksSecurityPosture",                    "Enabled": "False" }
]
```

---

## Related Resources

- [Built-in policy: Configure Microsoft Defender CSPM plan](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F72f8cee7-2937-403d-84a1-a4e3e57f3c21) (`72f8cee7-2937-403d-84a1-a4e3e57f3c21`)
- [Microsoft.Security/pricings ARM reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.security/pricings)
- [Microsoft Defender for Cloud — CSPM overview](https://learn.microsoft.com/en-us/azure/defender-for-cloud/concept-cloud-security-posture-management)
- [Azure Policy DeployIfNotExists effect](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effect-deploy-if-not-exists)
