const assert = require('chai').assert;
const { rejects } = require('node:assert/strict');
const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const vm = require('vm');
const { spawnSync } = require('child_process');
const {
    isAzurePortalUrl,
    normalizeTenantSelection,
    requireConfirmedTenant,
    verifySelectedTenant,
    normalizeScreenshotOptions,
    createValidationPlan,
    markScreenshotMasks,
    screenshotRedactionStyle,
    applyScreenshotRedaction,
    isolateScreenshotFrame,
    verifyScreenshotIsolation,
    restoreScreenshotIsolation,
    bindCaptureDocument,
    verifyCaptureDocument,
    clearCaptureDocument,
    captureMaskedScreenshot,
    captureWorkbookScreenshot,
    readGridSummary,
    waitForPanelReady,
    validatePanelContract,
    activateWorkbookControl,
    validateWorkbookInBrowser: validateWithExplicitTenant,
    loadValidationInput,
    validateCdpEndpoint,
    createPlaywrightScript
} = require('../../workbook-browser/workbookBrowserValidator');

const browserDirectory = path.resolve(__dirname, '..', '..', 'workbook-browser');
const fixturePath = path.join(browserDirectory, 'fixtures', 'Smoke.workbook');
const checksPath = path.join(browserDirectory, 'fixtures', 'smoke-checks.json');
const source = fs.readFileSync(fixturePath, 'utf8');
const checks = JSON.parse(fs.readFileSync(checksPath, 'utf8'));
const emptySource = JSON.stringify({ version: 'Notebook/1.0', items: [] });
const testTenant = { id: '11111111-2222-3333-4444-555555555555', confirmed: true };
const otherTenantId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
const fixtureProducer = JSON.parse(source).items.find(item => item.name === 'browser_fixture_group').content.items[0];
const fixtureIdentity = { itemName: fixtureProducer.name, linkId: fixtureProducer.content.links[0].id };

function validateWorkbookInBrowser(page, workbookSource, options = {}) {
    return validateWithExplicitTenant(page, workbookSource, { tenant: testTenant, ...options });
}

function accountPage(ids = [testTenant.id]) {
    return {
        url: () => 'https://portal.azure.com/#home',
        getByRole(role) {
            assert.equal(role, 'button');
            return {
                count: async () => 1,
                locator(selector) {
                    assert.equal(selector, '[title]');
                    return {
                        evaluateAll: async callback => callback(ids.map(id => ({
                            getAttribute: () => `Name: Synthetic account Directory: Synthetic directory (${id}) Domain: example.invalid`
                        })))
                    };
                }
            };
        }
    };
}

function changedSource(change) {
    const workbook = JSON.parse(source);
    change(workbook);
    return JSON.stringify(workbook);
}

function editorPage(existingSource, editorCount = 1, unsaved = true) {
    const state = { value: existingSource, writes: 0, clicks: [], backgroundModelAccess: 0, readingToolbarConfirmed: false };
    const inputElement = {};
    const model = {
        getValue: () => state.value,
        setValue(value) {
            state.writes++;
            state.value = value;
        }
    };
    const backgroundEditor = {
        getDomNode: () => ({ contains: () => false }),
        getModel() {
            state.backgroundModelAccess++;
            throw new Error('An unrelated cached editor must not be accessed.');
        }
    };
    const editors = [backgroundEditor, ...Array.from({ length: editorCount }, () => ({
        getDomNode: () => ({ contains: element => element === inputElement }),
        getModel: () => model
    }))];
    const frame = {
        getByRole(role, options = {}) {
            if (role === 'menubar') {
                assert.match('Workbooks toolbar. Use left and right arrow keys to navigate between commands', options.name);
                return {
                    getByRole(role, options) {
                        assert.equal(role, 'menuitem');
                        assert.equal(options.name, 'Edit');
                        return { async waitFor() { state.readingToolbarConfirmed = true; } };
                    }
                };
            }
            if (role === 'menuitem' && options.name === 'Edit') {
                throw new Error('Unscoped Edit also matches transient step-level commands.');
            }
            return {
                async waitFor() {},
                async isEnabled() { return true; },
                async focus() {},
                async press(key) { assert.equal(key, 'Enter'); state.clicks.push(options.name); },
                first() { return this; },
                async evaluate(callback, argument) {
                    const evaluate = vm.runInNewContext(`(${callback.toString()})`, {
                        globalThis: { monaco: { editor: {
                            getModels() { throw new Error('Do not select a model from the global cache.'); },
                            getEditors: () => editors
                        } } },
                        crypto: crypto.webcrypto,
                        TextEncoder
                    });
                    return evaluate(inputElement, argument);
                }
            };
        }
    };
    const page = {
        url: () => 'https://portal.azure.com/#home',
        getByRole: (role, options) => role === 'button' ? accountPage().getByRole(role, options) :
            ({ count: async () => unsaved ? 1 : 0 }),
        locator: () => ({ contentFrame: () => frame })
    };
    return { page, state, frame };
}

function bindParameterProducer(editor, trigger, {
    ownerCount = 1, linkCount = 1, visible = true, contained = true, navigational = false
} = {}) {
    const ownerSelector = `[id=${JSON.stringify(fixtureIdentity.itemName)}]`;
    const linkSelector = `[id=${JSON.stringify(fixtureIdentity.linkId)}]`;
    const controlSelector = `${linkSelector}:not([href]),${linkSelector}[href=""],${linkSelector}[href="#"]`;
    const roles = { or() { return this; } };
    const owner = {
        async waitFor(options) {
            assert.equal(options.state, 'visible');
            assert.isNumber(options.timeout);
            if (!visible || !ownerCount) throw new Error('Verified parameter producer is unavailable.');
        },
        count: async () => ownerCount,
        locator(selector) {
            assert.equal(selector, controlSelector);
            return trigger;
        },
        getByRole(role, options) {
            assert.include(['menuitem', 'button', 'link'], role);
            assert.deepEqual(options, { name: 'Show details', exact: true, includeHidden: true });
            return roles;
        }
    };
    trigger.and = candidate => {
        assert.strictEqual(candidate, roles);
        return trigger;
    };
    trigger.count = async () => contained && !navigational ? 1 : 0;
    editor.frame.locator = selector => {
        if (selector === ownerSelector) return owner;
        assert.equal(selector, linkSelector);
        return { count: async () => linkCount };
    };
}

function sharedDeferredEditor(initialHeadings = []) {
    const workbook = JSON.parse(source);
    const group = workbook.items.find(item => item.name === 'browser_fixture_group');
    delete group.conditionalVisibility;
    workbook.items = [workbook.items[0], group];
    const editor = editorPage(emptySource);
    const original = editor.frame.getByRole.bind(editor.frame);
    let loaded = false;
    let clicks = 0;
    const trigger = {
        or() { return this; },
        async waitFor(options) {
            if (options.state === 'hidden') assert.isTrue(loaded);
        },
        async isEnabled() { return true; },
        async focus() {},
        async scrollIntoViewIfNeeded() {},
        async press(key) {
            assert.equal(key, 'Enter');
            clicks++;
            loaded = true;
        }
    };
    editor.frame.getByRole = (role, options = {}) => {
        if (options.name === 'Show details') return trigger;
        if (role === 'heading' && ['Deferred table', 'Loaded details'].includes(options.name)) {
            return {
                count: async () => loaded || initialHeadings.includes(options.name) ? 1 : 0,
                async waitFor() { assert.isTrue(loaded); },
                locator: () => ({ count: async () => 1, evaluate: async () => ({ settled: true }) })
            };
        }
        return original(role, options);
    };
    bindParameterProducer(editor, trigger);
    return { ...editor, source: JSON.stringify(workbook), trigger, triggerClicks: () => clicks };
}

function deferredGridEditor({ rows = 2, columns = ['Label', 'Count'], available = true } = {}) {
    const editor = sharedDeferredEditor();
    const original = editor.frame.getByRole.bind(editor.frame);
    editor.frame.getByRole = (role, options = {}) => {
        const control = original(role, options);
        if (role !== 'heading' || options.name !== 'Deferred table') return control;
        return {
            ...control,
            locator: () => ({
                count: async () => 1,
                async evaluate() {
                    if (!available) throw new Error('No query grid is available.');
                    return { settled: true };
                },
                getByRole: () => ({
                    async waitFor() {
                        if (!available) throw new Error('No query grid is available.');
                    },
                    evaluate: async callback => callback({
                        getAttribute: () => String(rows + 1),
                        querySelectorAll: () => columns.map(textContent => ({ textContent }))
                    })
                })
            })
        };
    };
    return editor;
}

function gridContract(overrides = {}) {
    const contract = { ...checks.deferred[0], ...overrides };
    delete contract.tab;
    return { deferred: [contract] };
}

describe('Validating browser validator contracts...', () => {
    it('uses a valid fixture containing only inline JSON, text, and parameter actions', () => {
        const workbook = JSON.parse(source);
        assert.doesNotThrow(() => createValidationPlan(source, checks));
        const items = [];
        function collect(entries) {
            for (const item of entries) {
                items.push(item);
                if (item.type === 12) collect(item.content.items);
            }
        }
        collect(workbook.items);
        assert.isTrue(items.every(item => [1, 3, 9, 11, 12].includes(item.type)));
        assert.isTrue(items.filter(item => item.type === 3).every(item => item.content.queryType === 8));
        assert.isTrue(items.filter(item => item.type === 11)
            .every(item => item.content.links.every(link => link.linkTarget === 'parameter')));
        const group = workbook.items.find(item => item.name === 'browser_fixture_group');
        const query = group.content.items.find(item => item.type === 3);
        assert.equal(query.content.queryType, 8);
        const envelope = JSON.parse(query.content.query);
        assert.equal(envelope.version, '1.0.0');
        assert.deepEqual(JSON.parse(envelope.content), [{ Label: 'First', Count: 1 }, { Label: 'Second', Count: 2 }]);
        assert.isNull(envelope.transformers);
    });

    it('normalizes a BOM and Windows line endings without changing the source content', () => {
        const normalized = source.replace(/\r\n/g, '\n');
        assert.equal(createValidationPlan('\uFEFF' + normalized.replace(/\n/g, '\r\n'), checks).source, normalized);
    });

    it('infers primary tab labels and scopes requested grid assertions', () => {
        const plan = createValidationPlan(source, { deferred: checks.deferred });
        assert.deepEqual(plan.tabs, ['Overview', 'Details']);
        assert.equal(plan.itemCount, 9);
        assert.equal(plan.deferred[0].tab, 'Overview');
        assert.equal(plan.deferred[0].minRows, 2);
        assert.equal(plan.deferred[0].maxRows, 2);
        assert.deepEqual(plan.deferred[0].columns, ['Label', 'Count']);
        assert.isFalse(plan.screenshots);
    });

    it('groups contracts by both tab and parameter-action trigger', () => {
        const plan = createValidationPlan(source, checks);
        assert.lengthOf(plan.deferredGroups, 1);
        assert.lengthOf(plan.deferredGroups[0].checks, 2);
        assert.deepEqual(plan.deferredGroups[0].checks.map(check => check.heading), ['Deferred table', 'Loaded details']);
        const differentTabs = createValidationPlan(source, {
            deferred: [...checks.deferred, { ...checks.deferred[0], tab: 'Details' }]
        });
        assert.deepEqual(differentTabs.deferredGroups.map(group => [group.tab, group.trigger, group.checks.length]),
            [['Overview', 'Show details', 2], ['Details', 'Show details', 1]]);
    });

    it('preserves the verified producer and link identities in each deferred group', () => {
        const plan = createValidationPlan(source, checks);
        assert.deepEqual(plan.deferred[0].producer, fixtureIdentity);
        assert.deepEqual(plan.deferredGroups[0].producer, fixtureIdentity);
    });

    it('requires unique producer names and link ids before browser interaction', () => {
        const invalid = [
            workbook => { workbook.items[3].content.items[0].name = ''; },
            workbook => { workbook.items[2].name = fixtureIdentity.itemName; },
            workbook => { delete workbook.items[3].content.items[0].content.links[0].id; },
            workbook => { workbook.items[1].content.links[0].id = fixtureIdentity.linkId; }
        ];
        for (const change of invalid) {
            assert.throws(() => createValidationPlan(changedSource(change), checks), /unique producer name and link id/);
        }
    });

    it('uses total ARIA rows and normalizes display headers without inspecting record values', () => {
        const grid = {
            getAttribute(name) {
                assert.equal(name, 'aria-rowcount');
                return '101';
            },
            querySelectorAll(selector) {
                assert.equal(selector, '[role="columnheader"]');
                return [{ textContent: '\uE001' }, { textContent: '\uE001  First\n column ' },
                    { textContent: ' Count\t total ' }];
            }
        };
        assert.deepEqual(readGridSummary(grid), { rows: 100, columns: ['First column', 'Count total'] });
    });

    it('rejects unknown virtualized row counts instead of falling back to rendered rows', () => {
        for (const count of [null, '', '-1', 'unknown', '0', '2.5', '9007199254740993']) {
            assert.throws(() => readGridSummary({ getAttribute: () => count }), /reliable aria-rowcount/);
        }
    });

    it('rejects invalid source and workbook versions before browser interaction', () => {
        assert.throws(() => createValidationPlan('not JSON'), /valid JSON/);
        assert.throws(() => createValidationPlan('{}'), /Notebook\/1.0/);
        assert.throws(() => createValidationPlan(''), /non-empty JSON/);
        assert.throws(() => createValidationPlan(JSON.stringify({ version: 'Notebook/1.0', items: {} })), /items array/);
    });

    it('rejects unknown options and mistyped contracts rather than silently ignoring them', () => {
        assert.throws(() => createValidationPlan(source, { headers: {} }), /unsupported option/);
        assert.throws(() => createValidationPlan(source, { deferred: {} }), /deferred must be an array/);
        assert.throws(() => createValidationPlan(source, { deferred: [{ ...checks.deferred[0], rowLimit: 2 }] }), /unsupported option/);
        assert.throws(() => createValidationPlan(source, { tabs: ['Overview', 'Overview'] }), /unique labels/);
        assert.throws(() => createValidationPlan(source, { deferred: [{ ...checks.deferred[0], tab: 'Unknown' }] }), /primary tabset/);
    });

    it('rejects invalid timeouts, row bounds, columns, and producer expectations', () => {
        for (const timeout of [0, -1, 120001, 0.5, '30000']) {
            assert.throws(() => createValidationPlan(source, { timeout }), /timeout must/);
        }
        for (const invalid of [{ minRows: -1 }, { maxRows: '2' }, { minRows: 3, maxRows: 2 },
            { columns: [] }, { hideTriggerAfterLoad: 'true' }]) {
            assert.throws(() => createValidationPlan(source, {
                deferred: [{ ...checks.deferred[0], ...invalid }]
            }));
        }
    });

    it('does not automatically navigate external or ARM-action tabs', () => {
        const unsafe = changedSource(workbook => { workbook.items[1].content.links[0].linkTarget = 'ArmAction'; });
        assert.throws(() => createValidationPlan(unsafe), /parameter links only/);
    });

    it('does not allow a secondary tabset to bypass the parameter-only navigation guard', () => {
        const unsafe = changedSource(workbook => {
            workbook.items.push({
                type: 11,
                name: 'additional_tabs',
                content: {
                    version: 'LinkItem/1.0',
                    style: 'tabs',
                    links: [{ linkLabel: 'External', linkTarget: 'url', cellValue: 'https://example.invalid/' }]
                }
            });
        });
        assert.throws(() => createValidationPlan(unsafe), /parameter links only/);
    });

    it('requires explicit expected tab labels for parameterized labels', () => {
        const dynamic = changedSource(workbook => { workbook.items[1].content.links[0].linkLabel = '{DynamicLabel}'; });
        assert.throws(() => createValidationPlan(dynamic), /explicit tabs/);
        assert.deepEqual(createValidationPlan(dynamic, { tabs: ['Overview', 'Details'] }).tabs, ['Overview', 'Details']);
    });

    it('restricts deferred triggers to unique parameter links', () => {
        const external = changedSource(workbook => {
            workbook.items[3].content.items[0].content.links[0].linkTarget = 'OpenBlade';
        });
        assert.throws(() => createValidationPlan(external, checks), /one parameter link/);
        const duplicate = changedSource(workbook => {
            const links = workbook.items[3].content.items[0].content.links;
            links.push({ ...links[0], id: 'another-link' });
        });
        assert.throws(() => createValidationPlan(duplicate, checks), /one parameter link/);
    });

    it('catches a self-referential visibility export without a preceding global', () => {
        const local = changedSource(workbook => { workbook.items[0].content.parameters[0].isGlobal = false; });
        assert.throws(() => createValidationPlan(local, checks), /global before the producer/);
        const late = changedSource(workbook => { workbook.items.push(workbook.items.shift()); });
        assert.throws(() => createValidationPlan(late, checks), /global before the producer/);
    });

    it('respects globals in ancestor scopes without leaking private sibling-group declarations', () => {
        const localGroup = changedSource(workbook => {
            const parameters = workbook.items.shift();
            workbook.items.find(item => item.name === 'browser_fixture_group').content.items.unshift(parameters);
        });
        assert.equal(createValidationPlan(localGroup, checks).deferred.length, checks.deferred.length);
        const privateGroup = changedSource(workbook => {
            const parameters = workbook.items.shift();
            workbook.items.unshift({
                type: 12, name: 'private_parameters',
                content: { version: 'NotebookGroup/1.0', groupType: 'editable', items: [parameters] }
            });
        });
        assert.throws(() => createValidationPlan(privateGroup, checks), /global before the producer/);
        const exported = JSON.parse(privateGroup);
        exported.items[0].content.exportParameters = true;
        assert.equal(createValidationPlan(JSON.stringify(exported), checks).deferred.length, checks.deferred.length);
    });

    it('does not require a self-hiding global when producer hiding was not requested', () => {
        const local = changedSource(workbook => { workbook.items[0].content.parameters[0].isGlobal = false; });
        const options = { deferred: [{ ...checks.deferred[0], hideTriggerAfterLoad: false }] };
        assert.equal(createValidationPlan(local, options).deferred.length, 1);
    });

    it('recognizes only official Azure portal HTTPS origins', () => {
        for (const url of ['https://portal.azure.com/#home', 'https://portal.azure.us/', 'https://portal.azure.cn/']) {
            assert.isTrue(isAzurePortalUrl(url));
        }
        for (const url of ['http://portal.azure.com/', 'https://portal.azure.com.example/', 'https://login.microsoftonline.com/']) {
            assert.isFalse(isAzurePortalUrl(url));
        }
    });

    it('accepts only credential-free loopback HTTP CDP endpoints', () => {
        for (const endpoint of ['http://localhost:9222', 'http://127.0.0.1:9222/', 'http://[::1]:9222/']) {
            assert.match(validateCdpEndpoint(endpoint), /^http:/);
        }
        for (const endpoint of [undefined, 'not a URL', 'https://remote.example/', 'http://user:token@localhost:9222/',
            'http://localhost:9222/?token=secret', 'http://localhost:9222/#secret', 'http://localhost:9222/private',
            'http://localhost:0/', 'http://127.0.0.1.example:9222/']) {
            assert.throws(() => validateCdpEndpoint(endpoint), /loopback HTTP/);
        }
    });

    it('requires explicit source configuration and validates profile input', () => {
        assert.throws(() => loadValidationInput(), /WORKBOOK_BROWSER_TEMPLATE/);
        assert.throws(() => loadValidationInput(fixturePath, ''), /checks file/);
        const input = loadValidationInput(fixturePath, checksPath);
        assert.equal(input.source, source);
        assert.deepEqual(input.options, checks);
    });

    it('rejects sign-in redirects without touching a browser control', async () => {
        await rejects(validateWorkbookInBrowser({ url: () => 'https://login.microsoftonline.com/' }, source, checks), /Sign in to Azure/);
    });

    it('refuses saved and non-empty workbook editors without modifying them', async () => {
        const saved = editorPage(emptySource, 1, false);
        await rejects(validateWorkbookInBrowser(saved.page, emptySource), /new empty unsaved workbook/);
        assert.equal(saved.state.writes, 0);
        const filled = editorPage(source);
        await rejects(validateWorkbookInBrowser(filled.page, emptySource), /not an empty workbook/);
        assert.equal(filled.state.writes, 0);
        assert.deepEqual(filled.state.clicks, []);
    });

    it('rejects missing or ambiguous active editors without replacing content', async () => {
        for (const count of [0, 2]) {
            const editor = editorPage(emptySource, count);
            await rejects(validateWorkbookInBrowser(editor.page, emptySource), /one active Advanced Editor/);
            assert.equal(editor.state.writes, 0);
        }
    });

    it('round-trips exact source without touching cached editors or invoking Save', async () => {
        const editor = editorPage(emptySource);
        const report = await validateWorkbookInBrowser(editor.page, emptySource);
        assert.equal(editor.state.writes, 1);
        assert.equal(editor.state.value, emptySource);
        assert.equal(editor.state.backgroundModelAccess, 0);
        assert.deepEqual(editor.state.clicks, ['Apply', 'Done Editing']);
        assert.equal(report.sourceSha256, crypto.createHash('sha256').update(emptySource).digest('hex'));
        assert.deepEqual(report.tabsVisited, []);
        assert.equal(report.dataContractsChecked, 0);
        assert.equal(report.coverageLevel, 'smoke-only');
        assert.include(report.coverage, 'tab navigation is not query validation');
        assert.deepEqual(report.panelChecks, []);
        assert.deepEqual(report.sourceDiagnostics, []);
        assert.equal(report.parameterActionsClicked, 0);
        assert.include(report.coverage, 'no-data is not proof of health');
        assert.isFalse(report.workbookSaved);
        assert.isTrue(report.tenantVerified);
        assert.notInclude(JSON.stringify(report), testTenant.id);
        assert.notInclude(JSON.stringify(report), emptySource);
        assert.isFalse(report.screenshots.enabled);
        assert.deepEqual(report.screenshots.captures, []);
        assert.include(report.screenshots.guidance, 'auto redaction by default');
    });

    it('waits for the workbook toolbar rather than transient step Edit commands', async () => {
        const editor = editorPage(emptySource);
        await validateWorkbookInBrowser(editor.page, emptySource);
        assert.isTrue(editor.state.readingToolbarConfirmed);
    });

    it('checks eager grids through the same shared and generated contract path without parameter actions', async () => {
        for (const generated of [false, true]) {
            const editor = editorPage(emptySource);
            const original = editor.frame.getByRole.bind(editor.frame);
            editor.frame.getByRole = (role, options = {}) => role === 'heading' && options.name === 'Eager table' ? {
                async waitFor() {},
                count: async () => 1,
                locator: () => ({
                    count: async () => 1,
                    evaluate: async () => ({ settled: true }),
                    getByRole: () => ({ evaluate: async callback => callback({
                        getAttribute: () => '3',
                        querySelectorAll: () => [{ textContent: 'Label' }, { textContent: 'Count' }]
                    }) })
                })
            } : original(role, options);
            const options = { tenant: testTenant, panels: [{ heading: 'Eager table', minRows: 2, maxRows: 2, columns: ['Label', 'Count'] }] };
            const run = generated ? vm.runInNewContext(`(${createPlaywrightScript(emptySource, options)})`) : null;
            const report = run ? await run(editor.page) : await validateWorkbookInBrowser(editor.page, emptySource, options);
            assert.equal(report.dataContractsChecked, 1);
            assert.equal(report.panelChecks[0].grid.rows, 2);
            assert.equal(report.parameterActionsClicked, 0);
            assert.equal(report.coverageLevel, 'requested-data-contracts');
            assert.deepEqual(editor.state.clicks, ['Apply', 'Done Editing']);
        }
    });

    it('reports static source risks without rewriting a workbook or upgrading smoke coverage', async () => {
        const editor = editorPage(emptySource);
        const workbook = JSON.stringify({ version: 'Notebook/1.0', items: [{
            type: 3, content: { gridSettings: { formatters: [{ formatOptions: {
                thresholdsGrid: [{ thresholdValue: 1 }]
            } }] } }
        }] });
        const report = await validateWorkbookInBrowser(editor.page, workbook);
        assert.equal(editor.state.value, workbook);
        assert.equal(report.sourceDiagnostics[0].code, 'non-string-threshold');
        assert.equal(report.coverageLevel, 'smoke-only');
    });

    it('activates tabs with the native keyboard path and confirms the selected state', async () => {
        const editor = editorPage(emptySource);
        const original = editor.frame.getByRole.bind(editor.frame);
        const activated = [];
        let selected;
        const tablist = {
            first() { return this; },
            async waitFor() {},
            getByRole(role, options = {}) {
                assert.equal(role, 'tab');
                if (!options.name) return { allTextContents: async () => ['Overview', 'Details'] };
                return {
                    async isEnabled() { return true; },
                    async focus() {},
                    async press(key) {
                        assert.equal(key, 'Enter');
                        selected = options.name;
                        activated.push(selected);
                    },
                    async waitFor() {
                        if (options.selected) assert.equal(selected, options.name);
                    }
                };
            }
        };
        editor.frame.getByRole = (role, options) => role === 'tablist' ? tablist : original(role, options);
        const report = await validateWorkbookInBrowser(editor.page, source);
        assert.deepEqual(activated, ['Overview', 'Details']);
        assert.deepEqual(report.tabsVisited, activated);
    });

    it('checks initial absence after the trigger becomes ready, before clicking it', async () => {
        const workbook = JSON.parse(source);
        const group = workbook.items.find(item => item.name === 'browser_fixture_group');
        delete group.conditionalVisibility;
        delete group.content.items.find(item => item.type === 3).conditionalVisibility;
        workbook.items = [workbook.items[0], group];
        const editor = editorPage(emptySource);
        const original = editor.frame.getByRole.bind(editor.frame);
        let mounted = false;
        let clicked = false;
        const trigger = {
            or() { return this; },
            async waitFor() { mounted = true; },
            async scrollIntoViewIfNeeded() {},
            async isEnabled() { return true; },
            async focus() {},
            async press() { clicked = true; }
        };
        editor.frame.getByRole = (role, options = {}) => {
            if (options.name === 'Show details') return trigger;
            if (role === 'heading' && options.name === 'Deferred table') {
                return { count: async () => mounted ? 1 : 0, async waitFor() {} };
            }
            return original(role, options);
        };
        bindParameterProducer(editor, trigger);
        await rejects(validateWorkbookInBrowser(editor.page, JSON.stringify(workbook), {
            deferred: [{ trigger: 'Show details', heading: 'Deferred table' }]
        }), /mounted before its trigger/);
        assert.isFalse(clicked);
    });

    it('never keyboard-activates a disabled workbook control', async () => {
        let activated = false;
        await rejects(activateWorkbookControl({
            async waitFor() {},
            isEnabled: async () => false,
            async press() { activated = true; }
        }, 30000), /control is disabled/);
        assert.isFalse(activated);
    });

    it('applies the configured timeout to visibility, enabled-state checks, and keyboard activation', async () => {
        const calls = [];
        await activateWorkbookControl({
            async waitFor(options) { calls.push(['visible', options]); },
            async isEnabled(options) { calls.push(['enabled', options]); return true; },
            async focus(options) { calls.push(['focus', options]); },
            async press(key, options) { calls.push([key, options]); }
        }, 75);
        assert.deepEqual(calls, [
            ['visible', { state: 'visible', timeout: 75 }],
            ['enabled', { timeout: 75 }],
            ['focus', { timeout: 75 }],
            ['Enter', { timeout: 75 }]
        ]);
    });

    function installUnrelatedControl(editor) {
        let activations = 0;
        const original = editor.frame.getByRole.bind(editor.frame);
        const unrelated = {
            or() { return this; },
            async waitFor() {},
            async scrollIntoViewIfNeeded() {},
            async isEnabled() { return true; },
            async focus() {},
            async press() { activations++; }
        };
        editor.frame.getByRole = (role, options = {}) => options.name === 'Show details' ?
            unrelated : original(role, options);
        return () => activations;
    }

    it('never activates a same-named frame-wide link when its verified parameter producer is hidden', async () => {
        const editor = sharedDeferredEditor();
        bindParameterProducer(editor, editor.trigger, { visible: false });
        const unrelatedActivations = installUnrelatedControl(editor);
        await rejects(validateWorkbookInBrowser(editor.page, editor.source, {
            deferred: [{ trigger: 'Show details', heading: 'Deferred table' }]
        }));
        assert.equal(unrelatedActivations(), 0);
        assert.equal(editor.triggerClicks(), 0);
    });

    it('activates only the identified parameter control even when another frame-wide control has the same label', async () => {
        const editor = sharedDeferredEditor();
        const unrelatedActivations = installUnrelatedControl(editor);
        const report = await validateWorkbookInBrowser(editor.page, editor.source, {
            deferred: [{ trigger: 'Show details', heading: 'Deferred table' }]
        });
        assert.equal(unrelatedActivations(), 0);
        assert.equal(editor.triggerClicks(), 1);
        assert.equal(report.parameterActionsClicked, 1);
    });

    for (const [description, mapping] of [
        ['missing producer', { ownerCount: 0 }],
        ['ambiguous producer', { ownerCount: 2 }],
        ['missing link id', { linkCount: 0 }],
        ['duplicate link id', { linkCount: 2 }],
        ['link outside the producer', { contained: false }],
        ['navigational link', { navigational: true }]
    ]) {
        it(`refuses deferred activation with a ${description} instead of falling back to labels`, async () => {
            const editor = sharedDeferredEditor();
            bindParameterProducer(editor, editor.trigger, mapping);
            await rejects(validateWorkbookInBrowser(editor.page, editor.source, {
                deferred: [{ trigger: 'Show details', heading: 'Deferred table' }]
            }));
            assert.equal(editor.triggerClicks(), 0);
        });
    }

    it('clicks a shared trigger once and validates all of its panels', async () => {
        const editor = sharedDeferredEditor();
        const report = await validateWorkbookInBrowser(editor.page, editor.source, {
            deferred: checks.deferred.map(({ trigger, heading }) => ({ trigger, heading, hideTriggerAfterLoad: true }))
        });
        assert.equal(editor.triggerClicks(), 1);
        assert.equal(report.parameterActionsClicked, 1);
        assert.lengthOf(report.deferredChecks, 2);
        assert.isTrue(report.deferredChecks.every(check => check.producerHidden));
    });

    it('checks every shared panel for eager content before any trigger click', async () => {
        const editor = sharedDeferredEditor(['Loaded details']);
        await rejects(validateWorkbookInBrowser(editor.page, editor.source, {
            deferred: checks.deferred.map(({ trigger, heading }) => ({ trigger, heading, hideTriggerAfterLoad: true }))
        }), /"Loaded details" was mounted before its trigger/);
        assert.equal(editor.triggerClicks(), 0);
    });

    it('checks actual grid row bounds and exact columns and reports only aggregate results', async () => {
        const editor = deferredGridEditor();
        const report = await validateWorkbookInBrowser(editor.page, editor.source, gridContract());
        assert.equal(report.dataContractsChecked, 1);
        assert.deepEqual(report.deferredChecks[0].grid, { rows: 2, columns: ['Label', 'Count'] });
        assert.equal(report.parameterActionsClicked, 1);
    });

    it('fails actual below-minimum and above-maximum results instead of just validating option shapes', async () => {
        for (const [bounds, message] of [
            [{ minRows: 3, maxRows: 3 }, /below minRows 3/],
            [{ minRows: 1, maxRows: 1 }, /above maxRows 1/]
        ]) {
            const editor = deferredGridEditor();
            await rejects(validateWorkbookInBrowser(editor.page, editor.source, gridContract(bounds)), message);
            assert.equal(editor.triggerClicks(), 1);
        }
    });

    it('fails an actual column mismatch and never treats no-data as a successful contract', async () => {
        const mismatch = deferredGridEditor({ columns: ['Wrong label', 'Count'] });
        await rejects(validateWorkbookInBrowser(mismatch.page, mismatch.source, gridContract()), /column labels differ/);
        const missing = deferredGridEditor({ available: false });
        await rejects(validateWorkbookInBrowser(missing.page, missing.source, gridContract()), /No query grid/);
    });

    it('executes the emitted portable runner through import and a complete synthetic grid contract', async () => {
        const editor = deferredGridEditor();
        const run = vm.runInNewContext(`(${createPlaywrightScript(editor.source, {
            ...gridContract(), tenant: testTenant
        })})`);
        const report = await run(editor.page);
        assert.equal(report.dataContractsChecked, 1);
        assert.equal(report.deferredChecks[0].grid.rows, 2);
        assert.equal(report.sourceSha256, crypto.createHash('sha256')
            .update(editor.source.replace(/\r\n/g, '\n')).digest('hex'));
        assert.isFalse(report.workbookSaved);
    });

    it('emits a self-contained Playwright function without Node imports or credentials', async () => {
        const script = createPlaywrightScript(source, { ...checks, tenant: testTenant });
        const run = vm.runInNewContext(`(${script})`);
        assert.isFunction(run);
        assert.notInclude(script, "require('");
        assert.notInclude(script, 'process.env');
        await rejects(run({ url: () => 'https://login.microsoftonline.com/' }), /Sign in to Azure/);
    });

    it('serializes workbook text as data rather than executable script', async () => {
        const injected = changedSource(workbook => {
            workbook.items[2].content.json = '"); globalThis.injected = true; //';
        });
        const context = vm.createContext({});
        const run = vm.runInContext(`(${createPlaywrightScript(injected, { ...checks, tenant: testTenant })})`, context);
        await rejects(run({ url: () => 'https://login.microsoftonline.com/' }), /Sign in to Azure/);
        assert.isUndefined(context.injected);
    });
});

describe('Validating explicit tenant selection...', () => {
    it('never accesses a browser before a tenant is explicitly selected and confirmed', async () => {
        const page = { url() { throw new Error('Browser must not be accessed while waiting.'); } };
        for (const tenant of [undefined, { id: testTenant.id }, { id: testTenant.id, confirmed: false }]) {
            await rejects(validateWithExplicitTenant(page, emptySource, { tenant }), /PAUSED: Ask the user/);
        }
        assert.throws(() => createValidationPlan(source, { autopilot: true }), /unsupported option/);
    });

    it('normalizes a selected GUID without inferring confirmation or accepting invalid fields', () => {
        assert.deepEqual(normalizeTenantSelection({ id: ` ${otherTenantId.toUpperCase()} ` }),
            { id: otherTenantId, confirmed: false });
        assert.throws(() => requireConfirmedTenant({ id: testTenant.id }), /PAUSED/);
        for (const value of [false, {}, { id: 'not-a-guid', confirmed: true },
            { ...testTenant, confirmed: 'true' }, { ...testTenant, defaultTenant: true }]) {
            assert.throws(() => normalizeTenantSelection(value), /tenant must contain/);
        }
    });

    it('matches only the confirmed portal-directory GUID and never chooses another account', async () => {
        await verifySelectedTenant(accountPage(), testTenant);
        for (const ids of [[], [otherTenantId], [testTenant.id, otherTenantId]]) {
            await rejects(verifySelectedTenant(accountPage(ids), testTenant), error => {
                assert.include(error.message, 'PAUSED');
                assert.notInclude(error.message, testTenant.id);
                assert.notInclude(error.message, otherTenantId);
                return true;
            });
        }
    });

    it('pauses if tenant identity cannot be read instead of using the signed-in/default tenant', async () => {
        await rejects(verifySelectedTenant({
            url: () => 'https://portal.azure.com/#home',
            getByRole: () => ({ count: async () => 0 })
        }, testTenant), /Cannot verify/);
    });

    it('stops before Apply when the selected directory changes after source import', async () => {
        const editor = editorPage(emptySource);
        let checks = 0;
        const account = accountPage([otherTenantId]);
        const original = editor.page.getByRole;
        editor.page.getByRole = (role, options) => role === 'button' && ++checks > 1 ?
            account.getByRole(role, options) : original(role, options);
        editor.frame.getByRole = ((original) => (role, options) => role === 'tablist' ? {
            first() { return this; },
            async waitFor() {},
            getByRole: () => ({ allTextContents: async () => ['Overview', 'Details'] })
        } : original(role, options))(editor.frame.getByRole.bind(editor.frame));
        await rejects(validateWorkbookInBrowser(editor.page, source), /signed-in tenant is different/);
        assert.equal(editor.state.writes, 1);
        assert.deepEqual(editor.state.clicks, []);
    });

    it('reverifies the directory before leaving edit mode instead of continuing after a directory change', async () => {
        const editor = editorPage(emptySource);
        const original = editor.page.getByRole;
        const other = accountPage([otherTenantId]);
        let checks = 0;
        editor.page.getByRole = (role, options) => role === 'button' && ++checks > 2 ?
            other.getByRole(role, options) : original(role, options);
        await rejects(validateWorkbookInBrowser(editor.page, emptySource), /signed-in tenant is different/);
        assert.deepEqual(editor.state.clicks, ['Apply']);
    });

    it('emits a runner that pauses without touching a browser if approval is absent', async () => {
        const run = vm.runInNewContext(`(${createPlaywrightScript(source, checks)})`);
        await rejects(run({ url() { throw new Error('Unexpected browser access'); } }), /PAUSED: Ask the user/);
    });

    it('requires fresh confirmation when a CLI/environment override changes the tenant', () => {
        const input = loadValidationInput(fixturePath, checksPath, undefined,
            { tenantId: testTenant.id, confirmTenant: false });
        assert.isFalse(input.options.tenant.confirmed);
        assert.throws(() => requireConfirmedTenant(input.options.tenant), /PAUSED/);
        const confirmed = loadValidationInput(fixturePath, checksPath, undefined,
            { tenantId: testTenant.id, confirmTenant: true });
        assert.deepEqual(confirmed.options.tenant, testTenant);
    });

    it('fails before CDP connection when the opt-in Mocha runner has no tenant approval', () => {
        const env = {
            ...process.env,
            WORKBOOK_BROWSER_TEMPLATE: fixturePath,
            WORKBOOK_BROWSER_CHECKS: checksPath,
            WORKBOOK_BROWSER_CDP_ENDPOINT: 'http://127.0.0.1:1'
        };
        delete env.WORKBOOK_BROWSER_TENANT_ID;
        delete env.WORKBOOK_BROWSER_TENANT_CONFIRMED;
        delete env.WORKBOOK_BROWSER_SCREENSHOTS;
        delete env.WORKBOOK_BROWSER_REDACTION;
        delete env.WORKBOOK_BROWSER_ALLOW_SENSITIVE_CAPTURE;
        const result = spawnSync(process.execPath, [
            require.resolve('mocha/bin/mocha.js'), '--timeout', '10000',
            path.join(browserDirectory, 'workbookValidation.test.js')
        ], { encoding: 'utf8', env, timeout: 15000 });
        assert.equal(result.status, 1, result.stderr);
        assert.include(result.stdout + result.stderr, 'PAUSED: Ask the user');
        assert.notInclude(result.stdout + result.stderr, 'ECONNREFUSED');
    });
});

describe('Validating optional screenshot safeguards...', () => {
    it('requires explicit local output and preserves disabled defaults', () => {
        assert.isFalse(createValidationPlan(source, { screenshots: false }).screenshots);
        assert.deepEqual(createValidationPlan(source, { screenshots: { directory: '.playwright-mcp/images' } }).screenshots,
            { directory: '.playwright-mcp/images', maskSelectors: [], redaction: 'auto', allowSensitiveCapture: false });
        for (const directory of ['', 'https://example.invalid/', '\\\\server\\share', '//server/share',
            '../outside', 'local\\..\\outside', 'local\ninvalid']) {
            assert.throws(() => createValidationPlan(source, { screenshots: { directory } }), /local directory/);
        }
        assert.throws(() => createValidationPlan(source, { screenshots: true }), /must be an object/);
        assert.throws(() => createValidationPlan(source, { screenshots: { directory: 'local', unmasked: true } }), /supported options/);
        assert.throws(() => createValidationPlan(source, {
            screenshots: { directory: 'local', maskSelectors: [''] }
        }), /CSS selectors/);
    });

    it('supports CLI/environment opt-in without discarding additional checks-file masks', () => {
        const input = loadValidationInput(fixturePath, checksPath, 'C:\\private-evidence');
        assert.equal(input.options.screenshots.directory, 'C:\\private-evidence');
        assert.deepEqual(input.options.deferred, checks.deferred);
    });

    it('never disables automatic redaction without explicit sensitive-capture approval', () => {
        for (const redaction of ['manual', 'ai-assisted', 'none']) {
            assert.throws(() => normalizeScreenshotOptions({
                directory: 'private', redaction, maskSelectors: redaction === 'none' ? [] : ['.private']
            }), /PAUSED: Non-auto screenshots/);
        }
        assert.throws(() => normalizeScreenshotOptions({
            directory: 'private', redaction: 'none', allowSensitiveCapture: 'true'
        }), /boolean allowSensitiveCapture/);
        assert.throws(() => normalizeScreenshotOptions({
            directory: 'private', redaction: 'unknown', allowSensitiveCapture: true
        }), /Choose auto/);
    });

    it('requires reviewed selectors for manual/AI-assisted masks and rejects ignored masks in raw mode', () => {
        for (const redaction of ['manual', 'ai-assisted']) {
            assert.throws(() => normalizeScreenshotOptions({
                directory: 'private', redaction, allowSensitiveCapture: true
            }), /reviewed maskSelectors/);
            assert.equal(normalizeScreenshotOptions({
                directory: 'private', redaction, allowSensitiveCapture: true, maskSelectors: ['.private']
            }).redaction, redaction);
        }
        assert.throws(() => normalizeScreenshotOptions({
            directory: 'private', redaction: 'none', allowSensitiveCapture: true, maskSelectors: ['.private']
        }), /cannot silently ignore/);
    });

    function redactionBody({ stale = false, missing = false } = {}) {
        function element(role) {
            return {
                attributes: {},
                setAttribute(name, value) { this.attributes[name] = value; },
                closest(selector) {
                    if (selector === 'script,style,noscript') return null;
                    if (selector.includes('gridcell')) return role === 'cell' ? this : null;
                    return role === 'heading' ? this : null;
                }
            };
        }
        const heading = element('heading');
        const cell = element('cell');
        const text = element('text');
        const input = element('input');
        const image = element('image');
        const extra = element('extra');
        const nodes = [
            { nodeValue: 'Approved heading', parentElement: heading },
            { nodeValue: 'Approved heading', parentElement: cell },
            { nodeValue: 'private-resource@example.invalid', parentElement: text }
        ];
        let index = 0;
        const body = element('body');
        body.querySelectorAll = selector => {
            if (selector === '.extra-mask') return missing ? [] : [extra];
            return [cell, input, image];
        };
        body.ownerDocument = {
            querySelector: () => stale ? heading : null,
            createTreeWalker: () => ({ nextNode: () => nodes[index++] || null })
        };
        return { body, heading, cell, text, input, image, extra };
    }

    it('masks data, inputs, media and non-contract text even when a cell matches an allowed label', () => {
        const fixture = redactionBody();
        const count = markScreenshotMasks(fixture.body, {
            marker: 'unit', allowedLabels: ['Approved heading'], maskSelectors: ['.extra-mask']
        });
        assert.equal(count, 5);
        for (const element of [fixture.cell, fixture.text, fixture.input, fixture.image, fixture.extra]) {
            assert.equal(element.attributes['data-workbook-validation-mask'], 'unit');
        }
        assert.isUndefined(fixture.heading.attributes['data-workbook-validation-mask']);
        assert.equal(fixture.heading.attributes['data-workbook-validation-label'], 'unit');
        assert.equal(fixture.body.attributes['data-workbook-validation-capture'], 'unit');
    });

    it('limits approved manual/AI-assisted masking to the selected regions', () => {
        for (const redaction of ['manual', 'ai-assisted']) {
            const fixture = redactionBody();
            const count = markScreenshotMasks(fixture.body, {
                marker: 'unit', redaction, allowedLabels: [], maskSelectors: ['.extra-mask']
            });
            assert.equal(count, 1);
            assert.equal(fixture.extra.attributes['data-workbook-validation-mask'], 'unit');
            for (const element of [fixture.cell, fixture.text, fixture.input, fixture.image]) {
                assert.deepEqual(element.attributes, {});
            }
            assert.notInclude(screenshotRedactionStyle('unit', redaction),
                'body[data-workbook-validation-capture="unit"], body[data-workbook-validation-capture="unit"] *');
        }
    });

    it('refuses stale or unmatched explicit masks before altering the page', () => {
        const stale = redactionBody({ stale: true });
        assert.throws(() => markScreenshotMasks(stale.body, {
            marker: 'unit', allowedLabels: [], maskSelectors: []
        }), /previous screenshot mask/);
        const missing = redactionBody({ missing: true });
        assert.throws(() => markScreenshotMasks(missing.body, {
            marker: 'unit', allowedLabels: [], maskSelectors: ['.extra-mask']
        }), /matched no elements/);
        assert.deepEqual(missing.body.attributes, {});
        assert.deepEqual(missing.cell.attributes, {});
    });

    function screenshotPage({ fail = false, masks = 3, blockedRedaction = false, blockedIsolation = false, timeout = 30000, reload = false } = {}) {
        const calls = [];
        const cleanedRootAttributes = [];
        let replaced = false;
        const body = {
            async dispose() { calls.push('dispose-document'); },
            async evaluate(callback, argument) {
                if (callback === bindCaptureDocument) { calls.push('bind-document'); return; }
                if (callback === verifyCaptureDocument) {
                    calls.push('verify-document');
                    if (replaced) throw new Error('Inner document changed');
                    return;
                }
                if (callback === markScreenshotMasks) {
                    calls.push('mask');
                    assert.deepEqual(argument.allowedLabels, ['Approved heading']);
                    return masks;
                }
                if (callback === applyScreenshotRedaction) {
                    calls.push('redact');
                    assert.equal(argument.css, screenshotRedactionStyle(argument.marker, argument.redaction));
                    assert.include(argument.css, 'color: transparent !important');
                    assert.include(argument.css, 'background-color: #111111 !important');
                    assert.include(argument.css, 'visibility: hidden !important');
                    if (blockedRedaction) throw new Error('redaction blocked');
                    return;
                }
                assert.strictEqual(callback, clearCaptureDocument);
                calls.push('cleanup');
                cleanedRootAttributes.push('data-workbook-validation-mask', 'data-workbook-validation-label', 'data-workbook-validation-capture');
            }
        };
        const frame = {
            locator(selector) {
                assert.equal(selector, 'body');
                return { elementHandle: async () => body };
            }
        };
        const outer = {
            contentFrame: async () => frame,
            async dispose() { calls.push('dispose-frame'); },
            async evaluate(callback) {
                if (callback === isolateScreenshotFrame) {
                    calls.push('isolate');
                    if (blockedIsolation) throw new Error('parent isolation blocked');
                } else if (callback === verifyScreenshotIsolation) {
                    calls.push('verify-isolation');
                } else if (callback === restoreScreenshotIsolation) {
                    calls.push('restore-isolation');
                } else {
                    throw new Error('Unexpected parent document callback.');
                }
            }
        };
        const page = { locator: () => ({ count: async () => 1, elementHandle: async () => outer }) };
        const target = {
            async screenshot(options) {
                calls.push('capture');
                assert.isUndefined(options.mask);
                assert.isUndefined(options.style);
                assert.equal(options.animations, 'disabled');
                assert.equal(options.caret, 'hide');
                assert.equal(options.timeout, timeout);
                assert.match(options.path, /^C:\\private-evidence\\capture-[a-z0-9-]+\.png$/);
                if (reload) replaced = true;
                if (fail) throw new Error('simulated capture failure');
            }
        };
        return { page, target, calls, cleanedRootAttributes };
    }

    it('captures only with opaque masks and reports a review reminder without absolute paths', async () => {
        const fixture = screenshotPage();
        const result = await captureMaskedScreenshot(fixture.page, fixture.target,
            { directory: 'C:\\private-evidence', maskSelectors: [] }, ['Approved heading'], 0);
        assert.deepEqual(fixture.calls, ['bind-document', 'mask', 'redact', 'isolate', 'verify-isolation', 'verify-document', 'capture', 'verify-document', 'verify-isolation', 'cleanup', 'restore-isolation', 'dispose-document', 'dispose-frame']);
        assert.isTrue(result.parentIsolated);
        assert.isTrue(result.documentBound);
        assert.isTrue(result.reviewRequired);
        assert.equal(result.redaction, 'auto');
        assert.isFalse(result.publicationApproved);
        assert.equal(result.maskedElements, 3);
        assert.notInclude(JSON.stringify(result), 'private-evidence');
        assert.deepEqual(fixture.cleanedRootAttributes, [
            'data-workbook-validation-mask', 'data-workbook-validation-label', 'data-workbook-validation-capture'
        ]);
    });

    it('always cleans markers and never retries an unmasked screenshot after a capture error', async () => {
        const fixture = screenshotPage({ fail: true });
        await rejects(captureMaskedScreenshot(fixture.page, fixture.target,
            { directory: 'C:\\private-evidence', maskSelectors: [] }, ['Approved heading'], 1), /simulated capture failure/);
        assert.deepEqual(fixture.calls, ['bind-document', 'mask', 'redact', 'isolate', 'verify-isolation', 'verify-document', 'capture', 'cleanup', 'restore-isolation', 'dispose-document', 'dispose-frame']);
    });

    it('refuses mask-free captures while cleaning the temporary capture scope', async () => {
        const fixture = screenshotPage({ masks: 0 });
        await rejects(captureMaskedScreenshot(fixture.page, fixture.target,
            { directory: 'C:\\private-evidence', maskSelectors: [] }, ['Approved heading'], 2), /No screenshot masks/);
        assert.deepEqual(fixture.calls, ['bind-document', 'mask', 'cleanup', 'dispose-document', 'dispose-frame']);
    });

    it('captures unredacted content only through a distinct explicitly approved path', async () => {
        const fixture = screenshotPage();
        await rejects(captureWorkbookScreenshot(fixture.page, fixture.target,
            { directory: 'private', redaction: 'none' }, [], 0), /PAUSED/);
        assert.lengthOf(fixture.calls, 0);
        const result = await captureWorkbookScreenshot(fixture.page, fixture.target,
            { directory: 'C:\\private-evidence', redaction: 'none', allowSensitiveCapture: true }, [], 0);
        assert.deepEqual(fixture.calls, ['bind-document', 'isolate', 'verify-isolation', 'verify-document', 'capture', 'verify-document', 'verify-isolation', 'cleanup', 'restore-isolation', 'dispose-document', 'dispose-frame']);
        assert.equal(result.redaction, 'none');
        assert.equal(result.maskedElements, 0);
        assert.isTrue(result.reviewRequired);
        assert.isFalse(result.publicationApproved);
        await rejects(captureMaskedScreenshot(fixture.page, fixture.target,
            { directory: 'private', redaction: 'none', allowSensitiveCapture: true }, [], 0), /Masked capture requires/);
    });

    it('applies selective masks for both manual and AI-assisted selection without calling an AI service', async () => {
        for (const redaction of ['manual', 'ai-assisted']) {
            const fixture = screenshotPage();
            const result = await captureWorkbookScreenshot(fixture.page, fixture.target, {
                directory: 'C:\\private-evidence', redaction, allowSensitiveCapture: true, maskSelectors: ['.private']
            }, ['Approved heading'], 0);
            assert.equal(result.redaction, redaction);
            assert.isFalse(result.publicationApproved);
            assert.deepEqual(fixture.calls, ['bind-document', 'mask', 'redact', 'isolate', 'verify-isolation', 'verify-document', 'capture', 'verify-document', 'verify-isolation', 'cleanup', 'restore-isolation', 'dispose-document', 'dispose-frame']);
        }
    });

    it('never calls the screenshot API after a failed DOM-redaction probe', async () => {
        const fixture = screenshotPage({ blockedRedaction: true });
        await rejects(captureMaskedScreenshot(fixture.page, fixture.target,
            { directory: 'C:\\private-evidence', maskSelectors: [] }, ['Approved heading'], 3), /redaction blocked/);
        assert.deepEqual(fixture.calls, ['bind-document', 'mask', 'redact', 'cleanup', 'dispose-document', 'dispose-frame']);
    });

    it('never captures when parent-page overlay isolation is unavailable', async () => {
        const fixture = screenshotPage({ blockedIsolation: true });
        await rejects(captureMaskedScreenshot(fixture.page, fixture.target,
            { directory: 'C:\\private-evidence' }, ['Approved heading'], 4), /parent isolation blocked/);
        assert.deepEqual(fixture.calls, ['bind-document', 'mask', 'redact', 'isolate', 'cleanup', 'dispose-document', 'dispose-frame']);
    });

    it('rejects document replacement and explicitly requires disposal of any image already written', async () => {
        const fixture = screenshotPage({ reload: true });
        await rejects(captureMaskedScreenshot(fixture.page, fixture.target,
            { directory: 'C:\\private-evidence' }, ['Approved heading'], 5), error =>
            error.message.includes('Inner document changed') && error.message.includes('Discard local image'));
        assert.include(fixture.calls, 'restore-isolation');
        assert.deepEqual(fixture.calls.slice(-2), ['dispose-document', 'dispose-frame']);
    });

    it('passes the requested operation timeout through to screenshot capture', async () => {
        const fixture = screenshotPage({ timeout: 75 });
        await captureMaskedScreenshot(fixture.page, fixture.target,
            { directory: 'C:\\private-evidence' }, ['Approved heading'], 4, 75);
        assert.ok(fixture.calls.includes('capture'));
        const invalid = screenshotPage();
        await rejects(captureMaskedScreenshot(invalid.page, invalid.target,
            { directory: 'C:\\private-evidence' }, ['Approved heading'], 4, 0), /operation timeout/);
        assert.deepEqual(invalid.calls, []);
    });

    it('refuses capture if the browser blocks or ignores DOM redaction styles', () => {
        const removed = [];
        const body = {
            append() {},
            ownerDocument: {
                head: { append() {} },
                createElement: tag => ({
                    setAttribute() {},
                    remove() { removed.push(tag); }
                }),
                defaultView: { getComputedStyle: () => ({ color: 'rgb(0, 0, 0)' }) }
            }
        };
        assert.throws(() => applyScreenshotRedaction(body, { marker: 'unit', css: 'blocked' }), /did not take effect/);
        assert.deepEqual(removed, ['span']);
    });

    it('includes screenshot helpers in standalone scripts without capturing unless enabled', () => {
        const disabled = createPlaywrightScript(source, checks);
        assert.isFunction(vm.runInNewContext(`(${disabled})`));
        const enabled = createPlaywrightScript(source, {
            ...checks, screenshots: { directory: '.playwright-mcp/images' }
        });
        assert.isFunction(vm.runInNewContext(`(${enabled})`));
        assert.include(enabled, 'async function captureMaskedScreenshot');
        assert.include(enabled, 'function markScreenshotMasks');
        assert.notInclude(enabled, "require('");
    });
});

describe('Validating browser script generation...', () => {
    let directory;
    before(() => { directory = fs.mkdtempSync(path.join(os.tmpdir(), 'workbook-browser-validator-')); });
    after(() => {
        for (const file of fs.readdirSync(directory)) {
            fs.unlinkSync(path.join(directory, file));
        }
        fs.rmdirSync(directory);
    });

    function generate(args) {
        return spawnSync(process.execPath, [path.join(browserDirectory, 'generateScript.js'), ...args], {
            cwd: path.resolve(__dirname, '..', '..', '..'),
            encoding: 'utf8',
            env: { ...process.env, GH_TOKEN: 'browser-validator-test-sentinel' }
        });
    }

    it('generates only the requested script and does not print or embed authentication state', () => {
        const output = path.join(directory, 'smoke.js');
        const result = generate(['--workbook', fixturePath, '--checks', checksPath, '--output', output]);
        assert.equal(result.status, 0, result.stderr);
        assert.isTrue(fs.existsSync(output));
        assert.isFunction(vm.runInNewContext(`(${fs.readFileSync(output, 'utf8')})`));
        assert.notInclude(result.stdout, source);
        assert.notInclude(fs.readFileSync(output, 'utf8'), 'browser-validator-test-sentinel');
    });

    it('refuses to overwrite an existing file', () => {
        const output = path.join(directory, 'existing.js');
        fs.writeFileSync(output, 'keep this file');
        const result = generate(['--workbook', fixturePath, '--output', output]);
        assert.equal(result.status, 1);
        assert.equal(fs.readFileSync(output, 'utf8'), 'keep this file');
    });

    it('prints only source diagnostic codes and item indexes, not query contents', () => {
        const workbook = path.join(directory, 'risk.json');
        const output = path.join(directory, 'risk.js');
        fs.writeFileSync(workbook, JSON.stringify({ version: 'Notebook/1.0', items: [{
            type: 3, content: {
                query: 'private-test-query-value',
                gridSettings: { formatters: [{ formatOptions: { thresholdsGrid: [{ thresholdValue: 1 }] } }] }
            }
        }] }));
        const result = generate(['--workbook', workbook, '--output', output]);
        assert.equal(result.status, 0, result.stderr);
        assert.include(result.stdout + result.stderr, 'non-string-threshold (item 0)');
        assert.notInclude(result.stdout + result.stderr, 'private-test-query-value');
    });
    it('fails explicitly for missing arguments and unknown switches', () => {
        const missing = generate([]);
        assert.equal(missing.status, 1);
        assert.include(missing.stderr, '--output');
        const unknown = generate(['--credential', 'not-used']);
        assert.equal(unknown.status, 1);
        assert.include(unknown.stderr, 'Unsupported argument');
    });

    it('offers opt-in screenshot guidance and supports an explicit masked output directory', () => {
        const output = path.join(directory, 'screenshots.js');
        const result = generate(['--workbook', fixturePath, '--screenshots', 'C:\\private-evidence', '--output', output]);
        assert.equal(result.status, 0, result.stderr);
        assert.include(result.stdout, 'conservative masking');
        const without = path.join(directory, 'no-screenshots.js');
        const disabled = generate(['--workbook', fixturePath, '--output', without]);
        assert.equal(disabled.status, 0, disabled.stderr);
        assert.include(disabled.stdout, 'Would screenshots help?');
        assert.include(disabled.stdout, 'PAUSED for live execution');
    });

    it('accepts explicit per-run tenant choice and raw-capture approval without echoing the tenant', () => {
        const output = path.join(directory, 'approved-private.js');
        const result = generate(['--workbook', fixturePath, '--tenant', testTenant.id, '--confirm-tenant',
            '--screenshots', 'C:\\private-evidence', '--redaction', 'none', '--allow-sensitive-capture', '--output', output]);
        assert.equal(result.status, 0, result.stderr);
        assert.include(result.stdout, 'WARNING: approved selective/unredacted');
        assert.notInclude(result.stdout, 'PAUSED for live execution');
        assert.notInclude(result.stdout + result.stderr, testTenant.id);
        assert.isFunction(vm.runInNewContext(`(${fs.readFileSync(output, 'utf8')})`));
    });

    it('does not imply tenant confirmation or raw-capture approval from other CLI flags', () => {
        const pending = path.join(directory, 'pending-tenant.js');
        const result = generate(['--workbook', fixturePath, '--tenant', testTenant.id, '--output', pending]);
        assert.equal(result.status, 0, result.stderr);
        assert.include(result.stdout, 'PAUSED for live execution');
        const rejected = generate(['--workbook', fixturePath, '--screenshots', 'C:\\private-evidence',
            '--redaction', 'none', '--output', path.join(directory, 'rejected-raw.js')]);
        assert.equal(rejected.status, 1);
        assert.include(rejected.stderr, 'PAUSED: Non-auto screenshots');
    });

    it('can keep screenshot approval out of a private checks file and supply it only for this run', () => {
        const profile = path.join(directory, 'pending-approval.json');
        fs.writeFileSync(profile, JSON.stringify({
            screenshots: { directory: 'C:\\private-evidence', redaction: 'none' }
        }));
        const output = path.join(directory, 'per-run-approval.js');
        const result = generate(['--workbook', fixturePath, '--checks', profile,
            '--allow-sensitive-capture', '--output', output]);
        assert.equal(result.status, 0, result.stderr);
        assert.include(result.stdout, 'WARNING: approved selective/unredacted');
        assert.isUndefined(JSON.parse(fs.readFileSync(profile, 'utf8')).screenshots.allowSensitiveCapture);
    });

    it('honors negative and explicit-false CLI flags when revoking prior approvals', () => {
        const profile = path.join(directory, 'prior-approvals.json');
        fs.writeFileSync(profile, JSON.stringify({
            tenant: testTenant,
            screenshots: { directory: 'C:\\private-evidence', redaction: 'none', allowSensitiveCapture: true }
        }));
        for (const [index, flag] of ['--no-confirm-tenant', '--confirm-tenant=false'].entries()) {
            const result = generate(['--workbook', fixturePath, '--checks', profile, flag,
                '--output', path.join(directory, `revoked-tenant-${index}.js`)]);
            assert.equal(result.status, 0, result.stderr);
            assert.include(result.stdout, 'PAUSED for live execution');
        }
        for (const [index, flag] of ['--no-allow-sensitive-capture', '--allow-sensitive-capture=false'].entries()) {
            const result = generate(['--workbook', fixturePath, '--checks', profile, flag,
                '--output', path.join(directory, `revoked-capture-${index}.js`)]);
            assert.equal(result.status, 1);
            assert.include(result.stderr, 'PAUSED: Non-auto screenshots');
        }
    });
});
