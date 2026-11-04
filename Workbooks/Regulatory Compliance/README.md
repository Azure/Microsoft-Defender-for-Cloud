# Microsoft Defender for Cloud - Regulatory Compliance
**Original author:** [Vanessa Bruwer](https://github.com/vanessabruwer) | [FastTrack for Azure](https://aka.ms/fasttrackforazure)

This workbook displays current Microsoft Defender for Cloud regulatory compliance results across selected subscriptions using Azure Resource Graph. It provides subscription-first compliance reporting, resource posture by workload, and control-level detail.

## Contributors

- [Dr Bill Mcilhargey](https://github.com/billmcilhargey)
- [Lior Arviv](https://github.com/liorarviv)

Additional human contributors from this workbook folder's Git history, including this change set; the original author is credited above. Automated accounts and merge-only credits are excluded. Names use each verified GitHub profile's display name, or its username when no display name is set.

## Views and filters

The **Subscription** selector scopes every tab. **Compliance standard** applies to Overview, Workloads, and Compliance Detail, but not to export configuration or delivery evidence. The single-select standard selector defaults to **All**.
**Compliance Detail scope** optionally selects one subscription and standard for Compliance Detail only; it is still subject to the other filters. Exported snapshots have their own **History standard** selector so standards present only in history remain available.

### Overview

- Coverage cards show reporting versus selected subscriptions, assessed subscription-standard pairs, and subscription-standard pairs with failed controls. Repeated standards in different subscriptions are separate results.
- The coverage panel fits its tile content instead of reserving a fixed chart height. Page and result-grid scrolling use the portal's native scroll regions; close an open filter popup before scrolling the workbook.
- The control-outcomes chart adds the four standard-reported counts across subscription-standard results. It excludes rows with missing or negative counts and is not a compliance score or a count of unique controls: standards and subscriptions can overlap. Other control states are available in Compliance Detail.
- Select **Failed**, **Passed**, **Skipped**, or **Unsupported** in the chart to filter the table to subscription-standard rows with a positive count for that outcome. A selected outcome requires the same complete, nonnegative four-count guard as the chart. **All** retains incomplete rows; the chart and coverage cards keep their full current scope.
- The visible **Active table outcome filter** text shows the table's current state. Focus a chart legend item and press **Enter** to select or deselect it; selecting it again restores **All**. Space may not activate the legend.
  **Clear outcome filter (show all)** is also available when the chart is empty and changes only this filter. A legend highlight can remain after this parameter-only clear; deselect it before selecting it again.
- Expand a subscription to compare its standards. Subscriptions with failing standards are sorted first.
- Counts remain numeric. Pass percentage is calculated separately for each standard as `100 * passed / (passed + failed)`, excluding skipped and unsupported controls. A zero denominator is shown as **N/A**; overlapping standards are not averaged into a subscription compliance score.
- Subscription status is the worst child result: failed takes precedence, incomplete/unassessed results remain neutral, and passed requires all four counts to be present and nonnegative. **All** keeps incomplete rows visible without marking them passed.
- Status values stay numeric for roll-up; their formatter thresholds are serialized as strings for compatibility with the current portal renderer.
- Choose a subscription and standard in **Compliance Detail scope**, then choose **Open selected standard in Compliance Detail** below the table. The current scope is displayed there and can be cleared. Expanding a subscription does not select a scope or navigate away from Overview.
- The detail scope is separate from the global standard filter consumed by the Overview query and persists until cleared or changed. The main filters remain unchanged.

### Workloads

Workload is an operational resource family, not a business application or a tag-based grouping. Use the workload overview, choose one **Detail subscription**, then select a resource to load its recommendations.
Azure resources are grouped by their canonical, case-insensitive ID. The reported resource ID remains available in resource detail and export; native cloud identities retain case.

The **Workload** selector uses checkboxes. **All** is selected by default; select one or several workloads to apply the same workload scope to both the summary and resource findings.

| Workload | Provider-qualified resource types |
| --- | --- |
| Compute | `Microsoft.Compute/*`, `Microsoft.HybridCompute/*` |
| Containers | `Microsoft.ContainerService/*`, `Microsoft.ContainerRegistry/*`, `Microsoft.Kubernetes/*`, `Microsoft.App/containerApps*`, `Microsoft.App/managedEnvironments*` |
| Databases | `Microsoft.Sql/*`, `Microsoft.SqlVirtualMachine/*`, `Microsoft.DBforPostgreSQL/*`, `Microsoft.DBforMySQL/*`, `Microsoft.DBforMariaDB/*`, `Microsoft.DocumentDB/*`, `Microsoft.Cache/*` |
| Storage | `Microsoft.Storage/*` |
| Key Vault | `Microsoft.KeyVault/*` |
| Networking | `Microsoft.Network/*` |
| App Services | `Microsoft.Web/*` |
| Subscription-level | The subscription resource itself |
| Other/unmapped | Other types, missing resource identities/assessments, and native cloud types without a recognized workload mapping |

Classification uses the provider-qualified type derived from Azure resource IDs, including nested resource types, rather than a leaf name such as `vaults`. Recovery Services vaults therefore do not become Key Vault resources. Native AWS/GCP resource identities are retained; unsupported native type mappings remain visible in Other/unmapped.

The queries join regulatory compliance assessments to resource assessments on **subscription ID and assessment key**.
Control/standard mappings are collapsed before joining, and findings are deduplicated by **subscription, cloud-aware resource identity, and assessment key** afterward.
Azure identities are case-normalized; native cloud identities retain case.
AWS and GCP connector identities use the reported `resourceDetails.Id` when `ConnectorId` and `Id` are present.
Otherwise, they use the legacy `AwsResourceId` and `GcpResourceId` fields respectively.
The summary, resource counts, search, resource list and exact-resource recommendations share this identity rule.
Multiple controls referencing one recommendation do not inflate resource or finding counts.

The summary always includes all assessment states within the selected subscription, standard, and workload scope:

- **Assessed resources:** identifiable resources with at least one Healthy or Unhealthy assessment.
- **Resources with failures:** assessed resources with at least one Unhealthy assessment, counted once.
- **Failed findings:** unique Unhealthy resource/assessment pairs, or assessment identities when a resource ID is unavailable.
- **High-severity failures:** Unhealthy findings whose assessment severity is High; Healthy High-severity recommendations are excluded.
- **Not applicable / Unknown state:** separate finding counts, never treated as Healthy.
- **Unmapped recommendations:** regulatory recommendations with no matching resource assessment. These remain visible but are not counted as assessed resources.

The **Resource detail state** selector uses checkboxes and defaults to **All**. Select one or more of **Unhealthy**, **Healthy**, **Not applicable**, **Unknown**, or **No resource assessment** to filter the resource detail grid only; the summary's coverage denominator remains unchanged.
**Not applicable** corresponds to the `NotApplicable` assessment status. **Unknown** indicates a missing or unrecognized status; **No resource assessment** indicates a recommendation without a matching resource assessment.
Findings without an identifiable resource are retained but excluded from resource totals. Workload results describe **resource posture**, not a regulatory compliance percentage or certification.

Resource findings use a **resource-first browser**, not an unscoped resource-recommendation table that can exceed Workbooks' 10,000-result ceiling.
**Detail subscription** is a single native subscription picker, starts unset, and offers subscriptions in the main **Subscription** scope. The resource browser is hidden unless the detail selection is nonempty and included in that main scope; recommendation queries also require a resource-row selection.
The four resource-browser queries send Resource Graph requests to that detail subscription only. Both inputs of their joins additionally intersect the detail subscription with the main subscription filter. The workload summary remains globally scoped.
**Resource contains** filters reported resource ID, resource group and provider-qualified type in the query, before output limits. These detail-only filters do not change the all-state workload summary.

The resource list aggregates matching recommendation pairs to one row per workload, subscription and cloud-aware resource identity. Its counts follow the current detail-state filter; the overview remains all-state.
Missing-identity and unmapped rows remain selectable identity groups. Selecting a resource exports a separate scope parameter; the resource-list query never reads its own exported parameter, avoiding a refresh cycle.
Recommendation queries require the selected workload, subscription and exact resource key and reapply the current subscription, standard, workload, state and search filters.
A stale selection excluded by those filters returns no matches, never a broader inventory.
**Hide resource details** clears only the exported detail scope; it does **not** deselect the grid row. To reopen the same resource, deselect its row checkbox and select it again. Keyboard users should focus that checkbox and use its native toggle interaction. This guidance stays visible after details are hidden.
Do not blank **Detail subscription** or rely on refreshing the grid to reset a row selection.

Select a resource row outside its link to show its recommendations. Recognized Azure resource names open their Azure resource overview; AWS, Google Cloud, missing and malformed identities remain text.
Recommendation names open the resource-specific Defender destination when a valid source-provided link is available, or the reported general recommendation otherwise.
The workbook adds HTTPS to recognized scheme-less Azure portal destinations and does not create links for unrecognized hosts.

Two server-side count tables show the matching resource/identity-group and finding totals, and the selected resource's matching recommendation count, before output-row limits.
They explicitly flag scopes above 10,000 resources or recommendations. Both grids have an explicit 10,000-row display limit.
Narrow Workload or Resource contains for an oversized resource list; narrow standard or state for oversized selected-resource detail.
A below-limit count is a row-budget observation, not proof of complete source visibility. Counts and lists use separate requests and can change between refreshes.

Native grid search and Excel export operate on returned data only; they cannot retrieve omitted rows or provide an unlimited tenant inventory. The resource list exports resource aggregates; the selected-resource table exports that resource's returned recommendations. Query errors and native service-limit warnings remain visible.
Narrowing request scope and gating excluded detail selections do not guarantee complete results or exports, or prove that every parameter-update race is prevented. The previously reported **Query partially succeeded** service warning was not reproduced and its cause remains unknown; affected results and exports may be incomplete or incorrect.

### Compliance Detail

Control results are grouped by subscription and standard. The **Control state** selector uses checkboxes, defaults to **All**, and detects the normalized states present in the selected subscription, standard, and detail scope, independently of the current state selection.
Select one or more available states, which can include **Failed**, **Passed**, **Skipped**, **Unsupported**, **Not applicable**, and **Unknown**. Missing or unrecognized states remain **Unknown**, not passed.
Changing scope refreshes the available states; a state absent from the scope is not offered as if matching results existed.

**Control contains** searches control IDs and descriptions in the query, before result limits. It applies to the control list, matching-control count and available control states.
Clearing it restores the current subscription, standard, detail-scope and state selection; it does not change those filters.

Use **Failed** to prioritize remediation. Descriptions have more display space and open their full text when selected. Passed/failed/skipped values are assessment counts per control, not unique resource counts. Group rows do not default to a green success icon.

Select an individual control row to show its mapped recommendations below the grid.
The query requires its exact subscription, standard and control, and reapplies the current subscription, standard, detail scope and state filters.
Group rows, missing identities and stale selections cannot open an unscoped recommendation list. **Clear control selection** removes only this selection.
Recommendation names link to valid Defender destinations supplied by the assessment; their resource counts are not unique-resource totals across recommendations.
The separate count shows the matching row budget; the grid, search and export remain subject to the 10,000-row and source limits.

**Matching controls** counts the filtered controls server-side before output limits and warns when the selection exceeds the grid's 10,000-row budget.
Narrow Subscription, Compliance standard, Control state or **Control contains**, or choose one subscription and standard in **Compliance Detail scope**, before reviewing or exporting an oversized selection.
The count and list use separate requests and can change between refreshes; a below-limit count is not proof of complete source visibility.
The grid retains the [Azure Workbooks maximum display limit of **10,000 rows**](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-limits), subject to query and Resource Graph limits. There is no automatic pagination or unlimited export.
Unlike **Control contains**, native grid search filters returned data only and cannot retrieve omitted controls; Excel export likewise includes returned data, not a guaranteed complete inventory.
Selected-control recommendations reapply the control search so an excluded stale selection cannot show recommendations from outside that search.

**Compliance Detail scope** limits this tab to one subscription and standard. **Clear detail scope** clears that selection; the main subscription and standard filters remain active. If the main filters exclude the selection, clear the detail scope rather than interpreting the empty result as compliance.

### Regulatory Compliance Configuration

This read-only tab separates **standards rollout and reporting**, **Defender plan configuration**, **continuous export configuration**, and **history and workspace data** for the selected subscriptions. It does not configure exports, assign policies, install components, create workspaces, or change retention.

Subscription names and recognized Azure automation, scope and destination resource IDs open their corresponding resource overviews. Missing or malformed values remain visible without an Azure link. Historical rows can open the source subscription but do not link a historical control to a potentially unrelated current result.

The shared **Setup tips** control at the top defaults to **On**. It shows each section's setup instructions and Microsoft Learn links; **Off** hides those four help blocks without hiding the data, section headings, evidence limitations or operational warnings.
**Open Compliance Over Time** remains available either way. Setup tips never runs history queries or changes Azure settings; **Query history** remains a separate, default-off opt-in.

- **Regulatory-compliance reporting** counts standards returned by Azure Resource Graph and those with assessed controls. Missing results can reflect permissions, missing assignments, or reporting delays; they do not prove Defender for Cloud is disabled.
- **Reported standards by subscription** names the standards actually returned, their observed assessment coverage, and a recommended next step.
  Choose a reported subscription and standard in **Compliance Detail scope**, then use **Open selected standard in Compliance Detail**; the top standard filter still applies.
  A not-observed row is not a selectable standard. Invalid or missing assessed-control counts remain unknown, not zero or passed.
  Reporting is not a complete assignment inventory: an assigned standard can have no relevant assessed resources and be absent. Confirm assignments, inherited scopes, exclusions and exemptions through **Manage compliance policies**. See [Assign regulatory compliance standards](https://learn.microsoft.com/en-us/azure/defender-for-cloud/assign-regulatory-compliance-standards).
- **CSPM level and paid-plan enabled state by subscription** distinguishes **Foundational CSPM (free)** from **Defender CSPM (paid)** using the subscription-level `CloudPosture` pricing record.
  `Standard` means **Enabled (paid)**; `Free` means Defender CSPM is **Disabled**, with the free Foundational baseline available. Missing or unrecognized evidence remains **Not observed / verify** or unknown, not Disabled.
  The summary also shows reported plan enforcement and extension-inventory evidence. Foundational includes basic posture capabilities; Defender CSPM adds advanced capabilities, including regulatory-compliance assessments.
  Neither a pricing record nor an enabled feature establishes installed agents, completed scans, effective protection or compliance. See [CSPM levels and capabilities](https://learn.microsoft.com/en-us/azure/defender-for-cloud/concept-cloud-security-posture-management).
- **CSPM feature settings** keeps eight expected components visible: agentless machine scanning, Kubernetes API access/discovery, registry access/image vulnerability assessment, sensitive data discovery, CIEM, API posture, serverless protection and serverless containers. It also retains additional reported extensions.
  **Enabled / Disabled** comes only from each reported `isEnabled` switch and is shown separately from the paid parent plan. **Not reported** is not Disabled. An enabled switch under a disabled parent plan is flagged, not treated as active Defender CSPM coverage. Other plans can supply overlapping capabilities; a disabled CSPM switch does not establish an absence of equivalent protection.
  VM-scanning `ExclusionTags` values and additional-property **names** are shown for review; arbitrary property values are not projected. Missing exclusions are not proof that no exclusions exist.
  Malformed/missing arrays, unknown or duplicate setting rows and arrays exceeding the expansion budget are review findings, not passes. Eight expected entries share Resource Graph's 2,000-entry expansion budget, leaving room for 1,992 reported entries per subscription.
  Grids explicitly allow up to 10,000 rows, subject to Resource Graph limits. Narrow the subscription selection when warnings appear; client-side search and Excel export cannot recover omitted data.
  Setup tips explains each monitored component's purpose, portal steps, machine exclusions, Subscription Owner permissions, workload/cloud/region prerequisites, data-access implications and costs, with [component setup guidance](https://learn.microsoft.com/en-us/azure/defender-for-cloud/tutorial-enable-cspm-plan) and feature-specific Microsoft Learn links.
  The shared default-On toggle hides this guidance, not the audit data or its limitations.
  Actual scan coverage, connector onboarding, data-sensitivity rules, resource overrides and capabilities without an independently reported switch require separate verification. Serverless container posture is not runtime threat detection; review Registry access and actual registry permissions for full features.
  No plans, components, role assignments or billable services are enabled by this workbook.
- **Observed subscription Defender plan settings** lists visible subscription-level `Microsoft.Security/pricings` resources, including friendly names where recognized and the raw plan ID, tier and subplan. **Standard** is explicitly **Enabled (paid tier)**; **Free** means the paid tier is disabled, not that every free capability or every resource is disabled. Free is not automatically a failure.
  Missing configuration remains not observed, not disabled. Resource-level overrides and monitoring-component health are not inventoried here. Review applicable permissions, regulatory-standard prerequisites and costs before changing plans.
  See [Configure Defender plans](https://learn.microsoft.com/en-us/azure/defender-for-cloud/enable-enhanced-security) and the [pricing and extension API reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.security/2024-01-01/pricings).
- **Continuous-export settings** are checked per source subscription and Log Analytics destination, one row per setting: streaming updates, snapshots, export scope, source filters, destination workspace, same workspace for both, and configuration list size.
  Each row shows the observed value, the recommended value (enabled, subscription-wide, unfiltered `RegulatoryComplianceAssessment` and `RegulatoryComplianceAssessmentSnapshot` events to the **same valid workspace**) and a result: green check (matches), red X (does not match) or a neutral marker (not observed or unknown, never treated as Off).
  Setup tips explain what each setting checks and why the value is recommended. **Same workspace for both** checks configured target alignment, not whether either export is enabled or data was delivered.
  A match establishes configuration evidence only, not delivery, access, retention, or historical readiness.
  For each event type, any known enabled automation takes precedence; otherwise unknown enablement takes precedence over disabled evidence. An Off result therefore never hides a relevant unknown automation.
  A visible workspace is retained even when its automation has an empty source list or only unrelated sources such as alerts. A complete source inventory without the relevant regulatory event shows **Not configured**, not On; missing or incomplete source inventory remains Unknown.
  For **Same workspace for both**, a complete one-type inventory is a mismatch; one observed type with incomplete missing-type evidence remains **Unknown**. Both actually observed target types match, while an invalid destination takes precedence.
  Otherwise-complete scope, filter, destination and list-size checks say **Not observed (no confirmed enabled export)** when no regulatory export is confirmed enabled; this does not assert that unknown automations are disabled.
  Export scope and source filters consider each automation's own regulatory sources. Known enabled narrow or filtered regulatory evidence takes precedence as a mismatch.
  Without a known failure, a regulatory automation with unknown enablement and a narrow or unreported scope or a source filter leaves the corresponding check **Unknown**, even when another automation matches.
  Missing, malformed or oversized source inventories on potentially enabled automations leave both checks **Unknown** unless the relevant known failure already takes precedence.
  Known disabled automations and complete alerts-only or empty-source inventories do not affect valid regulatory scope/filter matches.
  Scope, source and action-type inventories expand together, then aggregate by automation ID before destinations expand. The settings query uses three `mv-expand` operators, never a scopes-by-sources-by-actions product, and does not combine sources, scope, filter or destination evidence from unrelated automations.
  Empty scopes remain visible for review. Missing, malformed or oversized lists produce bounded warning rows instead of disappearing or passing; lists over 2,000 entries are not partially accepted as complete.
  A malformed sibling action marks configuration list size incomplete for every workspace on that automation while retaining the warning row; recognized Event Hub and Logic App actions do not make the inventory incomplete.
  Destination and same-workspace matches require a GUID-qualified Log Analytics workspace resource ID.
- **Export data types by automation** lists each visible automation against Security recommendations, Secure score, Security alerts, Regulatory compliance and Security attack paths, with separate **Streaming updates** and **Snapshots** configuration states.
  These show **On**, **Off**, **Partially on**, **On (filtered)**, **Unknown / review**, **Not observed**, or **Not applicable**.
  The master **Automation enabled** switch is separate: selected data types under a disabled automation are not active export.
  Missing, malformed or oversized source lists remain unknown, not Off; Security alerts have no snapshot source.
  This is configuration evidence, not delivery proof.
- Three detailed inventories show **all visible security automations**, including non-compliance sources and non-workspace destinations. Match Automation ID across the tables to inspect the automation switch, location, description, scope paths and descriptions, source/destination counts, workspace/Event Hub/Logic App resource IDs, and Event Hub trusted-service switch.
  **On / Off** comes only from the reported automation or trusted-service Boolean; unknown and not-observed values are distinct. These are configuration settings, not delivery checks. Source rows show configured API event names, streaming or weekly snapshot frequency, and individual filter properties, types, operators and expected values. Rule sets use OR; rules within each numbered set use AND.
  The detailed source inventory lists configured sources; use **Export data types by automation** above it to see unconfigured items as Off when the source list is complete, or Unknown when inventory is incomplete.
  Missing, empty or malformed arrays and lists exceeding 2,000 entries per level are flagged; narrow selections when Resource Graph result limits apply. Unknown event/destination types remain visible for review.
  Connection strings and signed Logic App trigger URLs are never projected. Delivery, destination permissions, retention, costs and portal-only settings require separate verification. See the [security automation API field reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.security/2023-12-01-preview/automations).
- Resource-group-only or unknown scopes, nonempty or malformed source filters, invalid destination IDs, disabled or unknown enabled states, and configuration arrays exceeding the Resource Graph expansion limit are flagged for review rather than passed.
  Additional disabled or unknown automations remain visible in the detailed inventories below even when another automation matches for the same workspace. Event Hub-only destinations do not meet the Log Analytics requirement.
  **Not observed** is not proof of absence: Resource Graph is limited to resources visible to the caller. Narrow large selections if result limits apply.
- To check data, select **one destination workspace** and set **Query history** to **Run check**.
  The selector searches accessible workspaces across subscriptions in the active directory, including centralized destinations outside the selected source subscriptions. Destinations in another tenant require appropriate access and a separate tenant context.
  The 90-day query uses `RegulatoryComplianceSubscriptionId` for the source subscription and `TenantId` for the Log Analytics workspace ID, not `_SubscriptionId`. Records without a source-subscription ID cannot be attributed to a selected subscription in this view.
- The history grid includes selected subscriptions with no matching records when the table is queryable. A missing `SecurityRegulatoryCompliance` table or insufficient query access is surfaced as a query error, not a pass.
  No snapshot can mean a new export, absent data, retention, or access issues. Snapshots are weekly; allow at least one week for the first snapshot and additional time to build history. No snapshot in eight days is a review signal.
  A span of at least six days between snapshot records is an observation, not proof of complete snapshots or a valid trend. Streaming occurs on changes, so no recent stream alone is not a failure.
- With **Run check** enabled, **History standard** offers the standards present in the selected source subscriptions' snapshots in that workspace over the last 90 days. It does not depend on the current ARG standard list. Delivery evidence remains across all standards; the selector scopes the historical posture, trend, coverage, and control-change panels only.
- **Latest observed snapshot by standard** keeps each source subscription and standard separate. Records are grouped by UTC snapshot day and deduplicated by control, recommendation, assessed resource, and timestamp.
  The latest record wins within that identity; conflicting states at the same timestamp prefer failed evidence. A failed assessment makes the control Failed, otherwise unknown evidence blocks Passed, otherwise a passed assessment makes it Passed.
  Skipped, not-applicable, and unsupported results are not assessed passes.
- **Pass % (assessed)** is `100 * passed / (passed + failed)` for that subscription-standard snapshot. Other control states are displayed separately. Missing control or recommendation identifiers flag partial results and suppress affected percentages.
  An all-unassessed snapshot has **N/A**, not 100%. The delivery table also counts snapshot records with incomplete standard/control/recommendation identifiers. Records without a source-subscription ID cannot be assigned to the selected scope.
- **Matched change (pp)** compares the latest and previous observed UTC snapshot days using only controls that are Passed or Failed in both. The table shows both actual dates and the matched-control count.
  This is not a guaranteed seven-day comparison, and it is not the difference between two differently scoped overall percentages. No earlier snapshot, no common assessed controls, or incomplete identifiers makes the change **N/A**.
- The two full-width **weekly** point charts show assessed-control pass percentage and assessed-control count, with one series per subscription-standard pair. Each UTC week uses its latest observed snapshot day.
  Missing weeks and unusable rates are omitted rather than plotted as zero. After selecting each week's latest observed day, incomplete control or recommendation identifiers suppress its coverage point too; an earlier complete day does not replace it. A complete all-unassessed snapshot retains genuine zero assessed-control coverage. Points are not connected across missing history.
  Chart timestamps can display in your local time zone; the comparison tables show literal UTC dates. Changing assessed-control coverage can affect rates; inspect both charts, scope narrowly for readable legends, and respect native query/chart limits.
  A day bucket is an observation, not proof of an atomic or complete export batch.
- **Control changes** lists changed states, newly observed controls, and controls not observed in the latest snapshot. These are observations between the two available days, not proof that a control was created, deleted, or remediated. Only Failed-to-Passed is labeled recovered. A no-change/empty grid is not proof of no change when history is absent.

These snapshot views are inspired by [Microsoft's Compliance Over Time template](https://github.com/microsoft/Application-Insights-Workbooks/blob/master/Workbooks/Azure%20Security%20Center/Compliance/Compliance.workbook), but deliberately preserve subscription boundaries and unknown states instead of building a cross-subscription compliance score.
Streaming records are used for delivery evidence, not mixed into snapshot posture; the latest history can lag the current ARG Overview. Each opt-in panel queries up to 90 days of Log Analytics data and can incur query costs. Scope changes can refresh multiple panels.

Readers need visibility of the source subscriptions and their security automations, plus query access to the chosen Log Analytics workspace and table.
Setting up continuous export requires additional permissions described in the [continuous export documentation](https://learn.microsoft.com/en-us/azure/defender-for-cloud/continuous-export). Review workspace access, retention, and applicable ingestion/retention costs before changing settings.
Use **Open Compliance Over Time** to open [Microsoft's published workbook template](https://github.com/microsoft/Application-Insights-Workbooks/blob/master/Workbooks/Azure%20Security%20Center/Compliance/Compliance.workbook), then choose the workspace in that workbook.
Alternatively, open the built-in workbook from the [Defender for Cloud workbooks gallery](https://portal.azure.com/#view/Microsoft_Azure_Security/SecurityMenuBlade/~/28) in commercial Azure, or follow the [Microsoft workbook guidance](https://learn.microsoft.com/en-us/azure/defender-for-cloud/custom-dashboards-azure-workbooks#compliance-over-time-workbook).
In other clouds, open **Defender for Cloud > Workbooks** in the appropriate portal.

## Data coverage and export

Azure Resource Graph provides the current state, not historical trends. The optional readiness history query reads Log Analytics evidence separately. Empty results can mean missing permissions, disabled initiatives, unmatched filters, or incomplete coverage; they do not prove compliance. Not-applicable, unknown, and unmapped results are explicit.

All result grids support Excel export. Azure Resource Graph result-row limits also apply to detail grids and exports; exports contain returned rows, not an unlimited inventory. Narrow subscription, standard, workload, or state filters for large scopes. Summary counts are calculated server-side before result-row limits.

## Workbook files

| File | Purpose |
| --- | --- |
| [regulatorycompliance.workbook](./regulatorycompliance.workbook) | Standalone, paste-ready `Notebook/1.0` workbook JSON for the portal Advanced Editor. |
| [armTemplate.json](./armTemplate.json) | ARM template for deploying the same definition as a saved workbook. |

The standalone `.workbook` file contains plain JSON; it is not an ARM template. The two-file import/deployment layout follows the Defender for Storage workbook pattern while retaining the `.workbook` filename.

## Manual import with the Advanced Editor

1. Open [regulatorycompliance.workbook](./regulatorycompliance.workbook), select **Raw**, and copy the entire JSON, or copy the contents of the local file.
2. Open **Microsoft Defender for Cloud > Workbooks > New > Advanced Editor (</>)**, or **Edit > Advanced Editor** on an existing workbook. **Azure Monitor > Workbooks > New** is another entry point.
3. Choose **Workbook Template** (**Gallery Template** in some portal versions), replace the editor contents, and select **Apply > Done Editing**. Select **Save** only when ready to persist the workbook.

**No conversion, decoding, or extraction is required.** Paste the contents of `regulatorycompliance.workbook`, not `armTemplate.json`, a GitHub HTML page, or a quoted `serializedData` value. The first property is `"version": "Notebook/1.0"`. Importing JSON does not rename an existing saved workbook; update its saved name separately.

## Deploy to Azure

The template uses the stable `2023-06-01` workbook API, matching the Defender for Storage deployment pattern. ARM decodes `variables.workbookDataBase64` through a short `base64ToString` expression. The standalone JSON remains unencoded and contains the same definition, including valid workbook null values and empty arrays.

The existing Compliance deployment contract is retained: `workbookName` defaults to **Microsoft Defender for Cloud - Regulatory Compliance**, `location` defaults to the resource-group region, and `workbookSourceId` defaults to `azure security center`.
The source is a technical compatibility identifier, not a display name. These parameters can be overridden. Resource naming remains deterministic for the resource group and deployment name; redeploy with the same deployment name to update that workbook. The `workbookId` output identifies the saved resource.

**PR preview - after the updated artifacts are published to the branch**

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbillmcilhargey%2FMicrosoft-Defender-for-Cloud%2Frefs%2Fheads%2Ffeat%2Fregulatory-compliance-overview-workloads%2FWorkbooks%2FRegulatory%2520Compliance%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton" alt="Deploy PR preview to Azure"/></a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbillmcilhargey%2FMicrosoft-Defender-for-Cloud%2Frefs%2Fheads%2Ffeat%2Fregulatory-compliance-overview-workloads%2FWorkbooks%2FRegulatory%2520Compliance%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazuregovbutton" alt="Deploy PR preview to Azure Government"/></a>

**Published workbook - updated after merge**

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FWorkbooks%2FRegulatory%2520Compliance%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton" alt="Deploy to Azure"/></a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FWorkbooks%2FRegulatory%2520Compliance%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazuregovbutton" alt="Deploy to Azure Government"/></a>

1. Select the appropriate button, sign in, and choose a subscription, resource group, and region.
2. Review the workbook name, location, and source, then select **Review + create > Create**.
3. Open the saved workbook under **Microsoft Defender for Cloud > Workbooks** and select the reporting scope.

The preview buttons read the PR branch; the published buttons read upstream `main`. Neither includes changes that exist only in a local worktree. To use an unpublished local template, upload [armTemplate.json](./armTemplate.json) through **Deploy a custom template > Build your own template in the editor** instead.

**Permissions:** workbook deployment/write access to the target resource group, read access to selected subscriptions and security resources, and query access to the selected Log Analytics workspace when checking history.

## Maintaining the workbook JSON

Edit [regulatorycompliance.workbook](./regulatorycompliance.workbook), then regenerate `variables.workbookDataBase64` in [armTemplate.json](./armTemplate.json). Keep the deployment's `base64ToString` expression intact. Do not remove workbook fields or disable ARM validation to satisfy envelope checks.

From this directory in PowerShell 7:

```powershell
$workbookBytes = [IO.File]::ReadAllBytes((Resolve-Path .\regulatorycompliance.workbook).Path)
$null = [Text.Encoding]::UTF8.GetString($workbookBytes) | ConvertFrom-Json -Depth 100
$template = Get-Content .\armTemplate.json -Raw | ConvertFrom-Json -Depth 100
$template.variables.workbookDataBase64 = [Convert]::ToBase64String($workbookBytes)
$template | ConvertTo-Json -Depth 100 | Set-Content .\armTemplate.json -Encoding utf8
```

The folder's `.gitattributes` pins both deployment artifacts to LF line endings so Git checkout does not break exact-byte payload parity on Windows. Keep `regulatorycompliance.workbook` as UTF-8 without a BOM and preserve its LF endings before regenerating the payload.

Validate the standalone JSON against the workbook schema, compare the decoded UTF-8 bytes with the standalone file, and validate the ARM envelope separately. Run `npm test` and `npm run tsc -- --noEmit` from the repository root.
These offline checks do not qualify authenticated portal behavior, keyboard rendering, or every asynchronous parameter transition.
Validate the exact final source in a freshly confirmed tenant and non-production scope using a new unsaved workbook; never save it or change tenant settings as part of this check.

## Questions
You can submit any questions or requests [here](https://github.com/Azure/Microsoft-Defender-for-Cloud/issues). Please also refer to our [Wiki](https://github.com/Azure/Microsoft-Defender-for-Cloud/wiki#resources), as it will provide you with further information.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit <https://cla.microsoft.com>.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
