# Azure Arc Connected Servers - Multicloud and Hybrid Inventory

**Author: Inbal Silis**

Inventory Azure Arc-enabled servers across AWS, GCP, other clouds, private clouds, datacenters, and edge environments. The server inventory queries `Microsoft.HybridCompute/machines` directly in Azure Resource Graph. It does not depend on a Defender for Servers plan, a Defender for Cloud recommendation, or a security connector.

## Views

| Tab | Contents |
| --- | --- |
| All Arc servers (default) | Every visible Arc server resource, including resources without provider metadata or Defender for Cloud discovery records. |
| AWS | Arc servers reporting AWS, plus a separate EC2 discovery table from Defender for Cloud. |
| GCP | Arc servers reporting GCP, plus a separate GCP virtual machine discovery table from Defender for Cloud. |
| Other / unknown | Arc servers reporting another provider, or no provider. Includes private clouds, datacenters, and edge locations. Rows without provider metadata display **Environment = Unknown**, not a confirmed on-premises location. |

Server lists include the Arc resource name, computer name, reported cloud provider, connection status, operating system, agent version, subscription, resource group, Azure resource location, and resource link.
All Arc servers and Other / unknown also display the environment classification.
A registered Arc resource is not necessarily currently connected: disconnected, expired, error, and other reported states remain visible.

Each table has a specific empty-state message. Empty results describe the selected scope, not the entire tenant or the absence of machines in a cloud account. Query failures remain errors rather than being presented as empty inventory.

## Scope and prerequisites

- Select the Azure subscriptions containing the Arc resources and, for discovery, the Defender for Cloud security connectors. Queries use your Azure Resource Graph read permissions.
- The **AWS account (discovery only)** and **GCP project (discovery only)** selectors filter only the Defender for Cloud discovery tables. Arc server lists remain subscription-wide, including manually onboarded servers that have no security connector.
- Defender for Cloud security connectors and assessment records are required only for the optional AWS/GCP discovery tables. They are not required for the Arc inventory.
- This is a current-resource inventory, not historical telemetry. Azure Resource Graph and connector discovery can take time to reflect changes.

## Interpreting AWS/GCP and Azure inventory results

The AWS and GCP Arc lists use the documented [`properties.cloudMetadata.provider`](https://learn.microsoft.com/en-us/javascript/api/@azure/arm-hybridcompute/cloudmetadata) field, normalized for case and surrounding spaces. Resource names, the Azure resource location, and the Defender for Cloud **Environment** label are not used to infer the hosting provider.

A **Machine - Azure Arc** resource can appear under **Azure** in Defender for Cloud inventory because its resource representation is in Azure.
It is still included in **All Arc servers**, regardless of its physical hosting environment.
If its cloud-provider metadata reports AWS or GCP, it also appears in that tab; otherwise it appears in **Other / unknown**.
Missing provider metadata displays **Environment = Unknown** and **CloudProvider = Unknown**.
An EC2-style name or an `AWSPlatformDetails` tag is not used to infer the hosting provider or replace Arc-reported OS fields.

### Reading unknown and missing metadata

| Display | Arc property or fallback |
| --- | --- |
| Environment / CloudProvider = Unknown | `properties.cloudMetadata.provider` is missing or empty. The hosting environment is unverified, not confirmed as on-premises. |
| ConnectionStatus = Unknown | `properties.status` is missing, empty, or already reports an unknown value. This does not establish a Connected or Disconnected state. |
| OSName = Unknown | Neither `properties.osName` nor `properties.osType` supplies a value, or the reported value itself is unknown. A platform tag is separate metadata. |
| AgentVersion = Not reported | `properties.agentVersion` is missing or empty. No agent version was returned. |
| ComputerName matches the Arc resource name | If `properties.osProfile.computerName` and `properties.machineFqdn` are unavailable, the query falls back to the resource name. This is not proof of an agent-reported hostname. |

These are intentional display fallbacks, not an assertion that the Arc agent is installed, connected, disconnected, or absent.
An Arc resource's presence and **Defender for Cloud: On** do not establish agent connectivity.
Defender for Cloud resource health can show the same unknown OS and status while still displaying an `AWSPlatformDetails` tag or security recommendations.

To investigate, inspect the Arc resource's JSON and its Azure Resource Graph properties for the fields above, then check the machine's Connected Machine agent onboarding and heartbeat.
Missing or stale metadata can require investigation, but the workbook cannot identify the cause from an inventory row alone.
See the [Arc inventory query examples](https://learn.microsoft.com/en-us/azure/azure-arc/servers/resource-graph-samples) and [agent connection troubleshooting](https://learn.microsoft.com/en-us/azure/azure-arc/servers/troubleshoot-agent-onboard).

### Interpreting discovery matches

The discovery tables show assessment-backed EC2/GCP compute records and preserve records even when their display name is missing or they have only one assessment.
Name sources are aggregated separately before applying fallback precedence: reported display name, resource-details name, native resource ID, then Azure resource ID.
An unnamed assessment cannot replace another assessment's reported name with a fallback ID.
Native cloud identities are kept separate from Azure resource IDs, so account/project filtering and Azure resource links use the Azure identity.

**ArcMatch is only a matching hint.**
Possible matches compare the discovered name with the Arc resource name, computer name, and FQDN, case-insensitively and within the same Azure subscription.
Arc candidates must report the same provider or have unknown provider metadata.
Names can be reused across accounts, projects, regions, or zones, and an Arc resource can be registered in a different subscription.
Neither a possible name match nor an unmatched discovery record proves Arc installation or absence.
Verify the native instance identity and the linked Arc candidates before acting.

This replaces the previous definitive "without Arc deployment" wording: assessment discovery and name-only joins cannot reliably establish absence. The direct Arc inventory is the source of truth for visible Arc resources. "No discovery records" is also not proof that an AWS account or GCP project has no virtual machines; check connector configuration, permissions, and freshness.

## Import or deploy

- To update an existing workbook, open **Edit > Advanced Editor**, replace the Gallery Template JSON with [ArcDepolyment.json](./ArcDepolyment.json), and select **Apply**, then **Save**.
- To deploy a new workbook, use [armTemplate.json](./armTemplate.json). Its embedded workbook content matches the standalone JSON. The legacy folder and JSON filename are retained for existing links.
- The deployment `location` parameter defaults to the resource group's Azure region and can be overridden if needed.
- The template's default saved name is **Azure Arc Connected Servers - Multicloud and Hybrid Inventory**. Existing saved workbooks can be renamed separately when saving.

The existing portal buttons deploy the published version; local changes are available there only after publication:

<a href="https://aka.ms/AAopem3" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
<a href="https://aka.ms/AAopem3" target="_blank"><img src="https://aka.ms/deploytoazuregovbutton"/></a>

The previous [overview screenshot](./overview.png) shows the original two-tab Defender for Servers view, not the updated inventory.
