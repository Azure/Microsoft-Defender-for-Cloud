# MDC Cost Estimator - Raw Billable Data Export

## Description
This PowerShell script scans an Azure tenant and exports a CSV containing the
**raw billable units** for every subscription, ready to be imported into the
**Microsoft Defender for Cloud Cost Estimator** (part of the MDC Next-Gen
experience in Microsoft Sentinel).

The script does **not** perform any pricing calculation. It only collects the
inventory and usage metrics that the calculator needs in order to estimate
Defender for Cloud costs (per-plan).

### What it collects (one row per subscription)

| Plan / Category | Metric collected |
|---|---|
| Servers (P1/P2) | Count of VMs (excluding AKS node-pool VMs) |
| Containers | AKS node count (point-in-time + 30-day metrics avg) |
| App Service | Count of `microsoft.web/serverfarms` workers |
| Key Vault | Count of vaults |
| ARM | Always 1 per subscription |
| Storage Accounts | Count of storage accounts |
| Databases | Count of SQL servers, SQL VMs, OSS DBs |
| DCSPM | Broken down by Servers / Storage / Databases / Serverless |
| API | Total APIM requests (last 30 days) |
| CosmosDB | RU/s (provisioned + serverless + autoscale) |
| Malware Scanning | Storage Ingress GB (last 30 days) |
| AI | Token Transactions (last 30 days) |
| Container Registry | Distinct image manifests per registry |

Output file: `AzureRawBillableData_<yyyyMMdd_HHmmss>.csv`

## Prerequisites
- **PowerShell 7.0+**
- **Az PowerShell module**: `Install-Module -Name Az -Scope CurrentUser -Force`
- **Azure CLI** (only required if collecting Container Registry images): https://aka.ms/installazurecli
- Permissions:
  - `Reader` on every subscription you want to scan
  - `AcrPull` (or higher) on each Container Registry, only if you opt in to ACR collection

## Usage
```powershell
# 1. Sign in
Connect-AzAccount

# 2. Run the script
.\AzureRawBillableDataScript.ps1
