const assert = require('node:assert/strict');
const {
    verifySelectedTenant,
    createValidationPlan,
    isolateScreenshotFrame,
    verifyScreenshotIsolation,
    restoreScreenshotIsolation,
    waitForPanelReady,
    validatePanelContract,
    createPlaywrightScript
} = require('../../workbook-browser/workbookBrowserValidator');
const vm = require('node:vm');

const tenant = { id: '11111111-2222-3333-4444-555555555555', confirmed: true };
const otherId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
const notebook = items => JSON.stringify({ version: 'Notebook/1.0', items });

function accountWithTitle(title) {
    return {
        url: () => 'https://portal.azure.com/#home',
        getByRole: () => ({
            count: async () => 1,
            locator: () => ({
                evaluateAll: async callback => callback([{ getAttribute: () => title }])
            })
        })
    };
}

describe('Validating unambiguous directory metadata...', () => {
    it('rejects a confirmed GUID embedded in a display name before a different real directory GUID', async () => {
        const page = accountWithTitle(`Directory: Lab (${tenant.id}) (${otherId}) Domain: example.invalid`);
        await assert.rejects(verifySelectedTenant(page, tenant), error =>
            error.message.includes('PAUSED') && !error.message.includes(tenant.id) && !error.message.includes(otherId));
    });

    it('collects all candidates in one title regardless of order or case', async () => {
        const page = accountWithTitle(`Directory: Lab (${otherId.toUpperCase()}) (${tenant.id})`);
        await assert.rejects(verifySelectedTenant(page, tenant), /PAUSED/);
    });

    it('allows repeated identical candidates but never treats GUIDs before Directory as directory evidence', async () => {
        await verifySelectedTenant(accountWithTitle(`Directory: Lab (${tenant.id}) (${tenant.id})`), tenant);
        await assert.rejects(verifySelectedTenant(accountWithTitle(`Name: Lab (${tenant.id}) Directory: Lab`), tenant), /PAUSED/);
    });
});

describe('Validating reusable source diagnostics and panel planning...', () => {
    it('reports incompatible formatter types once per item without rewriting source or publishing values', () => {
        const source = notebook([{
            type: 3, name: 'generic_query', content: {
                query: 'private-value-not-for-reports',
                gridSettings: { formatters: [
                    { formatOptions: { thresholdsGrid: [{ operator: '==', thresholdValue: 2, representation: 3 }] } },
                    { formatOptions: { thresholdsGrid: [{ operator: '==', thresholdValue: false }] } }
                ] }
            }
        }]);
        const plan = createValidationPlan(source);
        assert.equal(plan.source, source);
        assert.deepEqual(plan.sourceDiagnostics, [{ code: 'non-string-threshold', itemIndex: 0 }]);
        assert.ok(!JSON.stringify(plan.sourceDiagnostics).includes('private-value'));
    });

    it('accepts string thresholds and omitted default-threshold values', () => {
        const source = notebook([{
            type: 3, content: { gridSettings: { formatters: [{
                formatOptions: { thresholdsGrid: [
                    { operator: '==', thresholdValue: '2', representation: '3', text: 'Failed' },
                    { operator: 'Default', representation: 'Blank', text: '' }
                ] }
            }] } }
        }]);
        assert.deepEqual(createValidationPlan(source).sourceDiagnostics, []);
    });

    it('flags direct global query-input/export feedback but not separate downstream scope exports', () => {
        const parameters = { type: 9, content: { parameters: [{ name: 'Scope', isGlobal: true }] } };
        const query = { type: 3, content: {
            query: 'resources | where name == "{Scope:escapejson}"',
            exportedParameters: [{ parameterName: 'Scope', fieldName: 'name' }]
        } };
        assert.deepEqual(createValidationPlan(notebook([parameters, query])).sourceDiagnostics,
            [{ code: 'global-input-export-cycle-risk', itemIndex: 1 }]);
        query.content.exportedParameters[0].parameterName = 'SelectedScope';
        assert.deepEqual(createValidationPlan(notebook([parameters, query])).sourceDiagnostics, []);
    });

    it('respects private group globals when checking legacy single-export configuration', () => {
        const query = { type: 3, content: { query: '{Scope}', exportParameterName: 'Scope' } };
        const group = { type: 12, content: {
            items: [{ type: 9, content: { parameters: [{ name: 'Scope', isGlobal: true }] } }]
        } };
        assert.deepEqual(createValidationPlan(notebook([group, query])).sourceDiagnostics, []);
        group.content.exportParameters = true;
        assert.equal(createValidationPlan(notebook([group, query])).sourceDiagnostics[0].code, 'global-input-export-cycle-risk');
    });

    it('supports eager panels without requiring tabs or synthetic deferred triggers', () => {
        const plan = createValidationPlan(notebook([]), {
            panels: [{ heading: 'Summary', minRows: 1, maxRows: 5, columns: ['Label', 'Count'] }]
        });
        assert.equal(plan.panels.length, 1);
        assert.equal(plan.panels[0].tab, undefined);
        assert.equal(plan.panels[0].allowTruncated, false);
        assert.deepEqual(plan.deferredGroups, []);
    });

    it('rejects ambiguous or malformed eager-panel contracts and invalid truncation choices', () => {
        for (const options of [
            { panels: {} },
            { panels: [{ heading: 'Summary' }, { heading: 'Summary' }] },
            { panels: [{ heading: 'Summary', tab: 'Unknown' }] },
            { panels: [{ heading: 'Summary', minRows: 3, maxRows: 2 }] },
            { panels: [{ heading: 'Summary', allowTruncated: 'true' }] },
            { panels: [{ heading: 'Summary', selector: '#arbitrary' }] }
        ]) assert.throws(() => createValidationPlan(notebook([]), options));
    });

    it('emits every runtime safeguard in the portable runner without Node-only dependencies', () => {
        const script = createPlaywrightScript(notebook([]), { panels: [{ heading: 'Summary', minRows: 1 }] });
        assert.equal(typeof vm.runInNewContext(`(${script})`), 'function');
        for (const name of ['isolateScreenshotFrame', 'restoreScreenshotIsolation', 'waitForPanelReady', 'validatePanelContract']) {
            assert.ok(script.includes(`function ${name}`));
        }
        assert.ok(!script.includes("require('"));
    });
});

function panelDom({ busy = false, grids = 1, error = false, truncation = false } = {}) {
    const state = { busy, grids, error, truncation, disconnected: false, observed: undefined };
    const visible = { getClientRects: () => [{}] };
    const document = {
        defaultView: {
            getComputedStyle: () => ({ visibility: 'visible', display: 'block' }),
            setTimeout,
            clearTimeout,
            MutationObserver: class {
                constructor(callback) { state.mutate = callback; }
                observe(_element, options) { state.observed = options; }
                disconnect() { state.disconnected = true; }
            }
        },
        createTreeWalker() {
            const texts = [
                ...(state.error ? ['Error loading item.'] : []),
                ...(state.truncation ? ['Results were limited to the first 10,000 of 74,605 items.'] : [])
            ];
            let index = 0;
            return { nextNode: () => index < texts.length ?
                { nodeValue: texts[index++], parentElement: { ...visible, closest: () => null } } : null };
        }
    };
    const element = {
        ownerDocument: document,
        isConnected: true,
        matches: () => false,
        querySelectorAll: selector => selector === '[role="grid"]' ?
            Array.from({ length: state.grids }, () => visible) : state.busy ? [visible] : []
    };
    return { element, state };
}

describe('Validating stable visible panels without reading record values...', () => {
    it('waits for settled data and reads only aggregate truncation counts', async () => {
        const fixture = panelDom({ truncation: true });
        const result = await waitForPanelReady(fixture.element, { timeout: 1000, requireGrid: true });
        assert.deepEqual(result, { settled: true, truncation: { returned: 10000, total: 74605 } });
        assert.equal(fixture.state.disconnected, true);
        assert.ok(fixture.state.observed.attributeFilter.includes('aria-rowcount'));
    });

    it('waits through initial loading rather than checking a transient empty panel', async () => {
        const fixture = panelDom({ busy: true, grids: 0 });
        const timer = setTimeout(() => { fixture.state.busy = false; fixture.state.grids = 1; fixture.state.mutate(); }, 40);
        try {
            assert.equal((await waitForPanelReady(fixture.element, { timeout: 1000, requireGrid: true })).settled, true);
        } finally {
            clearTimeout(timer);
        }
    });

    it('recognizes result-limit messages split across inline markup without reporting the raw text', async () => {
        const fixture = panelDom();
        fixture.element.ownerDocument.createTreeWalker = () => {
            let read = false;
            return { nextNode: () => read ? null : (read = true, {
                nodeValue: 'Results were limited to the first ',
                parentElement: {
                    textContent: 'Results were limited to the first 10,000 of 74,605 items.',
                    closest: () => null,
                    getClientRects: () => [{}]
                }
            }) };
        };
        const result = await waitForPanelReady(fixture.element, { timeout: 1000, requireGrid: true });
        assert.deepEqual(result.truncation, { returned: 10000, total: 74605 });
        assert.ok(!JSON.stringify(result).includes('Results were limited'));
    });

    it('refuses unsafe truncation counters rather than rounding them into an accepted result', async () => {
        const fixture = panelDom();
        fixture.element.ownerDocument.createTreeWalker = () => {
            let read = false;
            return { nextNode: () => read ? null : (read = true, {
                nodeValue: 'Results were limited to the first 2 of 9007199254740993 items.',
                parentElement: { closest: () => null, getClientRects: () => [{}] }
            }) };
        };
        await assert.rejects(waitForPanelReady(fixture.element, { timeout: 1000, requireGrid: true }), /invalid aggregate counts/);
        assert.equal(fixture.state.disconnected, true);
    });

    for (const [label, settings, message] of [
        ['renderer error', { error: true }, /renderer error/],
        ['multiple visible grids', { grids: 2 }, /multiple visible grids/],
        ['no-data', { grids: 0 }, /no-data and refresh loops are not passes/],
        ['permanent loading', { busy: true }, /stable ready state/]
    ]) {
        it(`refuses a ${label} and disconnects its observer`, async () => {
            const fixture = panelDom(settings);
            await assert.rejects(waitForPanelReady(fixture.element, { timeout: 100, requireGrid: true }), message);
            assert.equal(fixture.state.disconnected, true);
        });
    }

    it('does not qualify continuously refreshing content as stable', async () => {
        const fixture = panelDom();
        const interval = setInterval(() => fixture.state.mutate(), 30);
        try {
            await assert.rejects(waitForPanelReady(fixture.element, { timeout: 350, requireGrid: true }), /refresh loops/);
            assert.equal(fixture.state.disconnected, true);
        } finally {
            clearInterval(interval);
        }
    });

    it('refuses replacement/detached panels rather than silently switching results', async () => {
        const fixture = panelDom();
        fixture.element.isConnected = false;
        await assert.rejects(waitForPanelReady(fixture.element, { timeout: 100, requireGrid: true }), /replaced/);
        assert.equal(fixture.state.disconnected, true);
    });

    it('always disconnects its observer when DOM inspection throws', async () => {
        const fixture = panelDom();
        fixture.element.querySelectorAll = () => { throw new Error('DOM inspection failed'); };
        await assert.rejects(waitForPanelReady(fixture.element, { timeout: 100, requireGrid: true }), /DOM inspection failed/);
        assert.equal(fixture.state.disconnected, true);
    });

    function contractFrame({ truncated = false, headingCount = 1, rows = 2 } = {}) {
        return {
            getByRole: () => ({
                waitFor: async () => {},
                count: async () => headingCount,
                locator: () => ({
                    count: async () => 1,
                    evaluate: async () => ({ settled: true, truncation: truncated ? { returned: 100, total: 1000 } : undefined }),
                    getByRole: () => ({
                        evaluate: async callback => callback({
                            getAttribute: () => String(rows + 1),
                            querySelectorAll: () => [{ textContent: 'Label' }, { textContent: 'Count' }]
                        })
                    })
                })
            })
        };
    }

    it('fails truncated contracts by default and reports truncation only after explicit acceptance', async () => {
        const check = { heading: 'Generic summary', minRows: 1, columns: ['Label', 'Count'] };
        await assert.rejects(validatePanelContract(contractFrame({ truncated: true }), check, 1000), /allowTruncated/);
        const result = await validatePanelContract(contractFrame({ truncated: true }), { ...check, allowTruncated: true }, 1000);
        assert.deepEqual(result.truncation, { returned: 100, total: 1000 });
        assert.equal(result.grid.rows, 2);
    });

    it('rejects ambiguous headings before reading a grid', async () => {
        await assert.rejects(validatePanelContract(contractFrame({ headingCount: 2 }), { heading: 'Summary' }, 1000), /ambiguous/);
    });

    it('retains explicit zero-row contracts without describing them as healthy', async () => {
        const result = await validatePanelContract(contractFrame({ rows: 0 }), { heading: 'Empty', minRows: 0 }, 1000);
        assert.equal(result.grid.rows, 0);
        assert.ok(!JSON.stringify(result).includes('healthy'));
    });
});

function parentDocument({ blocked = false, shadow = false, nested = false } = {}) {
    const state = { disconnected: false, styleRemoved: false };
    const elements = [];
    function element(tag, parent, initial = {}) {
        const values = new Map(Object.entries(initial).map(([name, value]) => [name, [value, '']]));
        const attributes = new Map();
        const node = {
            tagName: tag,
            nodeType: 1,
            parentElement: parent,
            isConnected: true,
            style: {
                get length() { return values.size; },
                getPropertyValue: name => values.get(name)?.[0] || '',
                getPropertyPriority: name => values.get(name)?.[1] || '',
                setProperty: (name, value, priority) => values.set(name, [value, priority]),
                removeProperty: name => values.delete(name)
            },
            hasAttribute: name => name === 'style' ? values.size > 0 : attributes.has(name),
            getAttribute: name => attributes.get(name) || null,
            setAttribute: (name, value) => attributes.set(name, value),
            removeAttribute: name => attributes.delete(name),
            matches: () => tag === 'DIALOG',
            querySelectorAll: () => []
        };
        elements.push(node);
        return node;
    }
    const html = element('HTML');
    const body = element('BODY', html);
    const iframe = element('IFRAME', body);
    const overlay = element('DIV', body, { opacity: '0.8', visibility: 'visible' });
    const dialog = element('DIALOG', body);
    if (shadow) overlay.shadowRoot = {};
    const window = {
        getComputedStyle(node, pseudo) {
            if (pseudo) return { content: 'none', visibility: 'hidden', opacity: '0' };
            return {
                visibility: node.style.getPropertyValue('visibility') || 'visible',
                opacity: blocked && node === overlay ? '1' : node.style.getPropertyValue('opacity') || '1'
            };
        },
        MutationObserver: class {
            constructor(callback) { state.mutate = callback; }
            observe() {}
            disconnect() { state.disconnected = true; }
        }
    };
    window.top = nested ? {} : window;
    const document = {
        documentElement: html,
        defaultView: window,
        querySelector: () => null,
        querySelectorAll: () => elements,
        head: { append() {} },
        createElement: () => ({
            isConnected: true,
            setAttribute() {},
            remove() { state.styleRemoved = true; }
        })
    };
    for (const node of elements) node.ownerDocument = document;
    iframe.getRootNode = () => document;
    return { iframe, overlay, dialog, elements, element, state };
}

describe('Isolating workbook screenshots from all parent document paints...', () => {
    it('hides overlaid parent content and top-layer elements while keeping the iframe visible', () => {
        const fixture = parentDocument();
        isolateScreenshotFrame(fixture.iframe, 'test');
        assert.equal(fixture.overlay.style.getPropertyValue('opacity'), '0');
        assert.equal(fixture.dialog.style.getPropertyValue('display'), 'none');
        assert.equal(fixture.iframe.style.getPropertyValue('visibility'), 'visible');
        verifyScreenshotIsolation(fixture.iframe, 'test');
        restoreScreenshotIsolation(fixture.iframe, 'test');
        assert.equal(fixture.overlay.style.getPropertyValue('opacity'), '0.8');
        assert.equal(fixture.overlay.style.getPropertyValue('visibility'), 'visible');
        assert.equal(fixture.dialog.style.length, 0);
        assert.equal(fixture.iframe.__workbookValidationIsolation, undefined);
        assert.equal(fixture.state.disconnected, true);
        assert.equal(fixture.state.styleRemoved, true);
    });

    it('keeps new overlays isolated throughout capture, not just at initial inspection', () => {
        const fixture = parentDocument();
        isolateScreenshotFrame(fixture.iframe, 'test');
        const overlay = fixture.element('DIV', fixture.overlay, { opacity: '1' });
        overlay.ownerDocument = fixture.iframe.ownerDocument;
        fixture.state.mutate([{ type: 'childList', addedNodes: [overlay] }]);
        assert.equal(overlay.style.getPropertyValue('opacity'), '0');
        restoreScreenshotIsolation(fixture.iframe, 'test');
        assert.equal(overlay.style.getPropertyValue('opacity'), '1');
    });

    it('reapplies isolation when portal code changes overlay styles during capture', () => {
        const fixture = parentDocument();
        isolateScreenshotFrame(fixture.iframe, 'test');
        fixture.overlay.style.setProperty('opacity', '1', 'important');
        fixture.state.mutate([{ type: 'attributes', target: fixture.overlay }]);
        assert.equal(fixture.overlay.style.getPropertyValue('opacity'), '0');
        restoreScreenshotIsolation(fixture.iframe, 'test');
    });

    it('refuses ineffective isolation and restores styles before propagating the error', () => {
        const fixture = parentDocument({ blocked: true });
        assert.throws(() => isolateScreenshotFrame(fixture.iframe, 'test'), /did not take effect/);
        assert.equal(fixture.overlay.style.getPropertyValue('opacity'), '0.8');
        assert.equal(fixture.state.disconnected, true);
        assert.equal(fixture.state.styleRemoved, true);
        assert.equal(fixture.iframe.__workbookValidationIsolation, undefined);
    });

    it('refuses unsupported parent shadow-root and nested-frame environments', () => {
        const shadow = parentDocument({ shadow: true });
        assert.throws(() => isolateScreenshotFrame(shadow.iframe, 'test'), /Cannot guarantee isolation/);
        assert.equal(shadow.overlay.style.getPropertyValue('opacity'), '0.8');
        const nested = parentDocument({ nested: true });
        assert.throws(() => isolateScreenshotFrame(nested.iframe, 'test'), /Cannot isolate/);
    });

    it('rejects detached frames and unknown restoration scopes', () => {
        const fixture = parentDocument();
        isolateScreenshotFrame(fixture.iframe, 'test');
        assert.throws(() => verifyScreenshotIsolation(fixture.iframe, 'other'), /missing/);
        fixture.iframe.isConnected = false;
        assert.throws(() => verifyScreenshotIsolation(fixture.iframe, 'test'), /no longer valid/);
        restoreScreenshotIsolation(fixture.iframe, 'test');
        assert.throws(() => restoreScreenshotIsolation(fixture.iframe, 'test'), /unknown/);
    });
});
