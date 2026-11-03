# Microsoft Defender for Cloud - Regulatory Compliance
**Original author:** [Vanessa Bruwer](https://github.com/vanessabruwer) | [FastTrack for Azure](https://aka.ms/fasttrackforazure)

This workbook displays current Microsoft Defender for Cloud regulatory compliance results across selected subscriptions using Azure Resource Graph. It provides subscription-first compliance reporting, resource posture by workload, and control-level detail.

## Contributors

- [Dr Bill Mcilhargey](https://github.com/billmcilhargey)
- [Lior Arviv](https://github.com/liorarviv)

Additional human contributors from this workbook folder's Git history, including this change set; the original author is credited above. Automated accounts and merge-only credits are excluded. Names use each verified GitHub profile's display name, or its username when no display name is set.

## Views and filters

The **Subscription** selector scopes every tab. **Compliance standard** applies to Overview, Workloads, and Compliance Detail, but not to export configuration or delivery evidence. The single-select standard selector defaults to **All**. Exported snapshots have their own **History standard** selector so standards present only in history remain available.

### Overview

- Coverage cards show reporting versus selected subscriptions, assessed subscription-standard pairs, and subscription-standard pairs with failed controls. Repeated standards in different subscriptions are separate results.
- The coverage panel fits its tile content instead of reserving a fixed chart height. Page and result-grid scrolling use the portal's native scroll regions; close an open filter popup before scrolling the workbook.
- The control-outcomes chart adds the four standard-reported counts across subscription-standard results. It excludes rows with missing or negative counts and is not a compliance score or a count of unique controls: standards and subscriptions can overlap. Other control states are available in Compliance Detail.
- Expand a subscription to compare its standards. Subscriptions with failing standards are sorted first.
- Counts remain numeric. Pass percentage is calculated separately for each standard as `100 * passed / (passed + failed)`, excluding skipped and unsupported controls. A zero denominator is shown as **N/A**; overlapping standards are not averaged into a subscription compliance score.
- Subscription status is the worst child result: failed takes precedence, incomplete/unassessed results remain neutral, and passed is shown only when the child results support it.
- Status values stay numeric for roll-up; their formatter thresholds are serialized as strings for compatibility with the current portal renderer.
- Select a standard row to open **Compliance Detail** with that standard and subscription selected.
- Row selection exports a separate drill-through scope, not the global standard filter consumed by the Overview query. This avoids a refresh cycle while keeping the main filters unchanged.

### Workloads

Workload is an operational resource family, not a business application or a tag-based grouping. The resource hierarchy is **workload > subscription > resource > recommendation**.
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
Azure identities are case-normalized; native cloud identities retain case. Multiple controls referencing one recommendation do not inflate resource or finding counts.

The summary always includes all assessment states within the selected subscription, standard, and workload scope:

- **Assessed resources:** identifiable resources with at least one healthy or unhealthy assessment.
- **Resources with failures:** assessed resources with at least one unhealthy assessment, counted once.
- **Failed findings:** unique unhealthy resource/assessment pairs, or assessment identities when a resource ID is unavailable.
- **High-severity failures:** failed findings whose assessment severity is High; healthy High-severity recommendations are excluded.
- **Not applicable / Unknown state:** separate finding counts, never treated as passed.
- **Unmapped recommendations:** regulatory recommendations with no matching resource assessment. These remain visible but are not counted as assessed resources.

The **Resource detail state** filter, including **Failed only**, filters the resource detail grid only; it does not shrink the summary's coverage denominator. Findings without an identifiable resource are retained but excluded from resource totals. Workload results describe **resource posture**, not a regulatory compliance percentage or certification.

### Compliance Detail

Control results are grouped by subscription and standard. The **Control state** selector defaults to **All** and detects the normalized states present in the selected subscription, standard, and Overview drill-through scope, independently of the current state selection.
Available states can include **Failed only**, **Passed**, **Skipped**, **Unsupported**, **Not applicable**, and **Unknown**. Missing or unrecognized states remain **Unknown**, not passed.
Changing scope refreshes the available states; a state absent from the scope is not offered as if matching results existed.

Use **Failed only** to prioritize remediation. Descriptions have more display space and open their full text when selected. Passed/failed/skipped values are assessment counts per control, not unique resource counts. Group rows do not default to a green success icon.

An Overview selection scopes this tab to the selected subscription and standard. **Clear Overview drill-through** clears that row selection's scope; the main subscription and standard filters remain active. If the main filters exclude the drilled selection, clear the drill-through scope rather than interpreting the empty result as compliance.

### Export & compliance history

This read-only tab examines regulatory-compliance reporting and Defender for Cloud continuous export for each selected subscription. It does not configure exports, assign policies, create workspaces, or change retention.

- **Regulatory-compliance reporting** counts standards returned by Azure Resource Graph and those with assessed controls. Missing results can reflect permissions, missing assignments, or reporting delays; they do not prove Defender for Cloud is disabled.
- **Continuous-export configuration** groups `Microsoft.Security/automations` by source subscription and Log Analytics destination.
  A configuration pass requires enabled, subscription-wide, unfiltered `RegulatoryComplianceAssessment` streaming and `RegulatoryComplianceAssessmentSnapshot` events targeting the **same workspace**.
  A pass establishes configuration evidence only, not delivery, access, retention, or historical readiness. The chart counts each subscription once by its best observed destination; inspect every destination row and its additional findings.
- Resource-group-only or unknown scopes, nonempty or malformed source filters, invalid destination IDs, disabled or unknown enabled states, and configuration arrays exceeding the Resource Graph expansion limit are flagged for review rather than passed.
  Additional disabled or unknown configurations remain visible in Findings even when another configuration passes for the same workspace. Event Hub-only destinations do not meet the Log Analytics requirement.
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
  Missing weeks and unusable rates are omitted rather than plotted as zero; observed zero assessed-control coverage is retained. Points are not connected across missing history.
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
