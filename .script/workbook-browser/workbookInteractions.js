function normalizeCellAssertions(cells) {
    if (cells === undefined) return [];
    if (!Array.isArray(cells)) throw new Error('cells must be an array.');
    return cells.map(cell => {
        if (
            !cell ||
            typeof cell !== 'object' ||
            Array.isArray(cell) ||
            Object.keys(cell).some(key => !['row', 'column', 'equals'].includes(key)) ||
            !Number.isSafeInteger(cell.row) ||
            cell.row < 0 ||
            typeof cell.column !== 'string' ||
            !cell.column.trim() ||
            !Object.prototype.hasOwnProperty.call(cell, 'equals')
        ) {
            throw new Error('Each cell assertion requires a rendered row index, column label, and equals value.');
        }
        if (typeof cell.equals !== 'string' && (!cell.equals || typeof cell.equals !== 'object' || !cell.equals.$cell)) {
            throw new Error('Cell expectations must be display text or a captured-cell reference.');
        }
        return { row: cell.row, column: cell.column.replace(/\s+/g, ' ').trim(), equals: cell.equals };
    });
}

function planInteractionScenarios(workbook, options, tabs, normalizePanel) {
    function object(value, keys, message) {
        if (!value || typeof value !== 'object' || Array.isArray(value) || Object.keys(value).some(key => !keys.includes(key)))
            throw new Error(message);
    }
    function id(value) {
        if (typeof value !== 'string' || !/^[A-Za-z][A-Za-z0-9._-]{0,63}$/.test(value)) {
            throw new Error('Scenario, step, and capture IDs must be short non-sensitive identifiers.');
        }
        return value;
    }
    function tab(value) {
        if (value !== undefined && !tabs.includes(value)) throw new Error('Scenario tabs must belong to the primary tabset.');
        return value;
    }
    const evidenceMode = options.evidenceMode === undefined ? 'unspecified' : options.evidenceMode;
    if (!['unspecified', 'synthetic', 'authenticated'].includes(evidenceMode)) throw new Error('Invalid evidenceMode.');
    if (options.instrumentation !== undefined && typeof options.instrumentation !== 'boolean') {
        throw new Error('instrumentation must be an explicit boolean.');
    }
    const requested = options.scenarios === undefined ? [] : options.scenarios;
    if (!Array.isArray(requested)) throw new Error('scenarios must be an array.');
    if (requested.length && options.instrumentation !== true) {
        throw new Error('Interaction scenarios require explicit instrumentation: true for an unsaved test copy.');
    }
    const items = new Map();
    function collect(entries) {
        for (const item of entries) {
            if (!items.has(item.name)) items.set(item.name, []);
            items.get(item.name).push(item);
            if (item.type === 12) collect(item.content.items || []);
        }
    }
    collect(workbook.items);
    const candidateCount = Array.from(items.values())
        .flat()
        .filter(
            item =>
                (item.type === 3 && (item.content.exportedParameters?.length || item.content.exportParameterName)) ||
                (item.type === 9 &&
                    (item.content.parameters || []).some(parameter => [1, 2].includes(parameter.type) && !parameter.isHiddenWhenLocked)) ||
                (item.type === 11 &&
                    item.content.style !== 'tabs' &&
                    (item.content.links || []).some(link => link.linkTarget === 'parameter'))
        ).length;
    if (!requested.length) {
        return { scenarios: [], bindings: [], probes: [], namespace: '', evidenceMode, candidateCount };
    }
    function safeWrite(name, parameterType) {
        const declarations = Array.from(items.values())
            .flat()
            .filter(item => item.type === 9)
            .flatMap(item => item.content.parameters || [])
            .filter(parameter => parameter.name === name);
        if ([4, 5, 6, 8].includes(parameterType) || declarations.some(parameter => ![1, 2, 10].includes(parameter.type))) {
            throw new Error('Interaction scenarios do not automate resource, subscription, tenant, or time-scope pickers.');
        }
    }
    const source = JSON.stringify(workbook);
    let namespace = 'Workbook validation';
    while (source.includes(namespace)) namespace += 'x';
    let prefix = '__workbook_validation';
    while (source.includes(prefix)) prefix += '_';
    const bindings = new Map();
    const probes = new Map();
    function owner(name, type) {
        const matches = items.get(name) || [];
        if (matches.length !== 1 || matches[0].type !== type)
            throw new Error('An interaction must identify one source item of the required type.');
        if (!bindings.has(name)) {
            const index = bindings.size;
            bindings.set(name, { item: name, begin: `${namespace} begin ${index}`, end: `${namespace} end ${index}` });
        }
        return matches[0];
    }
    function parameter(itemName, name) {
        const item = owner(itemName, 9);
        const matches = (item.content.parameters || []).filter(parameter => parameter.name === name);
        if (matches.length !== 1 || !/^[A-Za-z_$][\w$]*$/.test(name))
            throw new Error('A parameter must identify one valid source declaration.');
        return matches[0];
    }
    function expected(value, captures) {
        if (value && typeof value === 'object') {
            if (Object.prototype.hasOwnProperty.call(value, '$cell')) {
                object(value, ['$cell'], 'Invalid captured-cell reference.');
                object(value.$cell, ['capture', 'column'], 'Invalid captured-cell reference.');
                if (!captures.has(value.$cell.capture) || typeof value.$cell.column !== 'string' || !value.$cell.column.trim()) {
                    throw new Error('A captured-cell reference must identify an earlier or current row capture and a column.');
                }
            } else {
                for (const nested of Object.values(value)) expected(nested, captures);
            }
        } else if (value !== null && !['string', 'number', 'boolean'].includes(typeof value)) {
            throw new Error('Expected values must be JSON values or captured-cell references.');
        }
    }
    const scenarioIds = new Set();
    const scenarios = requested.map(scenario => {
        object(scenario, ['id', 'tab', 'requiresAuthenticated', 'steps', 'panelDefaults'], 'Invalid scenario fields.');
        const scenarioId = id(scenario.id);
        if (scenarioIds.has(scenarioId)) throw new Error('Scenario IDs must be unique.');
        scenarioIds.add(scenarioId);
        const requiresAuthenticated = scenario.requiresAuthenticated === undefined ? true : scenario.requiresAuthenticated;
        if (typeof requiresAuthenticated !== 'boolean' || !Array.isArray(scenario.steps) || !scenario.steps.length) {
            throw new Error('Scenarios require steps and a boolean requiresAuthenticated choice.');
        }
        const panelDefaults = scenario.panelDefaults === undefined ? {} : scenario.panelDefaults;
        object(panelDefaults, ['minRows', 'maxRows', 'columns', 'allowTruncated'], 'Invalid shared scenario panel defaults.');
        normalizePanel({ ...panelDefaults, heading: 'Scenario defaults' }, 'Scenario panel defaults', [
            'heading',
            'minRows',
            'maxRows',
            'columns',
            'allowTruncated'
        ]);
        const captures = new Set();
        const stepIds = new Set();
        const steps = scenario.steps.map(step => {
            object(step, ['id', 'tab', 'action', 'expect'], 'Invalid scenario step fields.');
            const stepId = id(step.id);
            if (stepIds.has(stepId)) throw new Error('Step IDs must be unique within a scenario.');
            stepIds.add(stepId);
            const action = step.action;
            object(
                action,
                ['type', 'item', 'parameter', 'value', 'label', 'linkId', 'row', 'capture'],
                'Invalid interaction action fields.'
            );
            let normalized;
            if (action.type === 'selectRow' || action.type === 'expandRow') {
                object(action, ['type', 'item', 'row', 'capture'], 'Invalid row-action fields.');
                const item = owner(action.item, 3);
                if (action.type === 'selectRow' && !item.content.exportedParameters?.length && !item.content.exportParameterName) {
                    throw new Error('Row selection requires a source query with declared parameter exports.');
                }
                for (const exported of item.content.exportedParameters || []) safeWrite(exported.parameterName, exported.parameterType);
                if (item.content.exportParameterName) safeWrite(item.content.exportParameterName);
                object(action.row, ['index', 'match'], 'Row actions require an explicit row index or column match.');
                if ((action.row.index !== undefined) === (action.row.match !== undefined))
                    throw new Error('Choose exactly one row-selection method.');
                if (action.row.index !== undefined && (!Number.isSafeInteger(action.row.index) || action.row.index < 0))
                    throw new Error('Invalid row index.');
                if (action.row.match !== undefined) {
                    if (
                        !action.row.match ||
                        typeof action.row.match !== 'object' ||
                        Array.isArray(action.row.match) ||
                        !Object.keys(action.row.match).length
                    )
                        throw new Error('Row matches require explicit column expectations.');
                    for (const value of Object.values(action.row.match)) expected(value, captures);
                }
                if (action.capture !== undefined) {
                    if (action.type !== 'selectRow' || captures.has(id(action.capture))) throw new Error('Row capture IDs must be unique.');
                    captures.add(action.capture);
                }
                normalized = { type: action.type, item: action.item, row: action.row, capture: action.capture };
            } else if (action.type === 'setParameter') {
                object(action, ['type', 'item', 'parameter', 'value', 'label'], 'Invalid parameter-action fields.');
                const declaration = parameter(action.item, action.parameter);
                if (![1, 2].includes(declaration.type) || declaration.multiSelect || typeof action.value !== 'string') {
                    throw new Error(
                        'Only explicit single-value text/dropdown parameter changes are supported; resource/account pickers are not automated.'
                    );
                }
                if (action.label !== undefined && typeof action.label !== 'string') throw new Error('Option labels must be strings.');
                let optionLabel = action.label;
                if (optionLabel === undefined && declaration.jsonData) {
                    let data;
                    try {
                        data = JSON.parse(declaration.jsonData);
                    } catch (error) {
                        if (error instanceof SyntaxError)
                            throw new Error('Static parameter options must be valid JSON; values are not logged.');
                        throw error;
                    }
                    if (!Array.isArray(data)) throw new Error('Static parameter options must be an array.');
                    const choice = data
                        .flat()
                        .find(choice =>
                            choice && typeof choice === 'object' ? String(choice.value) === action.value : choice === action.value
                        );
                    if (choice !== undefined) optionLabel = typeof choice === 'object' ? choice.label : choice;
                }
                normalized = {
                    type: action.type,
                    item: action.item,
                    parameter: action.parameter,
                    parameterLabel: declaration.label || declaration.name,
                    parameterType: declaration.type,
                    value: action.value,
                    optionLabel
                };
            } else if (action.type === 'parameterLink') {
                object(action, ['type', 'item', 'linkId'], 'Invalid parameter-link action fields.');
                const item = owner(action.item, 11);
                const matches = (item.content.links || []).filter(link => link.id === action.linkId);
                if (
                    matches.length !== 1 ||
                    matches[0].linkTarget !== 'parameter' ||
                    typeof matches[0].linkLabel !== 'string' ||
                    /[{}]/.test(matches[0].linkLabel)
                ) {
                    throw new Error('A reset/action must identify one source parameter link with a static label.');
                }
                safeWrite(matches[0].cellValue);
                normalized = { type: action.type, item: action.item, linkId: action.linkId, label: matches[0].linkLabel };
            } else {
                throw new Error('Unsupported scenario action; arbitrary clicks, scripts, URLs, and ARM actions are not allowed.');
            }
            object(step.expect, ['tab', 'parameters', 'panels'], 'Invalid interaction expectations.');
            const parameters = step.expect.parameters === undefined ? [] : step.expect.parameters;
            if (!Array.isArray(parameters)) throw new Error('Parameter assertions must be an array.');
            const seen = new Set();
            const assertions = parameters.map(assertion => {
                object(assertion, ['item', 'parameter', 'parse', 'equals', 'contains', 'unchanged'], 'Invalid parameter assertion fields.');
                parameter(assertion.item, assertion.parameter);
                const key = JSON.stringify([assertion.item, assertion.parameter]);
                if (seen.has(key)) throw new Error('Parameter assertions must be unique within a step.');
                seen.add(key);
                const parse = assertion.parse === undefined ? 'text' : assertion.parse;
                if (!['text', 'json'].includes(parse)) throw new Error('Invalid parameter probe parse mode.');
                const comparisons = ['equals', 'contains', 'unchanged'].filter(field =>
                    Object.prototype.hasOwnProperty.call(assertion, field)
                );
                if (comparisons.length !== 1) throw new Error('Choose exactly one parameter assertion comparison.');
                const comparison = comparisons[0];
                if (comparison === 'unchanged') {
                    if (assertion.unchanged !== true) throw new Error('unchanged assertions must be true.');
                } else {
                    expected(assertion[comparison], captures);
                    if (
                        comparison === 'contains' &&
                        (parse !== 'json' ||
                            !assertion.contains ||
                            typeof assertion.contains !== 'object' ||
                            Array.isArray(assertion.contains) ||
                            !Object.keys(assertion.contains).length)
                    )
                        throw new Error('contains requires a nonempty JSON object expectation.');
                }
                if (!probes.has(key)) {
                    probes.set(key, {
                        key,
                        item: assertion.item,
                        parameter: assertion.parameter,
                        heading: `${namespace} parameter ${probes.size}`
                    });
                }
                return { probe: key, parse, comparison, expected: assertion[comparison] };
            });
            if (
                normalized.type === 'setParameter' &&
                !parameters.some(
                    assertion =>
                        assertion.item === normalized.item && assertion.parameter === normalized.parameter && assertion.unchanged !== true
                )
            ) {
                throw new Error('Parameter changes must assert the changed parameter, not only unrelated or unchanged state.');
            }
            if (normalized.type === 'selectRow') {
                const item = items.get(normalized.item)[0];
                const names = (item.content.exportedParameters || []).map(parameter => parameter.parameterName);
                if (item.content.exportParameterName) names.push(item.content.exportParameterName);
                if (!parameters.some(assertion => names.includes(assertion.parameter) && assertion.unchanged !== true)) {
                    throw new Error('Row selection must assert at least one declared parameter export.');
                }
            }
            if (normalized.type === 'parameterLink') {
                const link = items.get(normalized.item)[0].content.links.find(link => link.id === normalized.linkId);
                const tabTarget = Array.from(items.values())
                    .flat()
                    .some(
                        item =>
                            item.type === 11 &&
                            item.content.style === 'tabs' &&
                            (item.content.links || []).some(candidate => candidate.cellValue === link.cellValue)
                    );
                if (
                    !parameters.some(assertion => assertion.parameter === link.cellValue && assertion.unchanged !== true) &&
                    !(tabTarget && step.expect.tab !== undefined)
                ) {
                    throw new Error('A parameter link must assert its target parameter or its declared tab transition.');
                }
            }
            const panelRequests = step.expect.panels === undefined ? [] : step.expect.panels;
            if (!Array.isArray(panelRequests)) throw new Error('Step panels must be an array.');
            const panels = panelRequests.map(panel => {
                if (panel.tab !== undefined) throw new Error('Step panels apply to the observed current tab; use expect.tab instead.');
                const result = normalizePanel(
                    { ...panelDefaults, ...panel, tab: step.expect.tab || step.tab || scenario.tab || tabs[0] },
                    'Scenario panel',
                    ['tab', 'heading', 'minRows', 'maxRows', 'columns', 'allowTruncated', 'cells']
                );
                for (const cell of result.cells) expected(cell.equals, captures);
                return result;
            });
            if (!assertions.length && !panels.length)
                throw new Error('Interaction steps require parameter or panel assertions, not only tab navigation.');
            return {
                id: stepId,
                tab: tab(step.tab),
                action: normalized,
                expect: { tab: tab(step.expect.tab), parameters: assertions, panels }
            };
        });
        return { id: scenarioId, tab: tab(scenario.tab), requiresAuthenticated, steps };
    });
    if (scenarios.length && options.screenshots && options.screenshots.redaction && options.screenshots.redaction !== 'auto') {
        throw new Error(
            'Instrumented scenario captures require auto redaction because private parameter probes may contain sensitive values.'
        );
    }
    const bindingList = Array.from(bindings.values());
    const probeList = Array.from(probes.values());
    let importSource;
    if (scenarios.length) {
        const copy = JSON.parse(source);
        let sequence = 0;
        function marker(heading) {
            return { type: 1, name: `${prefix}_${sequence++}`, content: { json: `### ${heading}` } };
        }
        function instrument(entries) {
            const output = [];
            for (const item of entries) {
                const binding = bindings.get(item.name);
                if (binding) output.push(marker(binding.begin));
                if (item.type === 12) item.content.items = instrument(item.content.items || []);
                output.push(item);
                if (binding) output.push(marker(binding.end));
                for (const probe of probeList.filter(probe => probe.item === item.name)) {
                    output.push({
                        type: 1,
                        name: `${prefix}_${sequence++}`,
                        content: { json: `### ${probe.heading}\n\n\`\`\`text\n{${probe.parameter}:base64}\n\`\`\`` }
                    });
                }
            }
            return output;
        }
        copy.items = instrument(copy.items);
        importSource = JSON.stringify(copy, null, 2) + '\n';
    }
    return { scenarios, bindings: bindingList, probes: probeList, namespace, evidenceMode, importSource, candidateCount };
}

function initializeInteractionState(body, settings) {
    const document = body.ownerDocument;
    if (document.__workbookValidationInteractions || document.body !== body || !body.isConnected) {
        throw new Error('Cannot initialize a private interaction observation scope.');
    }
    function normalize(text) {
        return (text || '')
            .replace(/^[\uE000-\uF8FF\s]+/, '')
            .replace(/\s+/g, ' ')
            .trim();
    }
    function read(probeKey, parse) {
        const probe = settings.probes.find(probe => probe.key === probeKey);
        if (!probe) return { ok: false, code: 'parameter-probe-unavailable' };
        const headings = Array.from(document.querySelectorAll('h1,h2,h3,h4,h5,h6,[role="heading"]')).filter(
            element => normalize(element.textContent) === probe.heading
        );
        if (headings.length !== 1) return { ok: false, code: 'parameter-probe-unavailable' };
        const panel = headings[0].closest('[class*="styleWrapper-maximized"]');
        const code = panel?.querySelectorAll('pre code');
        if (!code || code.length !== 1) return { ok: false, code: 'parameter-probe-unavailable' };
        let value;
        try {
            const bytes = Uint8Array.from(atob(code[0].textContent.trim()), character => character.charCodeAt(0));
            value = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
        } catch (_error) {
            return { ok: false, code: 'parameter-probe-unreadable' };
        }
        if (parse === 'json') {
            try {
                value = JSON.parse(value);
            } catch (_error) {
                return { ok: false, code: 'parameter-json-invalid' };
            }
        }
        return { ok: true, value };
    }
    function resolve(value) {
        if (value && typeof value === 'object') {
            if (value.$cell) {
                const row = state.captures.get(value.$cell.capture);
                if (!row || !Object.prototype.hasOwnProperty.call(row, value.$cell.column))
                    throw new Error('Captured-cell reference is unavailable.');
                return row[value.$cell.column];
            }
            if (Array.isArray(value)) return value.map(resolve);
            return Object.fromEntries(Object.entries(value).map(([key, nested]) => [key, resolve(nested)]));
        }
        return value;
    }
    function same(actual, expected, subset = false) {
        if (actual === expected) return true;
        if (
            !actual ||
            !expected ||
            typeof actual !== 'object' ||
            typeof expected !== 'object' ||
            Array.isArray(actual) !== Array.isArray(expected)
        )
            return false;
        const keys = Object.keys(expected);
        if ((!subset || Array.isArray(expected)) && Object.keys(actual).length !== keys.length) return false;
        return keys.every(key => Object.prototype.hasOwnProperty.call(actual, key) && same(actual[key], expected[key], subset));
    }
    const state = {
        namespace: settings.namespace,
        body,
        root: document.documentElement,
        captures: new Map(),
        snapshots: new Map(),
        targets: new Map(),
        normalize,
        read,
        resolve,
        same
    };
    document.__workbookValidationInteractions = state;
}

function prepareInteractionStep(body, settings) {
    const state = body.ownerDocument.__workbookValidationInteractions;
    if (!state || state.namespace !== settings.namespace || state.body !== body || !body.isConnected) {
        return { ok: false, code: 'interaction-document-unavailable' };
    }
    if (settings.startScenario) state.captures.clear();
    state.snapshots.clear();
    return { ok: true };
}

async function bindInteractionTarget(body, settings) {
    function find() {
        const document = body.ownerDocument;
        const state = document.__workbookValidationInteractions;
        if (!state || state.namespace !== settings.namespace || state.body !== body || !body.isConnected) {
            return { ok: false, code: 'interaction-document-unavailable' };
        }
        const normalize = state.normalize;
        const headings = Array.from(document.querySelectorAll('h1,h2,h3,h4,h5,h6,[role="heading"]'));
        const begin = headings.filter(element => normalize(element.textContent) === settings.binding.begin);
        const end = headings.filter(element => normalize(element.textContent) === settings.binding.end);
        if (begin.length !== 1 || end.length !== 1 || !(begin[0].compareDocumentPosition(end[0]) & 4))
            return { ok: false, code: 'source-boundary-unavailable' };
        function visible(element) {
            const style = document.defaultView.getComputedStyle(element);
            return element.getClientRects().length > 0 && style.display !== 'none' && style.visibility !== 'hidden';
        }
        function inside(element) {
            return visible(element) && begin[0].compareDocumentPosition(element) & 4 && element.compareDocumentPosition(end[0]) & 4;
        }
        function label(element) {
            const labelled = (element.getAttribute('aria-labelledby') || '')
                .split(/\s+/)
                .filter(Boolean)
                .map(id => document.getElementById(id)?.textContent || '')
                .join(' ');
            return normalize(
                element.getAttribute('aria-label') ||
                    labelled ||
                    Array.from(element.labels || [])
                        .map(label => label.textContent)
                        .join(' ') ||
                    element.textContent
            );
        }
        function safe(element) {
            const href = element.getAttribute('href');
            return (
                !element.disabled &&
                element.getAttribute('aria-disabled') !== 'true' &&
                (href === null || href === '' || href === '#') &&
                element.getAttribute('type') !== 'password'
            );
        }
        let target;
        let kind;
        const action = settings.action;
        if (action.type === 'selectRow' || action.type === 'expandRow') {
            const grids = Array.from(body.querySelectorAll('[role="grid"]')).filter(inside);
            if (grids.length !== 1) return { ok: false, code: 'source-grid-unavailable' };
            const headers = Array.from(grids[0].querySelectorAll('[role="columnheader"]'), element => normalize(element.textContent));
            const rows = Array.from(grids[0].querySelectorAll('[role="row"]')).filter(
                row =>
                    visible(row) &&
                    row.querySelector('[role="gridcell"]') &&
                    Boolean(row.querySelector('[aria-expanded]')) === (action.type === 'expandRow')
            );
            const candidates = action.row.index !== undefined ? rows.slice(action.row.index, action.row.index + 1) : rows;
            const entries = candidates.map(row => {
                const cells = Array.from(row.querySelectorAll('[role="gridcell"]'));
                if (cells.length !== headers.length) return { row, values: null };
                const keys = headers.filter(Boolean);
                if (new Set(keys).size !== keys.length) return { row, values: null };
                return {
                    row,
                    values: Object.fromEntries(
                        headers.flatMap((header, index) => (header ? [[header, normalize(cells[index].textContent)]] : []))
                    )
                };
            });
            const matches =
                action.row.index !== undefined
                    ? entries
                    : entries.filter(
                          entry =>
                              entry.values &&
                              Object.entries(action.row.match).every(
                                  ([column, expected]) =>
                                      Object.prototype.hasOwnProperty.call(entry.values, column) &&
                                      entry.values[column] === state.resolve(expected)
                              )
                      );
            if (matches.length !== 1 || !matches[0].values) return { ok: false, code: 'source-row-unavailable' };
            const row = matches[0].row;
            const controls = Array.from(
                row.querySelectorAll(
                    action.type === 'expandRow' ? 'button[aria-expanded="false"]' : 'input[type="checkbox"],[role="checkbox"]'
                )
            ).filter(element => visible(element) && safe(element));
            if (controls.length !== 1) return { ok: false, code: 'safe-row-control-unavailable' };
            if (
                action.type === 'selectRow' &&
                (row.getAttribute('aria-selected') === 'true' || controls[0].checked || controls[0].getAttribute('aria-checked') === 'true')
            ) {
                return { ok: false, code: 'row-already-selected' };
            }
            if (action.capture) state.captures.set(action.capture, matches[0].values);
            target = controls[0];
            kind = action.type === 'selectRow' ? 'checkbox' : 'button';
        } else if (action.type === 'parameterLink') {
            const matches = Array.from(body.querySelectorAll('button,[role="button"],[role="menuitem"],a')).filter(
                element => inside(element) && safe(element) && label(element) === normalize(action.label)
            );
            if (matches.length !== 1) return { ok: false, code: 'source-link-unavailable' };
            target = matches[0];
            kind = 'button';
        } else {
            const candidates = Array.from(body.querySelectorAll('select,input,textarea,button,[role="combobox"],[role="button"]')).filter(
                element =>
                    inside(element) &&
                    safe(element) &&
                    (label(element) === normalize(action.parameterLabel) ||
                        label(element).startsWith(normalize(action.parameterLabel) + ' ='))
            );
            if (candidates.length !== 1) return { ok: false, code: 'source-parameter-control-unavailable' };
            const control = candidates[0];
            if (settings.option) {
                const ids = (control.getAttribute('aria-controls') || control.getAttribute('aria-owns') || '').split(/\s+/).filter(Boolean);
                if (ids.length !== 1 || typeof action.optionLabel !== 'string') return { ok: false, code: 'owned-option-list-unavailable' };
                const list = document.getElementById(ids[0]);
                if (!list || !visible(list) || !['listbox', 'menu'].includes(list.getAttribute('role'))) {
                    return { ok: false, code: 'owned-option-list-unavailable' };
                }
                const options = Array.from(list.querySelectorAll('[role="option"],[role="menuitemradio"]')).filter(
                    element => visible(element) && safe(element) && label(element) === normalize(action.optionLabel)
                );
                if (options.length !== 1) return { ok: false, code: 'owned-option-unavailable' };
                target = options[0];
                kind = 'button';
            } else {
                target = control;
                kind =
                    control.tagName === 'SELECT'
                        ? 'select'
                        : ['INPUT', 'TEXTAREA'].includes(control.tagName) && action.parameterType === 1
                        ? 'textbox'
                        : 'picker';
            }
        }
        if (!state.targets.has(target)) state.targets.set(target, target.getAttribute('data-workbook-validation-action'));
        target.setAttribute('data-workbook-validation-action', settings.token);
        return { ok: true, kind };
    }
    const deadline = Date.now() + settings.timeout;
    for (;;) {
        const result = find();
        if (result.ok || ['interaction-document-unavailable', 'row-already-selected'].includes(result.code) || Date.now() >= deadline)
            return result;
        await new Promise(resolve => body.ownerDocument.defaultView.setTimeout(resolve, Math.min(50, Math.max(1, deadline - Date.now()))));
    }
}

function waitForInteractionParameters(body, settings) {
    return new Promise(resolve => {
        const document = body.ownerDocument;
        const state = document.__workbookValidationInteractions;
        const deadline = Date.now() + settings.timeout;
        let timer;
        const observer = new document.defaultView.MutationObserver(inspect);
        function finish(result) {
            observer.disconnect();
            document.defaultView.clearTimeout(timer);
            resolve(result);
        }
        function inspect() {
            try {
                inspectState();
            } catch (_error) {
                finish({ ok: false, code: 'parameter-observation-failed' });
            }
        }
        function inspectState() {
            if (
                !state ||
                state.namespace !== settings.namespace ||
                state.body !== body ||
                state.root !== document.documentElement ||
                !body.isConnected
            ) {
                finish({ ok: false, code: 'interaction-document-unavailable' });
                return;
            }
            let code;
            for (const assertion of settings.assertions) {
                if (settings.snapshot && assertion.comparison !== 'unchanged') continue;
                const result = state.read(assertion.probe, assertion.parse);
                if (!result.ok) {
                    code = result.code;
                    break;
                }
                if (settings.snapshot) {
                    state.snapshots.set(assertion.probe, result.value);
                    continue;
                }
                let expected;
                try {
                    expected =
                        assertion.comparison === 'unchanged' ? state.snapshots.get(assertion.probe) : state.resolve(assertion.expected);
                } catch (_error) {
                    code = 'capture-reference-unavailable';
                    break;
                }
                if (!state.same(result.value, expected, assertion.comparison === 'contains')) {
                    code = 'parameter-assertion-mismatch';
                    break;
                }
            }
            if (!code) {
                finish({ ok: true });
                return;
            }
            if (Date.now() >= deadline) {
                finish({ ok: false, code });
                return;
            }
            document.defaultView.clearTimeout(timer);
            timer = document.defaultView.setTimeout(inspect, Math.min(50, Math.max(1, deadline - Date.now())));
        }
        observer.observe(body, { childList: true, subtree: true, characterData: true });
        inspect();
    });
}

function clearInteractionState(body, namespace) {
    const document = body.ownerDocument;
    const state = document.__workbookValidationInteractions;
    if (!state || state.namespace !== namespace || state.body !== body)
        throw new Error('The private interaction document is unavailable for cleanup.');
    state.captures.clear();
    state.snapshots.clear();
    for (const [element, previous] of state.targets) {
        if (previous === null) element.removeAttribute('data-workbook-validation-action');
        else element.setAttribute('data-workbook-validation-action', previous);
    }
    state.targets.clear();
    delete document.__workbookValidationInteractions;
}

async function runInteractionScenarios(page, frame, plan, helpers) {
    if (!plan.interactions.scenarios.length) {
        return {
            scenarios: [],
            needsCloserLook: plan.interactions.candidateCount
                ? [{ code: 'interaction-scenarios-not-configured', items: plan.interactions.candidateCount }]
                : []
        };
    }
    const body = await frame.locator('body').elementHandle();
    if (!body) throw new Error('The interaction document is unavailable.');
    const settings = { namespace: plan.interactions.namespace, probes: plan.interactions.probes };
    const scenarios = [];
    const needsCloserLook = [];
    let initialized = false;
    let stopped = false;
    function requireResult(result) {
        if (!result.ok) {
            const error = new Error('A requested interaction observation or source-bound control was unavailable.');
            error.validationCode = result.code;
            throw error;
        }
    }
    async function verifyTenant() {
        try {
            await helpers.verifyTenant();
        } catch (_error) {
            const error = new Error('Interaction execution paused because the confirmed tenant/session could not be verified.');
            error.validationCode = 'tenant-session-unverified';
            throw error;
        }
    }
    try {
        await verifyTenant();
        await body.evaluate(initializeInteractionState, settings);
        initialized = true;
        for (const scenario of plan.interactions.scenarios) {
            const result = { id: scenario.id, steps: [], status: 'not-run', qualification: 'needs-closer-look' };
            scenarios.push(result);
            let startScenario = true;
            for (const step of scenario.steps) {
                const outcome = {
                    id: step.id,
                    status: 'not-run',
                    parameterAssertions: 0,
                    panelAssertions: 0,
                    cellAssertions: 0,
                    dataContracts: 0
                };
                result.steps.push(outcome);
                if (stopped) {
                    needsCloserLook.push({ scenario: scenario.id, step: step.id, code: 'prior-step-did-not-pass' });
                    continue;
                }
                try {
                    outcome.phase = 'verify-session-before-action';
                    await verifyTenant();
                    const initialTab = step.tab === undefined && startScenario ? scenario.tab : step.tab;
                    outcome.phase = 'setup-view';
                    if (initialTab !== undefined) await helpers.navigate(initialTab);
                    outcome.phase = 'snapshot-parameters';
                    requireResult(await body.evaluate(prepareInteractionStep, { ...settings, startScenario }));
                    startScenario = false;
                    requireResult(
                        await body.evaluate(waitForInteractionParameters, {
                            ...settings,
                            assertions: step.expect.parameters,
                            timeout: plan.timeout,
                            snapshot: true
                        })
                    );
                    const binding = plan.interactions.bindings.find(binding => binding.item === step.action.item);
                    const token = `action-${Date.now().toString(36)}-${Math.random()
                        .toString(36)
                        .slice(2)}`;
                    const actionSettings = { ...settings, binding, action: step.action, token, timeout: plan.timeout };
                    outcome.phase = 'resolve-source-control';
                    const control = await body.evaluate(bindInteractionTarget, actionSettings);
                    requireResult(control);
                    const target = frame.locator(`[data-workbook-validation-action="${token}"]`);
                    outcome.phase = 'activate-source-control';
                    if (control.kind === 'select') {
                        await target.selectOption({ value: step.action.value }, { timeout: plan.timeout });
                    } else if (control.kind === 'textbox') {
                        await target.fill(step.action.value, { timeout: plan.timeout });
                        await helpers.activate(target, plan.timeout);
                    } else {
                        await helpers.activate(target, plan.timeout, control.kind === 'checkbox' ? 'Space' : 'Enter');
                        if (control.kind === 'picker') {
                            const optionToken = `${token}-option`;
                            requireResult(
                                await body.evaluate(bindInteractionTarget, { ...actionSettings, token: optionToken, option: true })
                            );
                            await helpers.activate(frame.locator(`[data-workbook-validation-action="${optionToken}"]`), plan.timeout);
                        }
                    }
                    outcome.phase = 'verify-session-after-action';
                    await verifyTenant();
                    outcome.phase = 'observe-resulting-view';
                    if (step.expect.tab !== undefined) await helpers.assertTab(step.expect.tab);
                    outcome.phase = 'observe-parameters';
                    requireResult(
                        await body.evaluate(waitForInteractionParameters, {
                            ...settings,
                            assertions: step.expect.parameters,
                            timeout: plan.timeout
                        })
                    );
                    outcome.phase = 'observe-result-panels';
                    for (const panel of step.expect.panels) {
                        try {
                            const checked = await helpers.checkPanel(panel);
                            if (checked.grid) outcome.dataContracts++;
                        } catch (_error) {
                            const error = new Error('A requested interaction result panel or rendered-cell contract failed.');
                            error.validationCode = 'panel-contract-failed';
                            throw error;
                        }
                    }
                    outcome.parameterAssertions = step.expect.parameters.length;
                    outcome.panelAssertions = step.expect.panels.length;
                    outcome.cellAssertions = step.expect.panels.reduce((count, panel) => count + panel.cells.length, 0);
                    outcome.phase = 'capture-result';
                    await helpers.capture(step.expect.panels.flatMap(panel => [panel.heading, ...(panel.columns || [])]));
                    outcome.phase = 'verify-session-after-observations';
                    await verifyTenant();
                    outcome.status = 'passed';
                    outcome.phase = 'complete';
                } catch (error) {
                    const code = error.validationCode || 'interaction-interrupted';
                    outcome.status = ['parameter-assertion-mismatch', 'parameter-json-invalid', 'panel-contract-failed'].includes(code)
                        ? 'failed'
                        : 'needs-closer-look';
                    outcome.code = code;
                    outcome.errorType = error.name || 'Error';
                    needsCloserLook.push({ scenario: scenario.id, step: step.id, code });
                    if (code === 'screenshot-capture-failed') outcome.discardLocalCaptures = true;
                    stopped = true;
                }
            }
            result.status = result.steps.every(step => step.status === 'passed')
                ? 'passed'
                : result.steps.some(step => step.status === 'failed')
                ? 'failed'
                : 'needs-closer-look';
            if (result.status === 'passed') {
                if (scenario.requiresAuthenticated && plan.interactions.evidenceMode !== 'authenticated') {
                    for (const step of scenario.steps)
                        needsCloserLook.push({ scenario: scenario.id, step: step.id, code: 'authenticated-validation-pending' });
                    result.qualification = 'needs-authenticated-validation';
                } else if (plan.interactions.evidenceMode === 'unspecified') {
                    needsCloserLook.push({ scenario: scenario.id, code: 'execution-evidence-unspecified' });
                } else {
                    result.qualification =
                        plan.interactions.evidenceMode === 'authenticated' ? 'authenticated-instrumented' : 'synthetic-contract';
                }
            }
        }
    } finally {
        try {
            if (initialized) await body.evaluate(clearInteractionState, settings.namespace);
        } finally {
            await body.dispose();
        }
    }
    return { scenarios, needsCloserLook };
}

function pendingInteractionReview(plan, code) {
    const pending = plan.interactions.scenarios.flatMap(scenario =>
        scenario.steps.map(step => ({ scenario: scenario.id, step: step.id, code }))
    );
    if (!pending.length && plan.interactions.candidateCount) {
        pending.push({ code: 'interaction-scenarios-not-configured', items: plan.interactions.candidateCount });
    }
    return pending;
}

module.exports = {
    normalizeCellAssertions,
    planInteractionScenarios,
    initializeInteractionState,
    prepareInteractionStep,
    bindInteractionTarget,
    waitForInteractionParameters,
    clearInteractionState,
    runInteractionScenarios,
    pendingInteractionReview
};
