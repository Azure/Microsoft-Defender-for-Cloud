# Defender for APIs - coverage and cost estimator

The [PowerShell estimator](./d4apis_cost_estimator_v1.ps1) collects API inventory,
subscription plan configuration and the last **30 days** of request metrics.
It exports standalone CSV/JSON evidence. Metric-based guidance is withheld when
self-hosted gateways are registered or their inventory cannot be read, because
the Requests metric does not distinguish managed from self-hosted traffic.

The [Defender for APIs cost workbook](../../Workbooks/Microsoft%20Defender%20for%20APIs%20Cost%20Estimation/README.md)
now uses **native live Azure queries**. This optional script is **not** a workbook
data source, prerequisite or refresh mechanism.

**Read-only:** it never enables a paid plan, onboards an API or changes a tier.
Original script authors: Giulio Astori and Preetham Anand Naik.

## Review of the original v1

Reviewed against Microsoft documentation and public retail meters on **2026-10-29**.
The historical filename is retained, but its implementation has been updated.

| Original behavior | Assessment |
| --- | --- |
| Sum APIM `Requests` with `Total` aggregation over 30 days, per subscription. | Still Microsoft's documented **rough sizing** method. It is not a measurement of protected API traffic. |
| Apply P1-P5 base fees plus overage, and choose the cheapest total. | The reference fees and overage rates remain consistent with public pricing. Keeping calls within an allowance is not necessarily the cheapest option. |
| Include all APIM traffic without API eligibility or onboarding checks. | Can overstate rollout costs and cannot describe protection coverage or current-scope cost. |
| Skip failed metrics and continue recommending a plan. | Can understate traffic and produce a false cheapest-plan recommendation. Missing data must not be zero. |
| Do not read the configured subscription plan. | Cannot determine whether Defender for APIs is enabled or whether the existing plan fits observed traffic. |
| Treat a rolling 30-day estimate as a monthly price. | Useful for modeling, but calendar-month entitlements, hourly subscription fees, trials and configuration changes affect actual billing. |

The updated collector separates two scenarios:

1. **All eligible APIs**: least-cost plan for a prospective full rollout.
2. **Currently onboarded APIs**: compare the configured plan against the least-cost
   plan for today's onboarded set, modeled over the full 30-day window.

It does **not** reconstruct which APIs were protected on each historical day.
“Best fit for modeled traffic” is not a claim that the actual invoice is optimized.

## Run

Requires **PowerShell 7.2+**, **Az.Accounts**, and a complete repository checkout.
The companion [module](./DefenderForApisCostEstimator.psm1) and
[pricing file](./pricing.json) are required; downloading
only the historical script is no longer sufficient.

```powershell
Install-Module Az.Accounts -Scope CurrentUser
Connect-AzAccount

.\d4apis_cost_estimator_v1.ps1 `
    -SubscriptionId '00000000-0000-0000-0000-000000000000' `
    -OutputDirectory .\ApiEstimate
```

Omit `-SubscriptionId` to enumerate accessible enabled subscriptions. A signed-in
context is reused; otherwise the collector signs in interactively. The original
context is restored afterward. Only **Azure commercial cloud** is supported.

**Compatibility changes:** the default output folder is now
`.\DefenderForApisEstimate`, not the current directory. The CSV name
`AllSubscriptionsPlanRecommendation.csv` remains, but `TotalRequests` now means
traffic for **eligible API collections**, not every request to every APIM service.
Keep existing automation on the old CSV contract only after adapting it to these
scope and data-quality changes.

## Permissions

Read access is required across each selected subscription:

- `Microsoft.ApiManagement/service/read` and `Microsoft.ApiManagement/service/apis/read`
- `Microsoft.ApiManagement/service/gateways/read`
- `Microsoft.Insights/metrics/read`
- `Microsoft.Security/pricings/read`
- `Microsoft.Security/apiCollections/read`

Subscription **Reader** is a useful starting point; verify effective permissions
and deny assignments in your environment. No Contributor, plan-write or API
onboarding permission is required for collection. Saving a workbook separately
requires workbook-write permission on its destination resource group.

## Outputs

| File in the output directory | Contents |
| --- | --- |
| `AllSubscriptionsPlanRecommendation.csv` | Subscription coverage, rollout recommendation, configured-plan fit and modeled savings. |
| `DefenderForApis-ApiInventory.csv` | API collection eligibility, onboarding, protection configuration and observed calls. |
| `DefenderForApis-ServiceInventory.csv` | APIM inventory completeness and whole-service traffic. |
| `DefenderForApis-PlanComparisons.csv` | Five base-fee/overage comparisons for every complete scenario. |
| `DefenderForApis-Issues.csv` | Failed reads, missing telemetry and eligibility requiring review. |
| `DefenderForApisReport.json` | Complete snapshot, pricing reference, UTC window and quality evidence. |

The script does not generate or populate a workbook. Its own reports are
snapshots; rerun it to refresh those CSV/JSON files.
The outputs contain resource inventory: restrict access
appropriately and do not commit collected customer data to this repository.

CSV exports prefix formula-leading text with an apostrophe, including formulas
after whitespace or control characters and full-width formula prefixes. Numeric
fields are unchanged. The JSON snapshot retains original text for unmodified
evidence; CSV text may therefore differ from the JSON.

Errors are recorded and affected recommendations are withheld. After exporting
partial evidence, the script throws if collection errors occurred. Warnings such
as missing traffic are visible in the reports and do not become zero estimates.

## Eligibility, traffic and limitations

- The documented scope is managed-gateway **REST APIs** on classic APIM
  **Developer, Basic, Standard and Premium** tiers in supported commercial regions.
  Consumption and non-REST API types are excluded. Unverified tiers, including v2
  tiers, or unlisted primary/secondary regions require review rather than being
  assumed supported.
- Inventory lists logical API collections under APIM services. Workspace APIs and
  self-hosted gateway traffic are outside this supported scope. An API can also be
  exposed elsewhere; the workbook does not attest protection for that traffic.
- API revisions are grouped at the API collection level for onboarding. Revision
  dimension values are normalized into one logical API without counting an API
  multiple times. This is not an inventory of individual revision endpoints.
- Calls use `Requests`, `Total`, `interval=FULL`, with the same UTC window for all
  resources. `ApiId` split totals must reconcile to whole-service totals. A
  10,000-series ceiling is explicitly treated as truncation.
- Before reading traffic for estimation, the collector reads the complete
  registered-gateway inventory. Any registered self-hosted gateway makes the
  managed traffic scope unverified and withholds metric-based recommendations.
  An unreadable gateway inventory is an error, never an empty inventory.
  The model assumes current gateway configuration across the window; historical
  gateway changes require separate verification.
- No matching series, null samples, failed requests and incomplete inventory are
  **unknown**, never zero. Only explicit numeric zero samples permit a zero-call
  model. An idle API may therefore require investigation before a recommendation
  is available.
- The current-scope model requires successful onboarding inventory, a recognized
  subplan and complete telemetry for its onboarded APIs. Full-rollout estimates
  additionally need complete usage for all eligible APIs. Missing usage on an unprotected
  API does not invalidate an otherwise complete current-scope estimate.
- Onboarded and unprotected-eligible counts are unknown (null) when onboarding
  evidence is incomplete, including missing or unverified provisioning states.
  Complete request data can still support a prospective full-rollout model.
- Deleted APIs' historical traffic is not assigned to today's API inventory.
  APIs created recently may have less than 30 days of history; traffic is not
  extrapolated to invent a full month. Metric availability does not prove that
  telemetry was uninterrupted.
- Discovered and eligibility counts from an incomplete inventory are lower bounds.
  The JSON and CSV exports retain the collected results.

## Pricing

The [versioned pricing reference](./pricing.json) contains:

| Plan | Monthly reference fee (USD) | Included calls | Overage per call (USD) |
| --- | ---: | ---: | ---: |
| P1 | 200 | 1,000,000 | 0.00020 |
| P2 | 700 | 5,000,000 | 0.00014 |
| P3 | 5,000 | 50,000,000 | 0.00010 |
| P4 | 7,000 | 100,000,000 | 0.00007 |
| P5 | 50,000 | 1,000,000,000 | 0.00005 |

For each subscription and scenario:

```text
modeled cost = monthly reference fee
             + max(0, observed calls - included calls) * overage per call
```

For example, two million calls cost **USD 400 on P1**, less than P2's USD 700 even
though they exceed P1's allowance. Existing plans tied for minimum modeled cost
are retained; the collector does not recommend switching for zero savings.

Monthly reference fees approximate 730-hour public rates. Actual fixed charges
use hourly meters and call entitlements reset by billing month. Taxes,
negotiated discounts, credits and trials are not modeled.

Use `-PricingPath` with a reviewed copy of the complete pricing JSON to model
another agreement or currency. There is no live pricing lookup or automatic
currency conversion during collection; the snapshot records the reference date.
Invalid pricing is rejected, not silently replaced.

## Validation

From this directory, use PSScriptAnalyzer with all severities:

```powershell
Invoke-ScriptAnalyzer -Path . -Recurse -Severity Information,Warning,Error
```

This sample does not bundle test files. Validation can use temporary synthetic
fixtures outside the repository for pricing ties, gateway scope, pagination,
revision normalization and missing-data behavior. Do not commit customer exports
or credentials as validation data.

## References

- [Microsoft's 30-day APIM traffic sizing guidance and billing scope](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-apis-deploy)
- [Supported tiers, API types, gateways and regions](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-apis-prepare)
- [API revisions and APIM multi-resource metrics limitation](https://learn.microsoft.com/azure/defender-for-cloud/faq-defender-for-apis)
- [APIM Requests metric and ApiId dimension](https://learn.microsoft.com/azure/azure-monitor/reference/supported-metrics/microsoft-apimanagement-service-metrics)
- [Self-hosted gateways emit Azure Monitor Requests by default](https://learn.microsoft.com/azure/api-management/how-to-configure-cloud-metrics-logs)
- [Metrics REST API: FULL interval and default top-10 split limit](https://learn.microsoft.com/rest/api/monitor/metrics/list)
- [Onboarded API collections REST API](https://learn.microsoft.com/rest/api/defenderforcloud/api-collections/list-by-subscription)
- [Defender for Cloud pricing](https://azure.microsoft.com/pricing/details/defender-for-cloud/)
- [Public retail price API](https://prices.azure.com/api/retail/prices?$filter=productName%20eq%20%27Defender%20for%20APIs%27)
