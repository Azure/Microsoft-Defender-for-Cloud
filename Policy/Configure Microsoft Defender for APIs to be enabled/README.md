# Configure Microsoft Defender for APIs to be enabled

## Overview

This custom policy enables **Microsoft Defender for APIs** at subscription scope and exposes the pricing plan required by the ARM API.

It extends the built-in policy **Microsoft Defender for APIs should be enabled** by adding `subPlan` support so the API pricing resource can be configured at scale.

---

## Why This Policy Exists

Defender for APIs requires more than just enabling the built-in policy. The live `Microsoft.Security/pricings/Api` resource must be created with:

- `pricingTier = Standard`
- `subPlan = P1` (or `P2`/`P3`/`P4`/`P5`)

The built-in policy does not expose the pricing plan, so this custom policy makes it configurable.

---

## Policy Details

| Property | Value |
|---|---|
| **Display Name** | CUSTOM - Configure Microsoft Defender for APIs to be enabled |
| **Category** | Security Center |
| **Mode** | All |
| **Resource Type** | `Microsoft.Resources/subscriptions` |
| **Deployment Target** | `Microsoft.Security/pricings/Api` |
| **Deployment Scope** | Subscription |
| **API Version** | `2024-01-01` |
| **Required Role** | Contributor (`b24988ac-6180-42a0-ab88-20f7382dd24c`) |
| **Supported Effects** | `DeployIfNotExists`, `Disabled` |

---

## Parameters

| Parameter Name | Display Name | Allowed Values | Default | Notes |
|---|---|---|---|---|
| `effect` | Effect | `DeployIfNotExists`, `Disabled` | `DeployIfNotExists` | |
| `subPlan` | API pricing plan | `P1`, `P2`, `P3`, `P4`, `P5` | `P1` | Required to enable Defender for APIs |

---

## How It Works

### Compliance Evaluation

The policy evaluates compliance by checking:

1. `Microsoft.Security/pricings/Api` exists
2. `pricingTier = Standard`
3. `subPlan` matches the configured parameter

### Remediation

When a subscription is found non-compliant, the policy deploys an ARM template at subscription scope that sets:

- `pricingTier = Standard`
- `subPlan = <selected plan>`

### Required RBAC

The policy assignment's managed identity requires the **Contributor** role at the target scope to deploy `Microsoft.Security/pricings` resources into child subscriptions.

---

## Usage Example

### Azure CLI

```bash
az policy assignment create \
  --name "api-defender-custom" \
  --display-name "CUSTOM - Configure Microsoft Defender for APIs to be enabled" \
  --policy "<policy-definition-id>" \
  --scope "/providers/Microsoft.Management/managementGroups/<mg-id>" \
  --location "eastus" \
  --mi-system-assigned \
  --params '{
    "effect": { "value": "DeployIfNotExists" },
    "subPlan": { "value": "P1" }
  }'
```

### Terraform

```hcl
resource "azurerm_management_group_policy_assignment" "api" {
  name                 = "custom-def-api"
  display_name         = "CUSTOM - Configure Microsoft Defender for APIs to be enabled"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/<mg-id>"
  policy_definition_id = azurerm_policy_definition.api.id
  location             = "eastus"

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    effect  = { value = "DeployIfNotExists" }
    subPlan = { value = "P1" }
  })
}
```

---

## Verification

After remediation completes, verify the pricing resource:

```bash
az rest --method get \
  --url "https://management.azure.com/subscriptions/<subscription-id>/providers/Microsoft.Security/pricings/Api?api-version=2024-01-01"
```

Expected output:

```json
{
  "name": "Api",
  "properties": {
    "pricingTier": "Standard",
    "subPlan": "P1"
  }
}
```

---

## Related Resources

- Built-in policy: **Microsoft Defender for APIs should be enabled**
- ARM resource type: `Microsoft.Security/pricings`
- Microsoft Defender for Cloud documentation
- Azure Policy `DeployIfNotExists` effect
