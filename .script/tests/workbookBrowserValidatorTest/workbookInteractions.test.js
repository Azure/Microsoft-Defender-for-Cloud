const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const os = require('node:os');
const { spawnSync } = require('node:child_process');
const validator = require('../../workbook-browser/workbookBrowserValidator');
const interactions = require('../../workbook-browser/workbookInteractions');

const directory = path.resolve(__dirname, '../../workbook-browser/fixtures');
const workbookPath = path.join(directory, 'Interactions.workbook');
const checksPath = path.join(directory, 'interaction-checks.json');
const source = fs.readFileSync(workbookPath, 'utf8');
const checks = JSON.parse(fs.readFileSync(checksPath, 'utf8'));
const clone = value => JSON.parse(JSON.stringify(value));
const plan = overrides => validator.createValidationPlan(source, { ...clone(checks), ...overrides });

describe('Planning generalized drill-through, filter and reset scenarios...', () => {
    it('requires explicit instrumentation and preserves the exact original production source', () => {
        assert.throws(() => plan({ instrumentation: undefined }), /explicit instrumentation/);
        assert.throws(() => plan({ instrumentation: false }), /explicit instrumentation/);
        const result = plan();
        assert.equal(result.source, source.replace(/\r\n/g, '\n'));
        assert.notEqual(result.importSource, result.source);
        assert.equal(result.interactions.probes.length, 2);
        assert.equal(result.interactions.scenarios[0].steps.length, 3);
        const original = JSON.parse(source);
        const copy = JSON.parse(result.importSource);
        function native(items) {
            return items.filter(item => !item.name.startsWith('__workbook_validation')).map(item =>
                item.type === 12 ? { ...item, content: { ...item.content, items: native(item.content.items) } } : item);
        }
        assert.deepEqual(native(copy.items), original.items);
        assert.ok(copy.items.filter(item => item.name.startsWith('__workbook_validation')).every(item => item.type === 1));
        assert.ok(result.importSource.includes('{Selection:base64}'));
        assert.ok(result.importSource.includes('{Filter:base64}'));
    });

    it('creates deterministic boundary/probe identities for shared and generated execution', () => {
        assert.equal(plan().importSource, plan().importSource);
        const result = plan();
        assert.equal(new Set(result.interactions.bindings.flatMap(binding => [binding.begin, binding.end])).size, 6);
        assert.ok(result.interactions.scenarios[0].requiresAuthenticated);
        assert.equal(result.interactions.evidenceMode, 'synthetic');
        const script = validator.createPlaywrightScript(source, checks);
        assert.equal(typeof vm.runInNewContext(`(${script})`), 'function');
        assert.ok(!script.includes("require('"));
    });

    it('reuses shared panel defaults while preserving exact per-step contract overrides', () => {
        const result = plan();
        const panels = result.interactions.scenarios[0].steps.map(step => step.expect.panels[0]);
        assert.ok(panels.every(panel => panel.minRows === 1 && panel.maxRows === 1));
        assert.ok(panels.every(panel => JSON.stringify(panel.columns) === JSON.stringify(['Key', 'Label', 'Filter'])));
        const profile = clone(checks);
        profile.scenarios[0].steps[1].expect.panels[0].maxRows = 2;
        const overridden = validator.createValidationPlan(source, profile);
        assert.equal(overridden.interactions.scenarios[0].steps[0].expect.panels[0].maxRows, 1);
        assert.equal(overridden.interactions.scenarios[0].steps[1].expect.panels[0].maxRows, 2);
        profile.scenarios[0].panelDefaults.selector = '#unsafe';
        assert.throws(() => validator.createValidationPlan(source, profile), /panel defaults/);
    });

    it('records unexecuted needs-closer-look items during offline profile loading', () => {
        const input = validator.loadValidationInput(workbookPath, checksPath);
        assert.equal(input.reviewPlan.status, 'not-run');
        assert.equal(input.reviewPlan.instrumentation, true);
        assert.equal(input.reviewPlan.needsCloserLook.length, 3);
        assert.ok(input.reviewPlan.needsCloserLook.every(item => item.code === 'not-executed'));
        assert.match(input.reviewPlan.plannedSourceSha256, /^[a-f0-9]{64}$/);
        assert.ok(!JSON.stringify(input.reviewPlan).includes('item-one'));
    });

    it('keeps authenticated requirements pending when tenant approval is absent, before any browser access', async () => {
        const page = { url() { throw new Error('Unapproved browser access'); } };
        await assert.rejects(validator.validateWorkbookInBrowser(page, source, checks), error => {
            assert.match(error.message, /PAUSED/);
            assert.equal(error.report.status, 'blocked');
            assert.equal(error.report.needsCloserLook.length, 3);
            assert.equal(error.report.instrumentation.productionSourceModified, false);
            return true;
        });
    });

    it('rejects unsafe actions, missing source exports, malformed references, and empty assertions before browser access', () => {
        const invalid = [
            profile => { profile.scenarios[0].steps[0].action.type = 'click'; },
            profile => { profile.scenarios[0].steps[0].action.selector = '#anything'; },
            profile => { profile.scenarios[0].steps[0].action.item = 'interaction_parameters'; },
            profile => { profile.scenarios[0].steps[1].action.parameter = 'Unknown'; },
            profile => { profile.scenarios[0].steps[0].expect.parameters[0].contains.Key.$cell.capture = 'future'; },
            profile => { profile.scenarios[0].steps[0].expect.parameters[0].contains = {}; },
            profile => { profile.scenarios[0].steps[0].expect = { tab: 'Details' }; },
            profile => { profile.scenarios[0].steps[2].action.linkId = 'unknown'; },
            profile => { profile.scenarios[0].steps[1].id = profile.scenarios[0].steps[0].id; },
            profile => { profile.scenarios[0].steps[0].expect.panels[0].tab = 'Overview'; },
            profile => { profile.evidenceMode = 'default-tenant'; }
        ];
        for (const change of invalid) {
            const profile = clone(checks);
            change(profile);
            assert.throws(() => validator.createValidationPlan(source, profile));
        }
        const document = JSON.parse(source);
        delete document.items[2].content.exportedParameters;
        assert.throws(() => validator.createValidationPlan(JSON.stringify(document), checks), /declared parameter exports/);
    });

    it('requires an assertion for the changed/exported parameter instead of accepting unrelated panel smoke', () => {
        for (const index of [0, 1, 2]) {
            const profile = clone(checks);
            profile.scenarios[0].steps[index].expect.parameters = [];
            assert.throws(() => validator.createValidationPlan(source, profile),
                /assert at least one declared parameter export|assert the changed parameter|assert its target parameter/);
        }
    });

    it('makes unconfigured interaction coverage explicit without creating instrumentation or changing the source', async () => {
        const plain = validator.createValidationPlan(source);
        assert.equal(plain.importSource, plain.source);
        assert.equal(plain.interactions.scenarios.length, 0);
        assert.equal(plain.interactions.bindings.length, 0);
        assert.ok(plain.interactions.candidateCount > 0);
        const report = await interactions.runInteractionScenarios({}, {}, plain, {});
        assert.deepEqual(report.needsCloserLook, [{
            code: 'interaction-scenarios-not-configured', items: plain.interactions.candidateCount
        }]);
    });

    it('does not automate resource-scope parameters or external/ARM reset controls', () => {
        for (const type of [4, 5, 6, 8]) {
            const document = JSON.parse(source);
            document.items[0].content.parameters[0].type = type;
            assert.throws(() => validator.createValidationPlan(JSON.stringify(document), checks), /do not automate/);
        }
        for (const linkTarget of ['Url', 'ArmAction']) {
            const document = JSON.parse(source);
            document.items[3].content.items[1].content.links[0].linkTarget = linkTarget;
            assert.throws(() => validator.createValidationPlan(JSON.stringify(document), checks), /source parameter link/);
        }
    });

    it('restricts instrumented captures to automatic redaction even if raw capture was separately allowed', () => {
        for (const redaction of ['none', 'manual', 'ai-assisted']) {
            assert.throws(() => plan({ screenshots: {
                directory: 'private', redaction, allowSensitiveCapture: true,
                maskSelectors: redaction === 'none' ? [] : ['.private']
            } }), /require auto redaction/);
        }
    });

    it('does not allow captured-cell references outside a scenario or arbitrary cell selectors', () => {
        assert.throws(() => validator.createValidationPlan(source, {
            panels: [{ heading: 'Selection results', cells: [{
                row: 0, column: 'Key', equals: { $cell: { capture: 'anything', column: 'Key' } }
            }] }]
        }), /require an interaction scenario/);
        assert.throws(() => validator.createValidationPlan(source, {
            panels: [{ heading: 'Selection results', cells: [{ row: -1, column: 'Key', equals: '' }] }]
        }), /rendered row index/);
    });
});

function probeDocument() {
    const planned = plan();
    const values = new Map([
        ['Selection', JSON.stringify({ Key: 'item-one', Label: 'Private Unicode \u03b1', TargetView: 'details' })],
        ['Filter', 'All']
    ]);
    const document = {
        documentElement: {},
        defaultView: {
            setTimeout, clearTimeout,
            MutationObserver: class { observe() {} disconnect() {} }
        },
        querySelectorAll: () => planned.interactions.probes.map(probe => ({
            textContent: probe.heading,
            closest: () => ({ querySelectorAll: () => [{
                textContent: Buffer.from(values.get(probe.parameter), 'utf8').toString('base64')
            }] })
        }))
    };
    const body = { ownerDocument: document, isConnected: true };
    document.body = body;
    const settings = { namespace: planned.interactions.namespace, probes: planned.interactions.probes };
    interactions.initializeInteractionState(body, settings);
    return { body, document, settings, values, steps: planned.interactions.scenarios[0].steps };
}

describe('Observing private runtime parameter propagation without publishing values...', () => {
    it('decodes Unicode/JSON privately and compares captured row fields structurally', async () => {
        const fixture = probeDocument();
        const state = fixture.document.__workbookValidationInteractions;
        state.captures.set('picked', { Key: 'item-one', Label: 'Private Unicode \u03b1' });
        const result = await interactions.waitForInteractionParameters(fixture.body, {
            ...fixture.settings, assertions: fixture.steps[0].expect.parameters, timeout: 1000
        });
        assert.deepEqual(result, { ok: true });
        assert.ok(!JSON.stringify(result).includes('Private Unicode'));
        assert.ok(state.read(fixture.settings.probes[0].key, 'json').ok);
        interactions.clearInteractionState(fixture.body, fixture.settings.namespace);
    });

    it('proves filtering preserves the whole scope and reset preserves the selected filter', async () => {
        const fixture = probeDocument();
        const state = fixture.document.__workbookValidationInteractions;
        state.captures.set('picked', { Key: 'item-one', Label: 'Private Unicode \u03b1' });
        interactions.prepareInteractionStep(fixture.body, { ...fixture.settings, startScenario: false });
        await interactions.waitForInteractionParameters(fixture.body, {
            ...fixture.settings, assertions: fixture.steps[1].expect.parameters, timeout: 1000, snapshot: true
        });
        fixture.values.set('Filter', 'Failed');
        assert.deepEqual(await interactions.waitForInteractionParameters(fixture.body, {
            ...fixture.settings, assertions: fixture.steps[1].expect.parameters, timeout: 1000
        }), { ok: true });
        interactions.prepareInteractionStep(fixture.body, { ...fixture.settings, startScenario: false });
        await interactions.waitForInteractionParameters(fixture.body, {
            ...fixture.settings, assertions: fixture.steps[2].expect.parameters, timeout: 1000, snapshot: true
        });
        fixture.values.set('Selection', '{}');
        assert.deepEqual(await interactions.waitForInteractionParameters(fixture.body, {
            ...fixture.settings, assertions: fixture.steps[2].expect.parameters, timeout: 1000
        }), { ok: true });
        fixture.values.set('Filter', 'All');
        const failure = await interactions.waitForInteractionParameters(fixture.body, {
            ...fixture.settings, assertions: fixture.steps[2].expect.parameters, timeout: 30
        });
        assert.deepEqual(failure, { ok: false, code: 'parameter-assertion-mismatch' });
        interactions.clearInteractionState(fixture.body, fixture.settings.namespace);
    });

    it('does not treat missing probes or a replaced inner document as an empty successful value', async () => {
        const fixture = probeDocument();
        fixture.document.querySelectorAll = () => [];
        const result = await interactions.waitForInteractionParameters(fixture.body, {
            ...fixture.settings, assertions: fixture.steps[2].expect.parameters, timeout: 30
        });
        assert.equal(result.code, 'parameter-probe-unavailable');
        fixture.document.documentElement = {};
        const replaced = await interactions.waitForInteractionParameters(fixture.body, {
            ...fixture.settings, assertions: [], timeout: 30
        });
        assert.equal(replaced.code, 'interaction-document-unavailable');
        interactions.clearInteractionState(fixture.body, fixture.settings.namespace);
    });

    it('reports an observation exception as a code and disconnects without leaking private contents', async () => {
        const fixture = probeDocument();
        fixture.document.querySelectorAll = () => { throw new Error('Private DOM error text'); };
        const result = await interactions.waitForInteractionParameters(fixture.body, {
            ...fixture.settings, assertions: fixture.steps[2].expect.parameters, timeout: 30
        });
        assert.deepEqual(result, { ok: false, code: 'parameter-observation-failed' });
        assert.ok(!JSON.stringify(result).includes('Private'));
        interactions.clearInteractionState(fixture.body, fixture.settings.namespace);
    });

    it('does not pass on a transient matching value before a delayed scope reset', async () => {
        const fixture = probeDocument();
        fixture.document.__workbookValidationInteractions.captures.set('picked',
            { Key: 'item-one', Label: 'Private Unicode \u03b1' });
        const timer = setTimeout(() => fixture.values.set('Selection', '{}'), 40);
        try {
            const result = await interactions.waitForInteractionParameters(fixture.body, {
                ...fixture.settings, assertions: fixture.steps[0].expect.parameters, timeout: 400
            });
            assert.deepEqual(result, { ok: false, code: 'parameter-assertion-mismatch' });
        } finally {
            clearTimeout(timer);
            interactions.clearInteractionState(fixture.body, fixture.settings.namespace);
        }
    });

    it('waits for legitimate delayed propagation and a full matching observation interval', async () => {
        const fixture = probeDocument();
        const timer = setTimeout(() => fixture.values.set('Filter', 'Failed'), 40);
        const start = Date.now();
        try {
            const result = await interactions.waitForInteractionParameters(fixture.body, {
                ...fixture.settings, assertions: fixture.steps[1].expect.parameters.filter(assertion =>
                    assertion.comparison !== 'unchanged'), timeout: 1000
            });
            assert.deepEqual(result, { ok: true });
            assert.ok(Date.now() - start >= 250);
        } finally {
            clearTimeout(timer);
            interactions.clearInteractionState(fixture.body, fixture.settings.namespace);
        }
    });

    it('does not shorten the required stable window when the caller provides an insufficient timeout', async () => {
        const fixture = probeDocument();
        const assertions = fixture.steps[0].expect.parameters.filter(assertion => assertion.parse === 'text');
        const result = await interactions.waitForInteractionParameters(fixture.body, {
            ...fixture.settings, assertions, timeout: 100
        });
        assert.deepEqual(result, { ok: false, code: 'parameter-observations-unstable' });
        interactions.clearInteractionState(fixture.body, fixture.settings.namespace);
    });
});

function scenarioHost({
    failAt,
    unavailable = false,
    captureFailure = false,
    failAfter,
    truncated = false,
    tabResetAfterCapture = false,
    reloadDuringLaterStep = false
} = {}) {
    const planned = plan();
    if (truncated) {
        for (const step of planned.interactions.scenarios[0].steps) {
            for (const panel of step.expect.panels) panel.allowTruncated = true;
        }
    }
    const calls = [];
    let activeStep = -1;
    let cleared = false;
    let disposed = false;
    let stage;
    const body = {
        async evaluate(callback, argument) {
            if (callback === interactions.initializeInteractionState) return;
            if (callback === interactions.prepareInteractionStep) { activeStep++; return { ok: true }; }
            if (callback === interactions.bindInteractionTarget) {
                calls.push(argument.action.type);
                return { ok: true, kind: argument.action.type === 'selectRow' ? 'checkbox' :
                    argument.action.type === 'setParameter' ? 'select' : 'button' };
            }
            if (callback === interactions.waitForInteractionParameters) {
                if (reloadDuringLaterStep && activeStep === 1 && !argument.snapshot) {
                    throw new Error('The interaction document was replaced.');
                }
                if (!argument.snapshot && (activeStep === failAt ||
                    (failAfter !== undefined && activeStep === 0 && failAfter === stage))) {
                    return { ok: false, code: unavailable ? 'parameter-probe-unavailable' : 'parameter-assertion-mismatch' };
                }
                return { ok: true };
            }
            if (callback === interactions.clearInteractionState) {
                if (reloadDuringLaterStep) throw new Error('The original interaction document is unavailable.');
                cleared = true;
                return;
            }
            throw new Error('Unexpected interaction callback');
        },
        async dispose() { disposed = true; }
    };
    const target = { async selectOption() {}, async fill() {} };
    const frame = { locator: selector => selector === 'body' ? { elementHandle: async () => body } : target };
    const helpers = {
        async verifyTenant() { calls.push('verify'); },
        async navigate() {},
        async assertTab(name) {
            calls.push(`assertTab:${name}`);
            if (tabResetAfterCapture && stage === 'capture') throw new Error('The expected tab is no longer selected.');
        },
        async activate(_target, _timeout, key) { calls.push(key || 'Enter'); },
        async checkPanel() {
            stage = 'panels';
            return { heading: 'Safe summary', settled: true, grid: { rows: 1, columns: ['Label', 'Count'] },
                ...(truncated ? { truncation: { returned: 100, total: 1000 } } : {}) };
        },
        async capture() {
            stage = 'capture';
            if (captureFailure) {
                const error = new Error('Private error value must not be reported');
                error.validationCode = 'screenshot-capture-failed';
                throw error;
            }
        }
    };
    return { planned, frame, helpers, calls, cleaned: () => cleared && disposed, disposed: () => disposed };
}

describe('Reporting interaction execution separately from authenticated qualification...', () => {
    it('keeps all three live review items pending even when synthetic UI assertions pass', async () => {
        const host = scenarioHost();
        const report = await interactions.runInteractionScenarios({}, host.frame, host.planned, host.helpers);
        assert.equal(report.scenarios[0].status, 'passed');
        assert.equal(report.scenarios[0].qualification, 'needs-authenticated-validation');
        assert.equal(report.needsCloserLook.length, 3);
        assert.ok(report.needsCloserLook.every(item => item.code === 'authenticated-validation-pending'));
        assert.ok(host.calls.includes('Space'));
        assert.ok(host.calls.filter(call => call === 'verify').length >= 7);
        assert.ok(host.cleaned());
    });

    for (const stage of ['panels', 'capture']) {
        it(`rechecks the original parameter snapshots after ${stage} observations`, async () => {
            const host = scenarioHost({ failAfter: stage });
            const report = await interactions.runInteractionScenarios({}, host.frame, host.planned, host.helpers);
            assert.equal(report.scenarios[0].steps[0].status, 'failed');
            assert.equal(report.scenarios[0].steps[0].code, 'parameter-assertion-mismatch');
            assert.equal(report.scenarios[0].steps[0].phase, `recheck-parameters-after-${stage}`);
            assert.ok(report.scenarios[0].steps.slice(1).every(step => step.status === 'not-run'));
            assert.ok(host.cleaned());
        });
    }

    it('preserves accepted truncation and safe grid evidence in scenario step reports', async () => {
        const host = scenarioHost({ truncated: true });
        host.planned.interactions.evidenceMode = 'authenticated';
        const report = await interactions.runInteractionScenarios({}, host.frame, host.planned, host.helpers);
        assert.equal(report.scenarios[0].qualification, 'authenticated-instrumented');
        for (const step of report.scenarios[0].steps) {
            assert.deepEqual(step.panelResults[0].truncation, { returned: 100, total: 1000 });
            assert.deepEqual(step.panelResults[0].grid, { rows: 1, columns: ['Label', 'Count'] });
        }
        assert.ok(!JSON.stringify(report).includes('item-one'));
        assert.ok(host.cleaned());
    });

    describe('Binding screenshot redaction to one inner workbook document...', () => {
        function captureDocument() {
            const attributes = new Map([
                ['data-workbook-validation-capture', 'test']
            ]);
            const style = { textContent: 'expected CSS', remove() {} };
            const document = {
                documentElement: {},
                querySelectorAll: () => [style],
                createElement: () => ({ setAttribute() {}, remove() {} }),
                defaultView: {
                    getComputedStyle: () => ({
                        color: 'rgba(0, 0, 0, 0)',
                        getPropertyValue: () => 'rgba(0, 0, 0, 0)'
                    })
                }
            };
            document.defaultView.document = document;
            const body = {
                ownerDocument: document, isConnected: true,
                getAttribute: name => attributes.get(name) || null,
                querySelector: () => ({}),
                querySelectorAll: () => [],
                removeAttribute: name => attributes.delete(name),
                append() {}
            };
            document.body = body;
            validator.bindCaptureDocument(body, 'test');
            return { body, document, attributes, style,
                settings: { marker: 'test', masked: true, redaction: 'auto', css: 'expected CSS' } };
        }

        it('requires the original body/root/window document and exact redaction state', () => {
            const fixture = captureDocument();
            validator.verifyCaptureDocument(fixture.body, fixture.settings);
            fixture.document.documentElement = {};
            assert.throws(() => validator.verifyCaptureDocument(fixture.body, fixture.settings), /document changed/);
            validator.clearCaptureDocument(fixture.body, 'test');
            assert.equal(fixture.document.__workbookValidationCapture, undefined);
        });

        describe('Keeping scenario evidence pending through CLI generation and blocked live setup...', () => {
            it('generates the instrumented runner without upgrading generation into authenticated validation', () => {
                const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'workbook-interaction-cli-'));
                const output = path.join(directory, 'runner.js');
                try {
                    const result = spawnSync(process.execPath, [
                        path.resolve(__dirname, '../../workbook-browser/generateScript.js'),
                        '--workbook', workbookPath, '--checks', checksPath, '--evidence-mode', 'synthetic', '--output', output
                    ], { encoding: 'utf8', timeout: 15000 });
                    assert.equal(result.status, 0, result.stderr);
                    assert.ok(result.stdout.includes('instrumented unsaved test copy'));
                    assert.ok(result.stdout.includes('3 planned review items remain unexecuted'));
                    assert.ok(result.stdout.includes('PAUSED for live execution'));
                    assert.equal(typeof vm.runInNewContext(`(${fs.readFileSync(output, 'utf8')})`), 'function');
                } finally {
                    if (fs.existsSync(output)) fs.unlinkSync(output);
                    fs.rmdirSync(directory);
                }
            });

            it('prints a blocked aggregate review report and never connects to a browser without fresh tenant approval', () => {
                const env = {
                    ...process.env,
                    WORKBOOK_BROWSER_TEMPLATE: workbookPath,
                    WORKBOOK_BROWSER_CHECKS: checksPath,
                    WORKBOOK_BROWSER_CDP_ENDPOINT: 'http://127.0.0.1:1',
                    WORKBOOK_BROWSER_EVIDENCE_MODE: 'authenticated'
                };
                for (const name of ['WORKBOOK_BROWSER_TENANT_ID', 'WORKBOOK_BROWSER_TENANT_CONFIRMED',
                    'WORKBOOK_BROWSER_SCREENSHOTS', 'WORKBOOK_BROWSER_REDACTION', 'WORKBOOK_BROWSER_ALLOW_SENSITIVE_CAPTURE']) {
                    delete env[name];
                }
                const result = spawnSync(process.execPath, [
                    require.resolve('mocha/bin/mocha.js'), '--timeout', '10000',
                    path.resolve(__dirname, '../../workbook-browser/workbookValidation.test.js')
                ], { encoding: 'utf8', env, timeout: 15000 });
                assert.equal(result.status, 1, result.stderr);
                assert.ok(result.stdout.includes('"status": "blocked"'));
                assert.ok(result.stdout.includes('"phase": "tenant-confirmation"'));
                assert.ok(result.stdout.includes('"needsCloserLook"'));
                assert.ok(!result.stdout.includes('ECONNREFUSED'));
                assert.ok(!result.stdout.includes('"qualification": "authenticated-instrumented"'));
            });
        });

        it('rejects lost redaction markers or styles even if parent isolation remains intact', () => {
            for (const change of [
                fixture => fixture.attributes.delete('data-workbook-validation-capture'),
                fixture => { fixture.style.textContent = 'different CSS'; },
                fixture => { fixture.document.querySelectorAll = () => []; }
            ]) {
                const fixture = captureDocument();
                change(fixture);
                assert.throws(() => validator.verifyCaptureDocument(fixture.body, fixture.settings), /redaction state/);
            }
        });

        it('never qualifies a replacement document even for explicitly unredacted capture', () => {
            const fixture = captureDocument();
            fixture.document.defaultView.document = {};
            assert.throws(() => validator.verifyCaptureDocument(fixture.body, { ...fixture.settings, masked: false }), /document changed/);
        });
    });

    it('qualifies only caller-declared authenticated instrumented checks, not the exact production layout', async () => {
        const host = scenarioHost();
        host.planned.interactions.evidenceMode = 'authenticated';
        const report = await interactions.runInteractionScenarios({}, host.frame, host.planned, host.helpers);
        assert.equal(report.scenarios[0].qualification, 'authenticated-instrumented');
        assert.deepEqual(report.needsCloserLook, []);
        assert.ok(host.cleaned());
    });

    it('rechecks the expected tab after panel and capture observations', async () => {
        const host = scenarioHost({ tabResetAfterCapture: true });
        host.planned.interactions.evidenceMode = 'authenticated';
        const report = await interactions.runInteractionScenarios({}, host.frame, host.planned, host.helpers);
        const step = report.scenarios[0].steps[0];
        assert.equal(step.status, 'needs-closer-look');
        assert.equal(step.phase, 'recheck-tab-after-observations');
        assert.notEqual(report.scenarios[0].qualification, 'authenticated-instrumented');
        assert.equal(host.calls.filter(call => call === 'assertTab:Details').length, 2);
        assert.ok(host.cleaned());
    });

    it('preserves completed scenario evidence and interruption details when cleanup fails after a document reload', async () => {
        const host = scenarioHost({ reloadDuringLaterStep: true, truncated: true });
        host.planned.interactions.evidenceMode = 'authenticated';
        const report = await interactions.runInteractionScenarios({}, host.frame, host.planned, host.helpers);
        const scenario = report.scenarios[0];
        assert.deepEqual(scenario.steps.map(step => step.status), ['passed', 'needs-closer-look', 'not-run']);
        assert.equal(scenario.steps[0].panelResults[0].truncation.total, 1000);
        assert.equal(scenario.steps[1].code, 'interaction-interrupted');
        assert.equal(scenario.steps[1].phase, 'observe-parameters');
        assert.equal(scenario.status, 'needs-closer-look');
        assert.notEqual(scenario.qualification, 'authenticated-instrumented');
        assert.ok(report.needsCloserLook.some(item => item.code === 'interaction-state-cleanup-failed'));
        assert.ok(host.disposed());
    });

    it('stops after a real assertion mismatch, marks later actions unexecuted, and retains aggregate evidence only', async () => {
        const host = scenarioHost({ failAt: 1 });
        const report = await interactions.runInteractionScenarios({}, host.frame, host.planned, host.helpers);
        assert.deepEqual(report.scenarios[0].steps.map(step => step.status), ['passed', 'failed', 'not-run']);
        assert.ok(!host.calls.includes('parameterLink'));
        assert.ok(!JSON.stringify(report).includes('item-one'));
        assert.equal(report.needsCloserLook[1].code, 'prior-step-did-not-pass');
        assert.ok(host.cleaned());
    });

    it('reports unsupported observation hooks as needs-closer-look, never a successful parameter propagation', async () => {
        const host = scenarioHost({ failAt: 0, unavailable: true });
        const report = await interactions.runInteractionScenarios({}, host.frame, host.planned, host.helpers);
        assert.equal(report.scenarios[0].status, 'needs-closer-look');
        assert.equal(report.scenarios[0].steps[0].parameterAssertions, 0);
        assert.ok(!host.calls.includes('setParameter'));
        assert.ok(host.cleaned());
    });

    it('retains explicit image-disposal requirements without copying raw screenshot error details', async () => {
        const host = scenarioHost({ captureFailure: true });
        const report = await interactions.runInteractionScenarios({}, host.frame, host.planned, host.helpers);
        assert.equal(report.scenarios[0].steps[0].discardLocalCaptures, true);
        assert.equal(report.scenarios[0].steps[0].code, 'screenshot-capture-failed');
        assert.ok(!JSON.stringify(report).includes('Private error'));
        assert.ok(host.cleaned());
    });
});
