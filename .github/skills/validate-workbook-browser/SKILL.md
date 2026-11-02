---
name: validate-workbook-browser
description: 'Validate Microsoft Defender for Cloud Azure Workbooks with Playwright or MCP. Use for eager/deferred panels, drill-through/filter/reset scenarios, hidden parameter propagation, needs-closer-look review gaps, Azure tenant selection, screenshots, and redaction. Requires fresh tenant confirmation; synthetic checks never qualify pending authenticated portal validation.'
---

# Validate a workbook in the browser

Follow the [testing guide](../../../.script/ReadMe.md#workbook-browser-validation-opt-in) and use the shared [validator](../../../.script/workbook-browser/workbookBrowserValidator.js).

## Confirm the tenant before live work

1. Ask the user **which Azure tenant to sign in to**, and which non-production subscription scopes to use. Use the host's structured question tool when available. Do not ask for passwords, tokens, or other credentials.
2. **Pause the live workflow and wait for the user to select and confirm the tenant.** This applies in autopilot too.
   A missing, declined, cancelled, or unavailable response is not permission to pick the current, default,
   previously used, or first available tenant. Do not navigate to sign-in, switch accounts, import a workbook,
   query Azure, or capture portal screenshots while waiting. Offline code and synthetic tests can continue.
3. Have the user sign in or switch directories themselves. Set the selected tenant GUID and confirmation only after their response, using private per-run arguments or environment variables. Do not commit tenant information, reuse an old confirmation for a new run, or echo account details.
4. The runner must unambiguously match the portal account-menu tenant to that selection before import, Apply, leaving edit mode, navigation, parameter actions, and screenshots. If identity changes, the session resets, or the check cannot verify the tenant, pause for the user; never automate sign-in, bypass the check, or select another tenant.

## Offer screenshot and redaction choices

Ask whether screenshots would help. Screenshots remain disabled unless requested; when enabled, **auto redaction is the default**.

If auto redaction hides too much, offer:

- **Auto:** conservative automatic masks plus any extra selected masks.
- **Manual masks:** the user selects CSS regions to hide before capture; other content may remain visible.
- **AI-assisted mask selection:** use authorized/local inspection to propose CSS masks, then obtain the user's approval. The validator applies those selectors; it does not call an AI service or send images anywhere.
- **Unredacted local capture:** explicitly disable masks only after warning about sensitive content and receiving specific approval. The user can edit/redact the local image manually afterward.

Manual, AI-assisted, and unredacted modes require explicit approval for potentially sensitive capture. Never turn masking off automatically after an error or because the result is too dark. Do not upload unredacted content to third-party AI services. Keep all captures local and private, and review the final edited/redacted image with the user before any sharing.

## Run and report

1. Use a new empty unsaved workbook's Advanced Editor. Do not replace an existing draft or save/provision an Azure workbook.
   Native `.workbook` and Notebook/1.0 `.json` files are supported, along with single-workbook ARM templates using literal serialized data or supported literal-variable expressions. Unsupported ARM expressions must fail; use the corresponding native workbook instead of deploying or evaluating the template.
2. Use `npm run test:browser` for a dedicated local CDP browser or generate the portable MCP runner with `npm run test:browser:script`.
3. Run only the agreed checks and scopes. Observe all approval, no-data, and redaction failures; do not convert them into passes.
   Use `panels` contracts for already-visible query results; do not invent a deferred action when none exists.
   Review nonfatal source diagnostics for incompatible threshold types and global input/export feedback.
   Import/tab smoke is not query validation; request explicit grid labels/row bounds where data matters.
   Result truncation fails contracts unless explicitly accepted, and accepted limits must remain in the report.
   Deferred actions require unique source producer/link identities mapped to DOM IDs. If that mapping is unavailable,
   stop instead of retrying against same-named controls elsewhere in the frame.
   For runtime interaction gaps, follow the scenario procedure below; import/tab smoke is not a substitute.
4. Report the exact tested source hash/revision, smoke-only versus requested-data-contract coverage, aggregate counts, selected redaction mode, and limits. Distinguish synthetic browser tests from actual authenticated portal execution; do not carry a live pass forward to a changed source. Do not include tenant IDs, account identities, record values, or raw screenshots in PR comments.
   Parent-document overlays must remain isolated throughout capture; cropping to an iframe is insufficient.
   If parent isolation or inner redaction fails, stop without an exposed fallback.
   Inner-document reload/replacement invalidates capture even if the outer iframe remains.
   Immediately discard any image already written by a failed capture; never publish it as auto-redacted evidence.
5. Images remain `reviewRequired` and not approved for publication, even in auto mode. No automatic upload is permitted. Remove task-owned intermediate images and private per-run configuration when finished.

## Qualify needs-closer-look runtime interactions

1. Turn each runtime review gap into explicit, non-sensitive scenario/step IDs in a private checks profile.
   Use the [generic scenario profile](../../../.script/workbook-browser/fixtures/interaction-checks.json)
   and [telemetry-free workbook](../../../.script/workbook-browser/fixtures/Interactions.workbook) as examples.
   Discover the reviewed source's query exports, parameter declarations, and reset link IDs; never hard-code
   a tenant, workbook name, resource type, or default scope in the validator.
2. For drill-through, explicitly select/expand a source row, capture displayed cells privately, and assert
   the resulting tab, exported context fields, and actual result cells. Friendly names do not prove hidden
   IDs; use agreed private expectations for relevant fields. Partial JSON assertions prove only those keys.
3. For filtering, assert the changed parameter value, preserved context and rendered results.
   For reset, assert the cleared target, unchanged unrelated filters, and resulting view/data.
   Missing parameter/control hooks are needs-closer-look items, never inferred successful propagation.
4. Obtain explicit opt-in via `instrumentation: true` for a separate unsaved test copy with passive source
   boundaries/private Base64 probes. Keep production files, query/export definitions, defaults, and scopes
   unchanged. Record original and imported hashes separately. Never save or publish the diagnostic copy.
   Base64 is not redaction; instrumented screenshots allow auto redaction only.
5. Declare `evidenceMode` honestly per run. Use `authenticated` only for an actual confirmed Azure session,
   never a mock/intercepted page. Keep `requiresAuthenticated: true` for Azure portal review gaps.
   Missing fresh confirmation, expired sign-in, wrong tenant, or unavailable browser pauses the run.
6. Inspect `interactionScenarios`, per-step assertion counts, `reviewState`, and `needsCloserLook`, including
   on thrown `error.report`. Unit/synthetic passes, generation, and not-run steps cannot clear authenticated
   pending items. Failed steps stop later actions; there is no action retry, URL fallback, or success-shaped
   conversion. Report aggregate status/codes, not private cells, parameter payloads, identifiers, or raw errors.
7. Close only the specifically asserted behavior with matching tested revisions/hashes and actual
   authenticated-instrumented evidence. Recheck unmodified-source layout separately. If the published source
   changes, keep the affected item pending until revalidated; do not carry a previous live pass forward.
