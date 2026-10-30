# Microsoft Defender for APIs - Price Estimation

**Version 1.7**

A self-contained, live workbook following the
[Defender for Storage Price Estimation](../Microsoft%20Defender%20for%20Storage%20Price%20Estimation/README.md)
scope selectors and native data sources. The main page shows **subscription
coverage and compact cost/plan recommendations**. API/service inventory and
diagnostics are optional under **Show details**, which defaults to **Off**.
There are no separate coverage or cost tabs.

All queries and calculations are **embedded in the workbook JSON**. No PowerShell,
build step, uploaded snapshot or custom ingestion is required. Creating or
importing this workbook does not enable a paid plan or onboard APIs.

## Main page and optional details

| Main-page section | Contents |
| --- | --- |
| Subscription coverage | All, several or one subscription: enablement, configured P1-P5 plan, trial status and reported onboarding assessments. |
| Full-rollout cost recommendation | Eligible API count, observed requests, best-fit plan, modeled cost and calculation status for a single resolved APIM service's scope. |
| Current-coverage plan optimization | Onboarded API count, requests, configured/best-fit plans, modeled costs, potential savings and calculation status. |
| Optional subscription log model | Compact subscription-wide cost and plan guidance when an existing workspace and its required logging confirmations are selected. |

Turn **Show details** On for the APIM service overview, individual API eligibility
and usage records, whole-service request grid, pricing reference and diagnostics.
The duplicate **Eligible API totals and protection gaps** grid has been removed.
Selected-service eligible/onboarded counts remain in the cost summaries.

The details option changes presentation only. Required live inventory, onboarding
and request reads still run for cost calculations while details are Off. A failed
required query still blocks the affected estimate and remains visible through the
cost summary's status/error. Hiding detail tables does **not** repair data errors
or convert missing evidence into zero.

Sections requiring a single service or an optional workspace remain conditional
on those selections. If no single service is resolved, the main page explains why
cost recommendations are not yet calculated.

**Enabled** is the subscription setting, not proof that every API is onboarded.
The plan can remain enabled with P1 configured even when no APIM services are
visible. Configuration alone does not establish protected traffic or actual charges.
**In trial** is Yes when reported trial time remains, No for `PT0S`, and Unknown
when trial data is unavailable.

**Assessment records returned** reports the number of onboarding assessments
returned by Resource Graph. If none are returned, assessed API counts are blank
and **Assessment evidence** explicitly reports Unknown, not zero eligible APIs.
When records exist, a zero count means zero matching records in that returned
assessment set; the set still is not proof of complete API inventory.

Costs display as **USD with two decimal places**. Request counts and costs remain
numeric for sorting and export. Empty cost cells mean **not calculated**, not zero.
The optional native metric grid hides the raw **Requests Timeline** array and keeps the
numeric **Requests (Sum)** total. This display change does not change call counts
or cost calculations.
All five plan fees and overages are still compared internally. Main-table exports
contain the compact recommendation fields, not the former five-cost breakdown.
The optional per-API grid retains its detailed record export.

## Workbook files

| File | Use |
| --- | --- |
| [D4ApisDeployment.json](./D4ApisDeployment.json) | Paste-ready workbook JSON with embedded live queries. |
| [armTemplate.json](./armTemplate.json) | ARM template deploying the same saved workbook. |

This directory contains only those two JSON files and this README.

**Current PR preview:** [Download the complete, latest workbook JSON](https://raw.githubusercontent.com/billmcilhargey/Microsoft-Defender-for-Cloud/refs/heads/feat/defender-apis-cost-workbook/Workbooks/Microsoft%20Defender%20for%20APIs%20Cost%20Estimation/D4ApisDeployment.json).
This link follows the APIs PR branch until publication; the relative workbook
link above follows whichever repository revision you are viewing.

## Manual import with the Advanced Editor

1. Open [D4ApisDeployment.json](./D4ApisDeployment.json), select **Raw**, and copy
   the entire JSON.
2. Open **Microsoft Defender for Cloud > Workbooks > New > Advanced Editor (</>)**,
   or **Edit > Advanced Editor** on an existing workbook.
3. Choose **Workbook Template** (**Gallery Template** in some portal versions),
   replace the contents, then select **Apply > Done Editing > Save**.
4. Choose **All subscriptions**, several subscriptions, or one subscription.
   The coverage table works without an APIM selection.
5. Choose **All APIM services** (the default), several services, or one service.
   Subscription coverage remains on the main page; **Show details > On** also
   displays the matching service overview.
6. For metric-based recommendations, clear All and select **one service**. Its
   subscription is derived automatically. The main page shows compact rollout and
   current-plan summaries.
7. Leave **Show details > Off** for the clean overview. Turn it **On** only when
   investigating individual APIs, traffic or missing-data diagnostics.

**No conversion or extraction is required.** Paste the standalone workbook JSON,
not [armTemplate.json](./armTemplate.json). Use **Refresh** to rerun live queries.
Importing JSON does not rename an existing saved workbook; update its name
separately.

## Deploy to Azure

1. Open **Deploy a custom template > Build your own template in the editor**.
2. Load [armTemplate.json](./armTemplate.json) and select **Save**.
3. Choose a subscription, resource group and region.
4. Keep `workbookSourceId` as `azure security center`, then select
   **Review + create > Create**.
5. Open the saved workbook under **Microsoft Defender for Cloud > Workbooks**.

Only a `Microsoft.Insights/workbooks` resource is deployed. Reuse an existing
workbook's GUID as `workbookId` when updating; the default `newGuid()` otherwise
creates another workbook.

**Permissions:** read access to selected subscriptions, APIM services/APIs,
metrics, registered gateways (`Microsoft.ApiManagement/service/gateways/read`),
Defender pricing and API collections. Optional log queries require
Log Analytics query access. Saving/deploying also requires workbook-write
permission on the destination resource group. No plan-write or API-onboarding
permission is needed.

## Live querying and scope

Like the Storage workbook, this workbook uses **Azure Resource Graph** for
coverage and a native **Azure Monitor Metrics** control for request usage.
**All subscriptions** is the default coverage scope and includes only subscriptions
you can access. You can also select a subset. Resource Graph's indexed pricing,
trial and assessment data can lag direct ARM configuration.
**All APIM services** is also a default option. It applies within the selected
subscriptions, not outside that scope. With **Show details** On, a live service overview shows the matching
services, tiers, regions and reported API onboarding assessments. It is not a
complete child-API inventory.
The embedded queries also use:

- **ARM GET/GETARRAY** for the actual API inventory, APIM tier/regions, configured
  subscription plan, onboarded collections and registered gateways.
  `GETARRAY` follows list pagination.
- **Azure Monitor Metrics REST** for per-API `Requests`, `Total`, `interval=FULL`
  over the same last-30-day window. These feed eligibility-aware calculations;
  the optional native metric grid shows whole-service requests, which can include
  self-hosted traffic and are not a protected-traffic billing meter.
- **Optional existing Log Analytics gateway logs** for a subscription-wide model
  across multiple APIM services.

APIM differs from Storage: its API child inventory is not indexed in Resource
Graph, and APIM metrics cannot use Storage's multi-resource selection pattern.
The coverage table evaluates all selected subscriptions. The service overview
follows the APIM selection; subscription coverage still describes entire
subscriptions rather than a selected APIM subset.

API details and cost models evaluate **one APIM service and its subscription at a
time**. A hidden resource picker resolves only an exactly-one-service scope;
All/several selections with multiple matching services leave detail queries
deferred. An All scope containing only one service can safely resolve that service.
An independent readiness check also verifies that the resolved resource matches
that sole service and its derived subscription, so a stale picker value cannot
start detail requests. Gates use the supported singular `conditionalVisibility`
property. The log section has a combined single-service/workspace readiness gate.
The detail subscription is derived from the selected APIM resource, not from the All marker
or a list of subscriptions. No All marker, unresolved first-resource marker or
resource list is passed to the per-service ARM/Metrics calls.
The automatic detail subscription is optional in All/multiple-service mode:
an unset value is expected there and is not a required user input.
Its API counts are selected-service counts, not a multi-service fleet total.
Reported assessment counts are labeled separately because they can lag or omit
APIs; they are not a replacement for full inventory.

### Cost recommendations

Selecting All APIM services provides subscription coverage and an optional service
overview under Show details; it does **not**
enumerate every child API, sum per-service traffic, or generate a fleet-wide
recommendation. Select one service for the detail view. Selecting All
subscriptions does **not** aggregate cost estimates across subscriptions. The
optional log comparison also stays within the selected APIM's subscription.

The metric-based comparison is a subscription recommendation only when the
selected APIM is the subscription's **sole APIM service**. It compares:

1. **All eligible APIs**: least-cost plan for a prospective full rollout.
2. **Currently onboarded APIs**: configured plan versus least-cost plan for today's
   onboarded set, modeled over the full 30 days, including potential monthly savings.

All P1-P5 fees **plus overages** are compared. An existing plan tied for minimum
modeled cost is retained. For example, two million calls favor P1 at USD 400,
even though they exceed its one-million-call allowance; P2 would cost USD 700.

Metric-based guidance requires a successful registered-gateway inventory with
no self-hosted gateways. Self-hosted gateways emit Requests to Azure Monitor by
default, and that metric has no gateway-type dimension. If such gateways exist
or their inventory is unknown, the workbook withholds metric-based guidance
rather than treating all traffic as managed. The native whole-service metric
grid remains diagnostic only.
This is a current-configuration model; it does not reconstruct historical gateway
changes during the 30-day window.

For subscriptions with multiple APIM services, these metric-based recommendations
are withheld rather than treating one instance as the subscription total.
In the **Cost estimation** section, select one service to identify the subscription, then
optionally select an existing Log Analytics workspace for the full subscription:

- Requires **Analytics-plan** `ApiManagementGatewayLogs` or legacy
  `AzureDiagnostics` `GatewayLogs`, not Basic/Auxiliary tables.
- Confirm complete, unsampled, managed-gateway-only logging with no relevant
  exclusions or transformations for the full 30 days. This is a declared
  assumption, not an automatic logging audit.
- Missing onboarded API records withhold current-scope guidance. Overlapping
  legacy/resource-specific schemas are blocked; select one schema if necessary.
- Full-rollout log modeling also requires confirmation that **every API** across
  the subscription is eligible and every service is represented. Otherwise that
  rollout estimate remains withheld.

The workbook does not enable diagnostic settings, change retention or ingest logs.

## Pricing and limitations

- Embedded **USD public reference pricing**, verified **2026-10-29**: P1-P5
  monthly fees are 200, 700, 5,000, 7,000 and 50,000; included calls are 1M, 5M,
  50M, 100M and 1B. Overage rates per call are 0.00020, 0.00014, 0.00010,
  0.00007 and 0.00005. Verify [current pricing](https://azure.microsoft.com/pricing/details/defender-for-cloud/)
  and your agreement before acting.
- The supported scope is managed-gateway REST API collections on documented
  classic Developer, Basic, Standard and Premium tiers in supported commercial
  regions. Consumption and unsupported API types are excluded. Unverified
  tiers/regions require review. Workspace APIs and self-hosted traffic are outside
  this scope. Revisions share one logical API collection.
- Grids display at most **1,000 rows**. Resource Graph calculations expand at most
  **2,000 raw rows per array**; exceeding the required API, collection or metric
  limit withholds recommendations. Observed inventory counts can be lower bounds;
  unmatched APIs in an incomplete onboarding inventory remain **Unknown**. Do not
  infer protection-gap totals from truncated membership.
  At large subscription scopes, a truncated coverage grid is not a tenant-wide
  total; narrow the subscription selection.
- Split API traffic must reconcile to whole-service totals. Missing/null samples,
  read failures, unknown plans, pending onboarding and incomplete required scope
  mean **not calculated**, never zero. Explicit numeric zero samples are valid.
- API identifiers are URI-decoded before revision suffix removal in inventory,
  onboarded collections, metric series and log joins. Encoded revision traffic
  contributes to its logical API instead of being silently dropped.
- This is a current-configuration planning model, not an invoice or a detection
  health attestation. Historical onboarding/deletions, recent APIs, calendar-month
  entitlements, hourly fees, trials, agreements, credits and seasonality can differ.
  Recent traffic is not extrapolated to invent a month.

## Maintaining the workbook JSON

Edit queries and formatting **directly in the standalone workbook JSON** or the
portal Advanced Editor. Keep it identical to the JSON parsed from
`resources[0].properties.serializedData` in [armTemplate.json](./armTemplate.json).
Update both files together; no separate query folder, build script or runtime
dependency is needed.
Optional empty GET body/header/transform metadata and unused empty formatting
properties are omitted. This preserves GET behavior and avoids the repository's
pinned legacy ARM-TTK incorrectly flagging blank metadata inside serialized
workbook JSON. The ARM deployment still contains the identical plain workbook
JSON; it does not hide it in an encoded or concatenated expression.
Cost summaries use one matching currency-column rule instead of repeated
per-column formatting. The native summaries contain one row each, and the log
summary at most two rows, so they do not need per-table search filters.

Local schema, KQL-parser and calculation checks do not replace a live Azure
portal import or verification of actual telemetry in an approved environment.
No added test files are shipped with this sample; regression fixtures used for
validation stay outside the repository.

## Troubleshooting

### Coverage query errors in an older saved workbook

If the page still has **Defender for APIs coverage / Cost estimation** tabs, or the
query title is **Current subscription settings and reported onboarding coverage**,
it is an earlier workbook revision, not the current one-page summary layout.
The early coverage query depended on ARM parameter values. The current coverage
query uses Resource Graph directly and does not require an APIM selection or ARM
parameter values.

Replace the saved workbook's entire template:

1. Download the [complete current PR workbook JSON](https://raw.githubusercontent.com/billmcilhargey/Microsoft-Defender-for-Cloud/refs/heads/feat/defender-apis-cost-workbook/Workbooks/Microsoft%20Defender%20for%20APIs%20Cost%20Estimation/D4ApisDeployment.json).
   Copy **all** of it, including the final closing braces. In an editor, use
   **Ctrl+A**, not an old partial selection.
2. In the portal, choose **Edit > Advanced Editor > Workbook Template**
   (**Gallery Template** in some versions). Select all existing contents and
   replace them; do not append the new JSON or paste the ARM deployment template.
3. Select **Apply > Done Editing**. Confirm that the header says **Version 1.7**,
   that **Show details** defaults to **Off**, and that there are **no coverage/cost
   tabs**, then **Save**.
4. If the editor rejects the JSON, the old workbook remains active. Check for an
   incomplete copy and repeat with the full downloaded file.

The current coverage query was executed successfully against Azure Resource Graph
on 2026-10-29 and returned subscription rows with the expected columns in an
accessible validation scope. That is not verification of a different tenant's
permissions, APIM metrics, or the saved portal copy.

If the error persists in the confirmed current revision, capture the complete
expanded error details and the rendered Resource Graph query. A timestamp and
correlation ID alone do not identify the query failure; also verify read access
to the selected subscriptions. Do not convert a failed query into zero coverage.

### Requests Timeline displays a raw array

If **Requests Timeline** displays an array such as `[8,30,17,...]`, the timeline
column is using a plain-cell renderer instead of being hidden. This is a grid
formatting issue, not a Defender finding or a request-total error.
The workbook hides the native metric-ID timeline column and its display-name
alias with formatter `5`, matching the Storage workbook's existing pattern.
Reimport the updated [workbook JSON](./D4ApisDeployment.json), or redeploy
[armTemplate.json](./armTemplate.json), to update an older saved copy.

## Optional PowerShell estimation at scale

The [PowerShell estimator](../../Powershell%20scripts/Defender%20APIs%20Cost%20Estimator/d4apis_cost_estimator_v1.ps1)
and its [README](../../Powershell%20scripts/Defender%20APIs%20Cost%20Estimator/readme.md)
are independent CSV/JSON reporting tools. The workbook never calls the script,
ingests its output or requires it for refresh.

## Version history

- **1.7** - Corrected review findings: supported coverage-query joins, Unknown
  missing assessments/onboarding membership, singular readiness gates, optional
  automatic scope, URI-decoded revision joins and managed-gateway metric guards.
  Removed added test files and corrected validation/documentation issues.
- **1.6** - Simplified the main page to coverage and compact cost/plan summaries.
  Added opt-in service/API/diagnostic details and removed the duplicate API totals
  grid. Data reads, five-plan calculations and missing-data safeguards are retained.
- **1.5** - Combined coverage, API inventory and cost sections onto one page;
  removed tab dependencies and hid the raw Requests Timeline array without
  changing usage or pricing queries.
- **1.4** - All/multi-APIM selection and live service overview, with full
  inventory/metrics deferred unless the scope resolves to exactly one service.
- **1.3** - All/multi-subscription coverage and APIM discovery; derive the detail
  subscription from the selected service and defer its ARM queries until selected.
- **1.2** - Storage-style coverage/cost layout, native metric grid, API coverage
  totals, embedded queries and two-file JSON delivery with README.
- **1.1** - Native live Azure queries, eligibility-aware plan comparison and optional
  multi-APIM log model.

## References

- [Workbook native data sources and pagination](https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-data-sources)
- [Defender for APIs support](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-apis-prepare)
- [Thirty-day sizing and billing guidance](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-apis-deploy)
- [APIM metric reference](https://learn.microsoft.com/azure/azure-monitor/reference/supported-metrics/microsoft-apimanagement-service-metrics)
- [Self-hosted gateway metrics and logs](https://learn.microsoft.com/azure/api-management/how-to-configure-cloud-metrics-logs)
