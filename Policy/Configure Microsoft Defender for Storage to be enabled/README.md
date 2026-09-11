# Configure Microsoft Defender for Storage to be enabled

## Overview

This custom policy enables **Microsoft Defender for Storage** at subscription scope and exposes the full set of configurable storage Defender settings available through the ARM API.

It extends the built-in policy **Configure Microsoft Defender for Storage to be enabled** by adding the additional extension properties that are not exposed in the built-in version.

---

## Why This Policy Exists

The built-in Storage policy does not expose all configurable Defender for Storage settings. In particular, it does not let you configure:

- `AutomatedResponse`
- `BlobScanResultsOptions`

This custom policy makes those settings available through parameters so they can be controlled consistently across subscriptions via Azure Policy.

---

## Policy Details

| Property | Value |
|---|---|
| **Display Name** | CUSTOM - Configure Microsoft Defender for Storage to be enabled |
| **Category** | Security Center |
| **Mode** | All |
| **Resource Type** | `Microsoft.Resources/subscriptions` |
| **Deployment Target** | `Microsoft.Security/pricings/StorageAccounts` |
| **Deployment Scope** | Subscription |
| **API Version** | `2024-01-01` |
| **Required Role** | Contributor (`b24988ac-6180-42a0-ab88-20f7382dd24c`) |
| **Supported Effects** | `DeployIfNotExists`, `AuditIfNotExists`, `Disabled` |

---

## Parameters

| Parameter Name | Display Name | Allowed Values | Default | Notes |
|---|---|---|---|---|
| `effect` | Effect | `DeployIfNotExists`, `AuditIfNotExists`, `Disabled` | `DeployIfNotExists` | |
| `isOnUploadMalwareScanningEnabled` | On-Upload Malware Scanning Enabled | `True`, `False` | `True` | Also in built-in policy |
| `capGBPerMonthPerStorageAccount` | Cap GB Per Month Per Storage Account | integer | `10` | Minimum `10`, use `-1` for unlimited |
| `automatedResponseOption` | Automated Response Option | `None`, `BlobSoftDelete` | `BlobSoftDelete` | **Not exposed by built-in policy** |
| `blobScanResultsOption` | Blob Scan Results Option | `BlobIndexTags`, `None` | `None` | **Validated against ARM; `StorageAccount` is invalid** |
| `isSensitiveDataDiscoveryEnabled` | Sensitive Data Discovery Enabled | `True`, `False` | `True` | Also in built-in policy |

---

## How It Works

### Compliance Evaluation

The policy evaluates compliance by checking:

1. `Microsoft.Security/pricings/StorageAccounts` exists with `pricingTier = Standard`
2. `subPlan = DefenderForStorageV2`
3. The configured extension values match the desired state

### Remediation

When a subscription is found non-compliant, the policy deploys an ARM template at subscription scope that sets:

- `pricingTier = Standard`
- `subPlan = DefenderForStorageV2`
- `OnUploadMalwareScanning`
- `SensitiveDataDiscovery`

The malware scanning extension includes the configurable additional properties:

- `AutomatedResponse`
- `BlobScanResultsOptions`
- `CapGBPerMonthPerStorageAccount`

### Required RBAC

The policy assignment's managed identity requires the **Contributor** role at the target scope to deploy `Microsoft.Security/pricings` resources into child subscriptions.

---

## Usage Example

### Azure CLI

```bash
az policy assignment create \
  --name "storage-defender-custom" \
  --display-name "CUSTOM - Configure Microsoft Defender for Storage to be enabled" \
  --policy "<policy-definition-id>" \
  --scope "/providers/Microsoft.Management/managementGroups/<mg-id>" \
  --location "eastus" \
  --mi-system-assigned \
  --params '{
    "effect": { "value": "DeployIfNotExists" },
    "isOnUploadMalwareScanningEnabled": { "value": "True" },
    "capGBPerMonthPerStorageAccount": { "value": 10 },
    "automatedResponseOption": { "value": "BlobSoftDelete" },
    "blobScanResultsOption": { "value": "None" },
    "isSensitiveDataDiscoveryEnabled": { "value": "True" }
  }'
```

### Terraform

```hcl
resource "azurerm_management_group_policy_assignment" "storage" {
  name                 = "custom-def-storage"
  display_name         = "CUSTOM - Configure Microsoft Defender for Storage to be enabled"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/<mg-id>"
  policy_definition_id = azurerm_policy_definition.storage.id
  location             = "eastus"

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    effect                           = { value = "DeployIfNotExists" }
    isOnUploadMalwareScanningEnabled = { value = "True" }
    capGBPerMonthPerStorageAccount   = { value = 10 }
    automatedResponseOption          = { value = "BlobSoftDelete" }
    blobScanResultsOption            = { value = "None" }
    isSensitiveDataDiscoveryEnabled  = { value = "True" }
  })
}
```

---

## Verification

After remediation completes, verify the pricing resource:

```bash
az rest --method get \
  --url "https://management.azure.com/subscriptions/<subscription-id>/providers/Microsoft.Security/pricings/StorageAccounts?api-version=2024-01-01" \
  --query "properties.extensions[?name=='OnUploadMalwareScanning'].additionalExtensionProperties"
```

Expected output:

```json
[
  {
    "AutomatedResponse": "BlobSoftDelete",
    "BlobScanResultsOptions": "None",
    "CapGBPerMonthPerStorageAccount": "10"
  }
]
```

---

## Related Resources

- Built-in policy: **Configure Microsoft Defender for Storage to be enabled**
- ARM resource type: `Microsoft.Security/pricings`
- Microsoft Defender for Cloud documentation
- Azure Policy `DeployIfNotExists` effect
