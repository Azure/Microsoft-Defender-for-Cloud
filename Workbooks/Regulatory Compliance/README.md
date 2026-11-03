# Microsoft Defender for Cloud - Regulatory Compliance
**Original author:** [Vanessa Bruwer](https://github.com/vanessabruwer) | [FastTrack for Azure](https://aka.ms/fasttrackforazure)

This workbook displays current Microsoft Defender for Cloud regulatory compliance results across selected subscriptions using Azure Resource Graph. It provides subscription-first compliance reporting, resource posture by workload, and control-level detail.

## Contributors

- [Dr Bill Mcilhargey](https://github.com/billmcilhargey)
- [Lior Arviv](https://github.com/liorarviv)

Additional human contributors from this workbook folder's Git history, including this change set; the original author is credited above. Automated accounts and merge-only credits are excluded. Names use each verified GitHub profile's display name, or its username when no display name is set.

## Views and filters

The **Subscription** and **Compliance standard** selectors apply to every tab. The single-select standard selector defaults to **All**; select one standard or all available standards rather than a hard-coded initiative.

### Overview

- Coverage cards show reporting versus selected subscriptions, assessed subscription-standard pairs, and subscription-standard pairs with failed controls. Repeated standards in different subscriptions are separate results.
- Expand a subscription to compare its standards. Subscriptions with failing standards are sorted first.
- Counts remain numeric. Pass percentage is calculated separately for each standard as `100 * passed / (passed + failed)`, excluding skipped and unsupported controls. A zero denominator is shown as **N/A**; overlapping standards are not averaged into a subscription compliance score.
- Subscription status is the worst child result: failed takes precedence, incomplete/unassessed results remain neutral, and passed is shown only when the child results support it.
- Status values stay numeric for roll-up; their formatter thresholds are serialized as strings for compatibility with the current portal renderer.
- Select a standard row to open **Compliance Detail** with that standard and subscription selected.
- Row selection exports a separate drill-through scope, not the global standard filter consumed by the Overview query. This avoids a refresh cycle while keeping the main filters unchanged.

### Workloads

Workload is an operational resource family, not a business application or a tag-based grouping. The resource hierarchy is **workload > subscription > resource > recommendation**.
Azure resources are grouped by their canonical, case-insensitive ID. The reported resource ID remains available in resource detail and export; native cloud identities retain case.

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

Control results are grouped by subscription and standard. Use **Failed only** to prioritize remediation. Descriptions have more display space and open their full text when selected. Passed/failed/skipped values are assessment counts per control, not unique resource counts. Group rows do not default to a green success icon.

An Overview selection scopes this tab to the selected subscription and standard. **Clear Overview drill-through** clears that row selection's scope; the main subscription and standard filters remain active. If the main filters exclude the drilled selection, clear the drill-through scope rather than interpreting the empty result as compliance.

## Data coverage and export

Azure Resource Graph provides the current state, not historical trends. Empty results can mean missing permissions, disabled initiatives, unmatched filters, or incomplete coverage; they do not prove compliance. Not-applicable, unknown, and unmapped results are explicit.

All result grids support Excel export. Azure Resource Graph result-row limits also apply to detail grids and exports; exports contain returned rows, not an unlimited inventory. Narrow subscription, standard, workload, or state filters for large scopes. Summary counts are calculated server-side before result-row limits.

The editable [workbook](./regulatorycompliance.workbook) and the workbook embedded in the [deployment template](./armTemplate.json) contain the same definition.
Unused nullable formatter properties are omitted so ARM template validation can also validate the embedded definition.

## Try on Portal
You can deploy the workbook by clicking on the buttons below:

The template uses the stable `2022-04-01` workbook API. `location` defaults to the resource-group region. `workbookSourceId` retains `azure security center` as a technical compatibility identifier for Microsoft Defender for Cloud, not a display name. Both parameters can be overridden at deployment.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FWorkbooks%2FRegulatory%2520Compliance%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FWorkbooks%2FRegulatory%2520Compliance%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazuregovbutton"/></a>

To deploy the workbook you will need **write permissions** in the subscription where it will be stored. To view the information, you will need **read permissions** of all subscriptions that are in the defined groups.

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
