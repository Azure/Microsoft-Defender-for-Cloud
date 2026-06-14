# Microsoft Defender for Cloud - Azure Assets Discovery

## Description
This PowerShell script scans an Azure tenant and exports a CSV containing the
**raw billable units** for every subscription, ready to be used as a reference
when filling in the **Microsoft Defender for Cloud Cost Estimator** (part of
the MDC Next-Gen experience in Microsoft Sentinel).

The cost estimator does **not** auto-import this file — use the CSV as a
lookup while typing the values into the calculator manually.

The script does **not** perform any pricing calculation. It only collects the
inventory and usage metrics that the calculator needs in order to estimate
Defender for Cloud costs (per-plan).

### What it collects (one row per subscription)

The output CSV contains the following columns:

| Column | Description |
|---|---|
| `SubscriptionID` | Subscription GUID |
| `SubscriptionName` | Subscription display name |
| `EnvironmentType` | Always `Azure` |
| `Servers` | **The value to use for the Servers plan.** VM count with AKS node-pool VMs already removed, because when both **Servers** and **Containers** plans are enabled those node VMs are billed under Containers — excluding them here prevents double-counting. |
| `Servers_All` | **Reference only.** Total VM count *including* AKS node-pool VMs. Use this column instead of `Servers` if you do **not** plan to enable the Containers plan, so AKS nodes still get protected (and counted) under Servers. |
| `Containers` | AKS node count — point-in-time from ARG, replaced by the 30-day average of `kube_node_status_condition` (Ready) when extended collection is enabled |
| `AppServices` | Sum of workers from `microsoft.web/serverfarms` (Consumption-tier plans are excluded) |
| `KeyVaults` | Count of Key Vaults |
| `ARM` | Always `1` per subscription |
| `StorageAccounts` | Count of storage accounts |
| `Databases` | Sum of SQL servers, SQL VMs (incl. Arc), and non-Basic OSS DBs (PostgreSQL / MySQL, single & flexible) |
| `DCSPM_Servers` | VMs + VMSS (counted via `cloudposture_servers`) |
| `DCSPM_Storage` | Storage accounts |
| `DCSPM_Databases` | SQL servers + non-Basic OSS DBs + CosmosDB accounts |
| `DCSPM_Serverless` | Eligible `microsoft.web/sites` (App + Function apps, all supported kinds) |
| `API_Requests` | Sum of APIM `Requests` metric across all APIM services (last 30 days) |
| `CosmosDB_RUs` | Equivalent RU/s — provisioned databases/containers (incl. autoscale avg-hourly-max, multiplied by replica region count) + serverless (Total RU × 0.00003125) |
| `MalwareScanning_GB` | Storage account blob `Ingress` (last 30 days), summed across accounts in the subscription, in GB |
| `AI_Tokens` | Sum of `TokenTransaction` across OpenAI / AIServices Cognitive Services accounts (last 30 days) |
| `ContainerRegistry_Images` | Sum of `manifestCount` across all repositories in every Container Registry (only populated if you opt in to ACR collection) |

Output file: `AzureRawBillableData_<yyyyMMdd_HHmmss>.csv` (written to the current directory).

## Prerequisites
- **PowerShell 7.0+**
- **Az PowerShell modules** (only the submodules used by the script are required):
  ```powershell
  Install-Module -Name Az.Accounts, Az.ResourceGraph, Az.Monitor -Scope CurrentUser -Force
  ```
- **Azure CLI** (only required if you opt in to Container Registry image collection): https://aka.ms/installazurecli
- Permissions:
  - `Reader` on every subscription you want to scan
  - `AcrPull` (or higher: `AcrPush`, `Contributor`, `Owner`) on each Container Registry — only if you opt in to ACR collection

The script verifies these prerequisites on start-up and exits early if any required Az submodule is missing. A missing Azure CLI only logs a warning; ACR collection is then skipped automatically.

## Usage
```powershell
# 1. Sign in
Connect-AzAccount

# 2. Run the script
.\AzureAssetsDiscovery.ps1
```

You will be asked two questions up-front, then the script runs unattended:

1. **Run extended (consumption-based) data collection?** Adds metrics-based AKS node averages, APIM requests, CosmosDB RU/s, Malware Scanning ingress GB, AI tokens, and (optionally) Container Registry image counts. Can take a while on large tenants.
2. **Include Container Registry images?** Only asked if you said yes to (1) and the Azure CLI is installed. Requires `AcrPull` on each registry.

The script writes `AzureRawBillableData_<timestamp>.csv` to the current working directory.

## Using the CSV with the Sentinel Cost Estimator

The MDC Cost Estimator does not auto-import this file. Open the CSV side-by-side
with the calculator and **type the per-plan values** from each subscription row
into the matching fields in the UI.

## Notes

- All consumption metrics use a **30-day lookback window**.
- **`Servers` vs `Servers_All`:** The default assumption is that both the **Servers**
  and **Containers** plans will be enabled, so AKS node-pool VMs are excluded from
  the `Servers` column (they're billed under Containers — counting them in both
  would double-bill). `Servers_All` is the unfiltered total VM count and is
  provided for the case where the Containers plan will **not** be enabled — in
  that scenario use `Servers_All` so AKS nodes are still covered (and counted)
  under the Servers plan. AKS nodes are detected via the `Microsoft.AKS` extension
  publisher on VMSS.
- Container node counts start as a point-in-time ARG value and are replaced by the
  30-day average of the `kube_node_status_condition` Ready metric when extended
  collection is enabled — more accurate for clusters that use the autoscaler.
- CosmosDB RU/s mirrors Defender for Cosmos billing: provisioned offers (per
  database/container) are multiplied by the account's replica region count, and
  serverless RU consumption is converted to equivalent RU/s using Microsoft's
  documented `0.00003125` factor.
- The script issues **read-only** ARG / ARM / Monitor calls; nothing is changed in
  your environment.
- Designed to be safe to interrupt and re-run.
- A timing summary is printed at the end of extended collection so you can spot
  which section is taking the longest in your tenant.

## Author

Nessya123
