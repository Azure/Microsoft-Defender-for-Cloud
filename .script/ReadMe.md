# How to add new PR validation

At the time of submitting your Pull Request, automatic GitHub validations using Azure Pipelines is enabled on this repository for basic syntactical checks of the contributions. You can add custom tests as needed based on your scenario following this guidance.

## What is Azure Pipelines  

[Azure Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/what-is-azure-pipelines?view=azure-devops) is a cloud service that you can use to automatically build and test your code project and make it available to other users. It works with just about any language or project type.


## Adding a new validation job
1. Install the following extensions, if you use [VS Code](https://code.visualstudio.com/docs/azure/extensions) editor:
   - [Azure Pipelines](https://marketplace.visualstudio.com/items?itemName=ms-azure-devops.azure-pipelines)
   - [Yaml](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)

2. Run "npm install" cmd, in order to install the libraries used in this project.  
The libraries are defined in package.json

3. Create an Azure Pipeline job for the new validation.  
Add new yaml file under [.azure-pipelines](https://github.com/Azure/Azure-Sentinel/blob/master/.azure-pipelines/) folder, see example in [yamlFileValidator.yaml](https://github.com/Azure/Azure-Sentinel/blob/master/.azure-pipelines/yamlFileValidator.yaml) file (note - the script code should be added on another file for clearer code, see in step #5).
    * Add scripts those are relevant to the specific folder under one yaml file in the same job. The validation infrastructure and the examples are in TypeScript, but you can use other languages if you prefer
    * Azure Pipelines work with many languages such as Python, Java,JavaScript, PHP, Ruby, C#, C++, and Go. Refer to [Azure Pipelines documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/?view=azure-devops) for further information on this.

4. Add the new job to [azure-pipelines.yml](https://github.com/Azure/Azure-Sentinel/blob/master/azure-pipelines.yml) file as a new template under jobs property

5. Create script file for the new validation. The job from step #3 has reference to this file. See instructions in [How to add script validation](#how-to-add-script-validation) section.  
   A step is a failure if it either explicitly reports failure (using a ##vso command) or ends the script with a non-zero exit code

6. Test the new validation. See instruction in [How to test the new validation](#how-to-test-the-new-validation) section

### How to add script validation

**Note**: All script logs are public and display in DevOps pipeline.  
By default, the logs color is white. In case you want another color you can use [logging commands](https://docs.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=bash)

1. Create script file under [.script](https://github.com/Azure/Azure-Sentinel/tree/master/.script) folder

2. In case you use TypeScript language, you can use the infrastructure script. See example in [yamlFileValidator.ts](https://github.com/Azure/Azure-Sentinel/blob/master/.script/yamlFileValidator.ts):
   - Create async validation function that gets file path and returns success in case the validation pass.
   - Create CheckOptions object with 3 properties:  
     - onCheckFile: the validation function that will run on each file (from step one)  
     - onExecError: error behavior in case that the file validation failed  
     - onFinalFailed:  error behavior at the end of the validation, execute in case one of the validation failed
   - Call runCheckOverChangedFiles with properties:
     - checkOptions:  the object you create in the earlier step 2  
     - fileTypeSuffixes : file type filter, example: ["yaml", "yml"]
     - filePathFolderPreffixes: folder path filter, example: ["Detections"]
   - Run prettier command to fix type script files format.  
     - install "npm install -g prettier" if needed
     - Run cmd: prettier --write --print-width 200 ".script/**/*.ts"

### How to test the new validation

1. In case the language script is TypeScript, check the new validation function by local tests. Since most of the code are the same, these tests will help you validate your changes before it gets merged to master.  
See example in [yamlFileValidatorTest](https://github.com/Azure/Azure-Sentinel/tree/master/.script/tests/yamlFileValidatorTest) folder.

   - Create new folder under [.script/test](https://github.com/Azure/Azure-Sentinel/tree/master/.script/tests). folder name format: TestedFileName+Test  
   - Create tests file. Filename format: TestedFileName.test.ts
   - Run the test by execute from  cmd "npm test".  
Since it is run locally you will see "Azure DevOps CI for a Pull Request wasn't found. If issue persists - please open an issue" message. You can ignore it.
   - In order to debug the test file, select "Mocha Current File" option in VSCode  

5. After the code is merged to master, create a Draft PR to test the new validation. Check both options, pass and failed.  
    * (Draft PR marked as "Work in Progress" and cannot be merged, more info [here](https://help.github.com/en/articles/about-pull-requests#draft-pull-requests)).  
    * Remember to delete the draft PR.  

## Workbook browser validation (opt-in)

Adapted from [microsoft/Application-Insights-Workbooks#3260](https://github.com/microsoft/Application-Insights-Workbooks/pull/3260),
at commit `01e1ba4daf9bdc6727b84a4525f781568bbdb5bc`. The shared
[Mocha/Playwright validator](./workbook-browser/workbookBrowserValidator.js) adds source-import,
primary-tab, eager-panel, deferred-content and grid contracts without deploying or saving a workbook.
It complements JSON syntax validation; it does not certify every query or workbook workflow.

### Offline tests and supported inputs

Use Node.js 24 and run `npm ci` from the repository root.

```powershell
npm test
npm run test:workbook
npm run tsc -- --noEmit
```

`npm test` includes the existing TypeScript tests and the new offline regression tests.
`npm run test:workbook` runs only the workbook validator regressions. The
[Azure Pipelines job](../.azure-pipelines/workbookBrowserValidator.yaml) runs that focused suite
without Azure credentials, CDP access, browser installation or portal navigation.
`playwright-core` does not download browsers. Authenticated tests are outside normal test discovery
and run only with `npm run test:browser`.

Unlike the upstream repository, Microsoft Defender for Cloud stores workbooks in several formats.
The [source loader](./workbook-browser/workbookSource.js) supports:

- Native `Notebook/1.0` documents with an `items` array, regardless of `.workbook` or `.json` extension.
- An ARM template containing exactly one top-level `Microsoft.Insights/workbooks` resource,
  with literal JSON in `properties.serializedData`.
- Literal workbook variables referenced by `[variables('name')]`,
  `[string(variables('name'))]` or `[base64ToString(variables('name'))]`.
  The last form supports base64-embedded workbook payloads.
- ARM-escaped strings such as `[[example]` inside literal workbook objects, decoded exactly once.
  Native workbook strings and text inside serialized JSON remain unchanged.
- A single `Microsoft.Insights/workbookTemplates` resource with literal `properties.templateData`
  or a supported literal-variable reference.

Extraction is entirely local. General ARM evaluation, parameter substitution, chained/dynamic
variables and nested deployments are deliberately unsupported and fail explicitly.
For example, use the native
[Synack workbook](../Workbooks/Synack%20Vulnerabilities/SynackVulnerabilities.workbook)
instead of its dynamically rewritten ARM template. Ambiguous templates with multiple workbook
resources must also use a separate native workbook. No template is deployed to extract its content.
The report's SHA-256 covers the extracted workbook source, with BOM removed and CRLF normalized,
not the enclosing ARM template.

### Confirm scope before live testing

Follow the [browser-validation skill](../.github/skills/validate-workbook-browser/SKILL.md).
Ask which Azure tenant and non-production subscription scopes the user wants, and whether screenshots
would help. **Pause and wait for explicit tenant selection and per-run confirmation, including in
autopilot.** Do not choose the current, default or previously used directory, request credentials,
or automate sign-in. Offline generation and synthetic tests need no Azure access.

After confirmation, the user signs into that directory themselves. Use only trusted templates and
Reader permissions at the agreed scopes: rendering real workbooks can execute queries and incur costs.
In the current **English-language React workbook view**, open a **new empty unsaved workbook**,
open **Advanced Editor**, and leave its default empty JSON in place. Do not paste the template first.

The runner verifies all parenthesized directory-GUID candidates in portal account-menu metadata,
not the first GUID in a display name. Conflicting candidates fail closed. It rechecks before import,
Apply, leaving edit mode, tab changes, parameter actions and screenshots. Missing, ambiguous or mismatched
tenant evidence pauses the run; it never switches tenants or automates sign-in after a session reset.
It refuses saved/non-empty workbooks and
selects only the Monaco model bound to the visible editor. It never clicks Save or ARM action links.
Tenant IDs, account details and record values are not included in its report.

### Local Mocha/CDP runner

After the user has selected and confirmed a tenant, start a dedicated Chromium-based browser with
a separate profile outside this repository and a loopback-only debugging port. For example:

```powershell
& "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 --user-data-dir="$env:LOCALAPPDATA\WorkbookBrowserValidation"
```

Prepare sign-in and the empty Advanced Editor in that browser, then run:

```powershell
$env:WORKBOOK_BROWSER_TEMPLATE = ".script\workbook-browser\fixtures\Smoke.workbook"
$env:WORKBOOK_BROWSER_CHECKS = ".script\workbook-browser\fixtures\smoke-checks.json"
$env:WORKBOOK_BROWSER_CDP_ENDPOINT = "http://127.0.0.1:9222"
$env:WORKBOOK_BROWSER_TENANT_ID = "<user-selected-tenant-guid>"
$env:WORKBOOK_BROWSER_TENANT_CONFIRMED = "true"
npm run test:browser
```

The example uses only static text and inline JSON; it does not query tenant telemetry.
Use another native workbook or supported ARM template by changing `WORKBOOK_BROWSER_TEMPLATE`;
the checks file is optional. Exactly one eligible portal page must be open. Missing configuration
is a failure, not a skipped/passing test. Only credential-free loopback HTTP CDP endpoints are accepted.
The client disconnects afterward without creating or closing browser contexts. Close the dedicated
browser and clear private per-run variables when finished. Do not expose CDP or use your normal profile.

### Existing Playwright or MCP browser

For a tool that already supplies a Playwright `page`, generate a portable function instead of opening
a debugging port:

```powershell
New-Item -ItemType Directory -Force .playwright-mcp | Out-Null
npm run test:browser:script -- --workbook ".script\workbook-browser\fixtures\Smoke.workbook" --checks ".script\workbook-browser\fixtures\smoke-checks.json" --tenant "<user-selected-tenant-guid>" --confirm-tenant --output ".playwright-mcp\workbook-check.js"
```

Run the generated `async (page) => { ... }` function in the tool's selected tab after preparing
the empty Advanced Editor. Use the tool's filename input where available. The function has no Node
imports; hosts with short timeouts should use the local Mocha runner for longer validations.

Generation can run offline without tenant arguments, but executing that script pauses before browser
access until tenant selection is confirmed. `--tenant` alone is not confirmation. Changing a tenant
through CLI/environment overrides revokes previous confirmation unless explicitly confirmed again.
Existing output files are never overwritten. Generated scripts contain workbook data and checks, not
authentication state; keep them private and remove your own generated files afterward.
The local `.playwright-mcp/` output folder is ignored by Git.

### Contract coverage

The [example checks](./workbook-browser/fixtures/smoke-checks.json) exercise two tabs, an eager two-row
table, and one parameter action revealing both a two-row table and text with the producer hidden afterward.
Supported options are:

- `tabs`: exact primary tab labels in order. Static labels are inferred; parameterized labels need
  explicit expectations. All declared tabsets must use parameter links, not external/ARM navigation.
- `timeout`: per-operation timeout, 1 to 120000 milliseconds; default 30000.
- `tenant`: a private per-run `{ "id": "<user-selected-tenant-guid>", "confirmed": true }` object,
  preferably supplied through CLI/environment rather than a committed checks file.
- `panels`: eager/initially visible panel contracts with `heading` and optional `tab` (defaults to the
  first primary tab). No trigger or workbook-specific action is invented for these checks.
- `deferred`: an array with `trigger` (one unique parameter-link label), `heading` (one content heading),
  optional `tab` (defaults to the first primary tab), and optional `hideTriggerAfterLoad`.
- `minRows`, `maxRows`, `columns`: optional fields on each panel or deferred check for exact ordered column
  display labels and inclusive row bounds. Counts use `aria-rowcount` minus the header, not virtualized
  DOM rows. In grouped grids, these are the current ARIA view entries, not unique resources or the full
  backend result set. A missing result grid or unreliable count fails; no-data is not proof of health.
- `allowTruncated`: a boolean on a panel/deferred check, default `false`. A recognized portal result-limit
  warning fails the contract unless explicitly accepted. Accepted truncation is reported with aggregate
  returned/total counts; it does not qualify a complete inventory.
- `cells`: optional assertions on specifically rendered cells, each with a zero-based rendered data-row
  index, exact `column` label, and `equals` display text. A virtualized/unmounted row is not silently
  replaced by another row. Captured-cell references are available only inside interaction scenarios.

For example, validate an existing grid without requiring a deferred-load button:

```json
{
  "panels": [
    { "heading": "Summary table", "minRows": 1, "columns": ["Label", "Count"] }
  ]
}
```

Each requested panel must become visible and quiet for 250 milliseconds within the operation timeout.
The observer waits through initial loading, detects the renderer's `Error loading item` state, and
refuses missing/ambiguous grids, replaced panels and sustained refresh churn. Only aggregate counts
and requested labels are reported; record values and raw DOM/console output are not collected.
Panel checks run before that tab's screenshot so opted-in captures follow the requested readiness checks.

Checks sharing a tab and trigger are grouped: all headings must be unmounted before the ready trigger
is activated once, then every requested panel contract is checked. A self-hiding producer needs its
visibility parameter declared global before the producer.

Each deferred action also retains the verified type-11 producer's unique `name` and the link's
unique `id`. The renderer must expose those exact values as unique DOM IDs, with the control
inside its visible producer. Missing, hidden, ambiguous or differently mapped producers/links
stop the check; there is no frame-wide label fallback. The matched control must have the
requested accessible label and cannot have an external/action `href`. Renderer versions that
do not expose this identity contract are unsupported for automatic deferred activation.

The runner explicitly focuses enabled controls before native Enter-key activation and confirms tab selection.
Visibility waits, enabled-state checks, focus, keyboard activation and deferred-control scrolling all
receive the configured per-operation timeout, including in the generated runner.
There is no forced click, mouse fallback or automatic action retry if keyboard activation fails.
This tests the accessible path, not mouse hit testing. Nested-tab interactions, filters, graphs,
query correctness, resource coverage and arbitrary workflows still need scenario-specific tests.

Planning also returns nonfatal `sourceDiagnostics`: `non-string-threshold` flags formatter values
that can crash the string-based portal renderer, and `global-input-export-cycle-risk` flags a query
that exports a global parameter it directly consumes. These are review risks, not a complete KQL or
dependency analysis; intentional global brushing can be valid. Diagnostics contain codes/item indexes,
not source values, and never rewrite source or autofix risks. Optional scenario instrumentation is
a separate explicitly requested operation, reported with its own imported-source hash.

The JSON report includes the normalized source hash, visited labels, eager/deferred contract results,
source diagnostics and aggregate counts, with explicit coverage limits and `workbookSaved: false`.
`coverageLevel: "smoke-only"` means no query-data contract was qualified; successful source import and
tab navigation must not be reported as healthy queries or live qualification. `requested-data-contracts`
still describes only the explicit contracts, not workbook-wide certification. Distinguish an isolated
synthetic browser run from an actual authenticated portal run, and report which exact source revision
was tested if the workbook changes afterward. Review even labels before
publishing summaries; never publish generated scripts or browser profiles as test evidence.

### Interaction scenarios and needs-closer-look items

Use the telemetry-free [interaction workbook](./workbook-browser/fixtures/Interactions.workbook) and
[scenario profile](./workbook-browser/fixtures/interaction-checks.json) as a starting point. The profile
tests row drill-through, a filter that preserves selected scope, and a reset that preserves the filter.
No workbook name, parameter name, resource type, tenant, or business value is built into the runner.

An interactive workbook without scenario contracts is reported as
`interaction-scenarios-not-configured`; tab or panel smoke does not close that gap.
For each pending review item:

1. Define a non-sensitive scenario/step `id` and the specific source item names to exercise.
2. Select a row by an explicit rendered index or unique column match. `selectRow` requires a query
   with declared parameter exports and activates only its native selection checkbox, not a row's
   links. `expandRow` supports an explicitly selected collapsed group before selecting a leaf.
3. Use `capture` to retain that row's displayed cells privately. References such as
   `{ "$cell": { "capture": "picked", "column": "Key" } }` compare later results to the selected row;
   they are display values, not hidden backend fields or resource IDs.
4. Assert expected tab changes, runtime parameter values, and meaningful result panels/cells.
   JSON parameters support exact `equals`, nonempty partial-object `contains`, or `unchanged`.
   A partial object assertion proves only the selected keys. Supply private per-run expectations for
   business-relevant hidden identifiers; do not infer them from friendly display names.
5. Apply `setParameter` to an explicit single-value text/dropdown parameter. Assert the changed
   parameter and that the selected scope remains unchanged. Resource/account/time-scope pickers,
   passwords, arbitrary selectors/scripts, external links, and ARM actions are not automated.
6. Invoke `parameterLink` by its verified source item and link ID for reset behavior. Assert the
   cleared target and preserved unrelated filters, plus the resulting view/data. Do not treat
   clicking a reset button or seeing an empty table as proof of correct parameter propagation.

Scenarios require explicit `instrumentation: true`. Hidden values are observed through passive
read-only base64 probes placed in a separate **unsaved test copy**, with source-boundary markers
around declared action producers. Parameter definitions, defaults, queries, exports and action links
are not changed. Production files are never rewritten. The report retains the original `sourceSha256`
and separate `importedSourceSha256`; instrumented layout is not a claim of exact published-layout
qualification. Recheck unmodified-source panels/layout separately against the same original hash.

The instrumentation proves source ownership even when a renderer generates unrelated step DOM IDs:
controls must be uniquely between that source item's paired boundary headings. No frame-wide label
fallback is used. Dropdown options must belong to the verified picker's `aria-controls`/`aria-owns`
list. Missing, ambiguous, unsupported, or replaced bindings stop execution. Passive readiness polling
is bounded; actions are not retried. Private comparison state and temporary action markers are
cleaned after execution; passive probes remain in the unsaved copy until it is discarded.
base64 is **not encryption or redaction**: keep the test copy and generated script
private, never save it, and discard it after testing. Instrumented captures support auto redaction
only, to avoid exposing diagnostic values through selectively redacted/raw screenshots.

Useful profile fields:

| Field | Meaning |
| --- | --- |
| `instrumentation` | Must explicitly be `true` for scenarios. Ordinary runs still import exact unmodified source. |
| `evidenceMode` | Caller-declared `synthetic`, `authenticated`, or default `unspecified`; never inferred from a portal-looking URL. |
| `scenarios[].requiresAuthenticated` | Defaults to `true`; keep it true for pending Azure portal review items. |
| `scenarios[].panelDefaults` | Shared `minRows`, `maxRows`, `columns`, and `allowTruncated` defaults for that scenario's result panels; explicit step-panel values override them. |
| `scenarios[].tab` / `steps[].tab` | Explicit setup navigation within the primary source tabset. |
| `steps[].action` | `selectRow`, `expandRow`, `setParameter`, or `parameterLink`, with a source `item` and type-specific fields. |
| `steps[].expect.tab` | Observe the resulting selected tab; the runner does not navigate there to manufacture a pass. |
| `steps[].expect.parameters` | Identify source `item`/`parameter`, optional `parse: "json"`, and one comparison. |
| `steps[].expect.panels` | Current-view panel/grid/cell contracts; no implicit tab navigation. |

Set evidence mode per run with `--evidence-mode authenticated` or
`WORKBOOK_BROWSER_EVIDENCE_MODE=authenticated` **only** for a real, user-confirmed signed-in portal
session and agreed scopes. Never label mocked/intercepted browser data as authenticated evidence.
Mode does not grant consent or bypass tenant verification. The supplied profile defaults to synthetic
evidence; executing its UI assertions successfully leaves all three authenticated review items pending.

Reports distinguish execution from qualification:

- `interactionScenarios` contains per-step statuses and assertion counts, never captured row values,
  parameter payloads, expected identifiers, or raw DOM/error details.
  Each step retains safe `panelResults` (grid/column counts, checked labels and any accepted
  returned/total truncation), so accepting a limit never discards that qualification boundary.
- `needsCloserLook` retains unexecuted, failed, unsupported, or still-authentication-dependent items.
  Generation reports `not-run`; missing consent/browser setup reports `blocked`, not a pass.
- `reviewState: "needs-closer-look"` can remain even when synthetic UI checks pass. Only matching,
  actually authenticated instrumented assertions can receive `authenticated-instrumented` qualification.
  That still covers only explicit assertions, not exact production layout or every workflow.
- On the first unsuccessful step, later actions are `not-run`. Failed interaction runs throw with an
  aggregate `error.report`; CLI/generated runners print that report and still fail rather than
  returning success-shaped fallbacks.

Parameter assertions require a bounded 250 ms matching-observation window, not the first matching
read. Unchanged baselines are captured stably before the action and are never overwritten by later
checks. All assertions are revalidated against those original baselines after panel readiness and
again after capture. Delayed filter/scope resets therefore fail rather than inheriting an earlier
transient match. Insufficient timeouts remain failures; they do not shorten the required stable window.

To close a runtime review gap, retain exact original/imported hashes and revisions, fresh confirmed
tenant evidence, passing scenario/parameter/rendered-cell contracts, and any remaining limits.
Do not clear an authenticated pending item using unit tests, synthetic results, generation alone, or
a previous source version. Expired sessions pause for user sign-in; the runner never changes tenants.

### Optional local screenshots

Screenshots are disabled by default. After separate user approval, enable auto-redacted local captures
with `--screenshots "C:\private-evidence\workbook-check"` for the generator, or
`WORKBOOK_BROWSER_SCREENSHOTS` for Mocha. A checks file can also contain:

```json
{
  "screenshots": {
    "directory": ".playwright-mcp/screenshots",
    "maskSelectors": ["[data-sensitive-context]"]
  }
}
```

`auto` is the default redaction mode. It masks data cells, inputs, non-contract text and media before
capture, retaining only exact contract labels. Element cropping alone cannot exclude overlapping
portal/account chrome: every capture also temporarily isolates the workbook iframe from the parent
document's paints, including existing and newly added overlays and top-layer controls.
The isolation is monitored throughout capture and restored in `finally`, including on capture errors.
Blocked isolation and unsupported parent shadow-root/nested-frame environments refuse capture rather
than falling back to an exposed image. This parent isolation also applies to selectively redacted and
explicitly approved unredacted workbook captures.
Capture is also bound to the original inner document/body and verifies document identity, mask
markers, exact redaction CSS and a computed-style probe before and after the image is written.
Iframe reloads, replacement bodies/documents or lost masks fail the capture even when parent
isolation remains valid. Dispose of any local image already written by a failed capture immediately;
do not publish or reuse it. Cleanup uses the bound handles, not locators that can retarget a replacement
document, and always attempts parent restoration and handle disposal.
Additional selectors add masks and must match at every capture stage. Redaction uses DOM CSS with a
computed-style probe; blocked redaction fails capture without an unmasked fallback. Temporary
markers/styles are removed even after errors. Output paths must be local, without URLs, network paths
or parent traversal. Conservative masking is not guaranteed anonymization.

If auto masks hide too much, ask the user to choose, never reduce masking automatically:

| `screenshots.redaction` | Behavior |
| --- | --- |
| `auto` | Conservative automatic masks plus extra selected masks. |
| `manual` | Only user-reviewed `maskSelectors`. |
| `ai-assisted` | Only approved selectors proposed through authorized/local inspection; no AI service is called. |
| `none` | Private unredacted capture for local manual editing/redaction. |

Every non-auto mode requires specific sensitive-capture approval and `allowSensitiveCapture: true`.
Manual/AI-assisted modes require reviewed selectors; `none` refuses selectors instead of ignoring them.
CLI equivalents are `--redaction <mode> --allow-sensitive-capture`; Mocha uses
`WORKBOOK_BROWSER_REDACTION` and `WORKBOOK_BROWSER_ALLOW_SENSITIVE_CAPTURE=true`.
Approval environment values must be exactly `true` or `false`. Negative/explicit-false CLI flags revoke
prior approvals. Keep tenant IDs and approval choices out of committed configuration.

All images remain local, `reviewRequired: true` and `publicationApproved: false`.
Nothing is uploaded or shared automatically. Do not send sensitive screenshots to third-party AI
services. Review every final image, including manually edited/redacted images, before sharing, and
remove only your own private intermediate files when finished.
