const fs = require('fs');
const { URL } = require('url');
const crypto = require('crypto');
const { extractWorkbookSource } = require('./workbookSource');
const interactionHelpers = require('./workbookInteractions');
const { normalizeCellAssertions, planInteractionScenarios, runInteractionScenarios, pendingInteractionReview } = interactionHelpers;

function isAzurePortalUrl(value) {
    return /^https:\/\/portal\.azure\.(com|us|cn)(\/|$)/.test(value);
}

function normalizeTenantSelection(value) {
    if (value === undefined) return undefined;
    if (!value || typeof value !== 'object' || Array.isArray(value) ||
        Object.keys(value).some(key => !['id', 'confirmed'].includes(key)) ||
        typeof value.id !== 'string' ||
        !/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(value.id.trim()) ||
        (value.confirmed !== undefined && typeof value.confirmed !== 'boolean')) {
        throw new Error('tenant must contain a tenant GUID and an explicit boolean confirmed choice.');
    }
    return { id: value.id.trim().toLowerCase(), confirmed: value.confirmed === true };
}

function requireConfirmedTenant(value) {
    const tenant = normalizeTenantSelection(value);
    if (!tenant?.confirmed) {
        throw new Error('PAUSED: Ask the user which Azure tenant to sign in to and wait for explicit selection and confirmation, including in autopilot. Do not choose the current/default tenant.');
    }
    return tenant;
}

async function verifySelectedTenant(page, value) {
    const tenant = requireConfirmedTenant(value);
    if (!isAzurePortalUrl(page.url())) {
        throw new Error('Sign in to Azure using the selected tenant before running portal validation.');
    }
    const account = page.getByRole('button', { name: /^Account menu/ });
    if (await account.count() !== 1) {
        throw new Error('PAUSED: Cannot verify the selected tenant from the portal account menu.');
    }
    const titles = await account.locator('[title]').evaluateAll(elements => elements.map(element => element.getAttribute('title') || ''));
    const ids = new Set(titles.flatMap(title => {
        const directory = title.match(/\bDirectory:([\s\S]*)/i);
        return directory ? Array.from(directory[1].matchAll(
            /\(([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})\)/gi
        ), match => match[1].toLowerCase()) : [];
    }));
    if (ids.size !== 1 || !ids.has(tenant.id)) {
        throw new Error('PAUSED: The signed-in tenant is different from, or cannot be matched to, the user-confirmed tenant. Ask the user to select it; do not switch automatically.');
    }
}

function normalizeScreenshotOptions(value) {
    if (value === undefined || value === false) return false;
    if (!value || typeof value !== 'object' || Array.isArray(value) ||
        Object.keys(value).some(key => !['directory', 'maskSelectors', 'redaction', 'allowSensitiveCapture'].includes(key))) {
        throw new Error('screenshots must be an object with supported options only.');
    }
    const directory = value.directory;
    if (typeof directory !== 'string' || !directory.trim() || /[\u0000-\u001F]/.test(directory) ||
        /^(?:[\\/]{2}|[a-z][a-z0-9+.-]*:)/i.test(directory.replace(/^[a-z]:[\\/]/i, '')) ||
        directory.split(/[\\/]/).includes('..')) {
        throw new Error('screenshots.directory must be a local directory without URLs, network paths, or parent traversal.');
    }
    const maskSelectors = value.maskSelectors === undefined ? [] : value.maskSelectors;
    if (!Array.isArray(maskSelectors) || maskSelectors.some(selector => typeof selector !== 'string' || !selector.trim())) {
        throw new Error('screenshots.maskSelectors must be an array of non-empty CSS selectors.');
    }
    const redaction = value.redaction === undefined ? 'auto' : value.redaction;
    const allowSensitiveCapture = value.allowSensitiveCapture === undefined ? false : value.allowSensitiveCapture;
    if (!['auto', 'manual', 'ai-assisted', 'none'].includes(redaction) || typeof allowSensitiveCapture !== 'boolean') {
        throw new Error('Choose auto, manual, ai-assisted, or none redaction and a boolean allowSensitiveCapture choice.');
    }
    if (redaction !== 'auto' && !allowSensitiveCapture) {
        throw new Error('PAUSED: Non-auto screenshots can expose sensitive content. Obtain explicit approval and set allowSensitiveCapture to true; never disable redaction automatically.');
    }
    if (['manual', 'ai-assisted'].includes(redaction) && !maskSelectors.length) {
        throw new Error('Manual and AI-assisted redaction require explicitly reviewed maskSelectors. No AI service is called automatically.');
    }
    if (redaction === 'none' && maskSelectors.length) {
        throw new Error('Unredacted mode cannot silently ignore maskSelectors; use a selective redaction mode instead.');
    }
    return { directory, maskSelectors, redaction, allowSensitiveCapture };
}

function createValidationPlan(workbookSource, options = {}) {
    function checkObject(value, label, keys) {
        if (!value || typeof value !== 'object' || Array.isArray(value)) {
            throw new Error(`${label} must be an object.`);
        }
        if (keys && Object.keys(value).some(key => !keys.includes(key))) {
            throw new Error(`${label} contains an unsupported option.`);
        }
    }

    function label(value, name) {
        if (typeof value !== 'string' || !value.trim()) {
            throw new Error(`${name} must be a non-empty string.`);
        }
        return value.replace(/\s+/g, ' ').trim();
    }

    function labels(values, name) {
        if (!Array.isArray(values)) {
            throw new Error(`${name} must be an array.`);
        }
        const result = values.map(value => label(value, name));
        if (new Set(result).size !== result.length) {
            throw new Error(`${name} must contain unique labels.`);
        }
        return result;
    }

    if (typeof workbookSource !== 'string' || !workbookSource.trim()) {
        throw new Error('Workbook source must be a non-empty JSON string.');
    }
    const source = workbookSource.replace(/^\uFEFF/, '').replace(/\r\n/g, '\n');
    let workbook;
    try {
        workbook = JSON.parse(source);
    } catch (error) {
        if (error instanceof SyntaxError) {
            throw new Error('Workbook source must be valid JSON.');
        }
        throw error;
    }
    if (!workbook || workbook.version !== 'Notebook/1.0' || !Array.isArray(workbook.items)) {
        throw new Error('Expected a Notebook/1.0 workbook with an items array.');
    }
    checkObject(options, 'Browser validation options',
        ['tabs', 'panels', 'deferred', 'timeout', 'screenshots', 'tenant', 'scenarios', 'instrumentation', 'evidenceMode']);
    const timeout = options.timeout === undefined ? 30000 : options.timeout;
    if (!Number.isSafeInteger(timeout) || timeout < 1 || timeout > 120000) {
        throw new Error('timeout must be an integer between 1 and 120000 milliseconds.');
    }
    const screenshots = normalizeScreenshotOptions(options.screenshots);
    const tenant = normalizeTenantSelection(options.tenant);

    const links = [];
    const tabsets = [];
    const itemNames = new Map();
    const sourceDiagnostics = [];
    let itemCount = 0;
    function visit(items, inheritedGlobals) {
        if (!Array.isArray(items)) {
            throw new Error('Workbook group items must be an array.');
        }
        const globals = new Map(inheritedGlobals);
        for (const item of items) {
            checkObject(item, 'Workbook item');
            itemCount++;
            itemNames.set(item.name, (itemNames.get(item.name) || 0) + 1);
            const content = item.content || {};
            if (item.type === 9) {
                const parameters = content.parameters || [];
                if (!Array.isArray(parameters)) {
                    throw new Error('Workbook parameters must be an array.');
                }
                for (const parameter of parameters) {
                    if (parameter.isGlobal === true) {
                        globals.set(parameter.name, parameter);
                    }
                }
            }
            if (item.type === 11) {
                const itemLinks = content.links || [];
                if (!Array.isArray(itemLinks)) {
                    throw new Error('Workbook links must be an array.');
                }
                if (content.style === 'tabs') {
                    tabsets.push(itemLinks);
                }
                for (const link of itemLinks) {
                    links.push({ item, link, globals: new Map(globals) });
                }
            }
            if (item.type === 3) {
                if ((content.gridSettings?.formatters || []).some(formatter =>
                    (formatter.formatOptions?.thresholdsGrid || []).some(threshold =>
                        ['operator', 'thresholdValue', 'representation', 'text'].some(field =>
                            threshold[field] !== undefined && typeof threshold[field] !== 'string')))) {
                    sourceDiagnostics.push({ code: 'non-string-threshold', itemIndex: itemCount - 1 });
                }
                const inputs = new Set(Array.from((content.query || '').matchAll(
                    /\{([A-Za-z_$][\w$]*)(?::[^}]+)?\}/g
                ), match => match[1]));
                const exports = content.exportedParameters || (content.exportParameterName ?
                    [{ parameterName: content.exportParameterName }] : []);
                if (exports.some(parameter => inputs.has(parameter.parameterName) && globals.has(parameter.parameterName))) {
                    sourceDiagnostics.push({ code: 'global-input-export-cycle-risk', itemIndex: itemCount - 1 });
                }
            }
            if (item.type === 12) {
                const childGlobals = visit(content.items || [], globals);
                if (content.exportParameters === true) {
                    for (const [name, parameter] of childGlobals) {
                        globals.set(name, parameter);
                    }
                }
            }
        }
        return globals;
    }
    visit(workbook.items, new Map());

    const primaryTabs = tabsets[0] || [];
    if (tabsets.some(tabset => tabset.some(link => link.linkTarget !== 'parameter'))) {
        throw new Error('Automatic tab navigation supports parameter links only.');
    }
    if (options.tabs === undefined && primaryTabs.some(link => /[{}]/.test(link.linkLabel))) {
        throw new Error('Provide explicit tabs when tab labels contain parameter substitutions.');
    }
    const tabs = labels(options.tabs === undefined ? primaryTabs.map(link => link.linkLabel) : options.tabs, 'tabs');
    if ((!primaryTabs.length && tabs.length) || (primaryTabs.length && !tabs.length)) {
        throw new Error('tabs must describe the primary parameter-driven tabset.');
    }
    function panelCheck(check, name, keys) {
        checkObject(check, name, keys);
        const heading = label(check.heading, 'heading');
        const tab = check.tab === undefined ? tabs[0] : label(check.tab, 'tab');
        if (tab !== undefined && !tabs.includes(tab)) {
            throw new Error('A panel tab must belong to the primary tabset.');
        }
        for (const field of ['minRows', 'maxRows']) {
            if (check[field] !== undefined && (!Number.isSafeInteger(check[field]) || check[field] < 0)) {
                throw new Error(`${field} must be a non-negative integer.`);
            }
        }
        if (check.minRows !== undefined && check.maxRows !== undefined && check.minRows > check.maxRows) {
            throw new Error('minRows must not exceed maxRows.');
        }
        const columns = check.columns === undefined ? undefined : labels(check.columns, 'columns');
        if (columns && !columns.length) throw new Error('columns must contain at least one label.');
        const allowTruncated = check.allowTruncated === undefined ? false : check.allowTruncated;
        if (typeof allowTruncated !== 'boolean') throw new Error('allowTruncated must be a boolean.');
        const cells = normalizeCellAssertions(check.cells);
        return { tab, heading, minRows: check.minRows, maxRows: check.maxRows, columns, allowTruncated, cells };
    }
    const panelKeys = ['tab', 'heading', 'minRows', 'maxRows', 'columns', 'allowTruncated', 'cells'];
    const requestedPanels = options.panels === undefined ? [] : options.panels;
    if (!Array.isArray(requestedPanels)) throw new Error('panels must be an array.');
    const panels = requestedPanels.map(check => panelCheck(check, 'Panel check', panelKeys));
    for (const panel of panels) {
        if (panel.cells.some(cell => typeof cell.equals !== 'string')) throw new Error('Captured-cell references require an interaction scenario.');
    }
    if (new Set(panels.map(check => JSON.stringify([check.tab, check.heading]))).size !== panels.length) {
        throw new Error('panels must have unique tab and heading pairs.');
    }
    const requested = options.deferred === undefined ? [] : options.deferred;
    if (!Array.isArray(requested)) {
        throw new Error('deferred must be an array.');
    }
    const deferred = requested.map(check => {
        const panel = panelCheck(check, 'Deferred-content check', [...panelKeys, 'trigger', 'hideTriggerAfterLoad']);
        if (panel.cells.some(cell => typeof cell.equals !== 'string')) throw new Error('Captured-cell references require an interaction scenario.');
        const trigger = label(check.trigger, 'trigger');
        const hideTriggerAfterLoad = check.hideTriggerAfterLoad === undefined ? false : check.hideTriggerAfterLoad;
        if (typeof hideTriggerAfterLoad !== 'boolean') {
            throw new Error('hideTriggerAfterLoad must be a boolean.');
        }
        const matches = links.filter(entry => typeof entry.link.linkLabel === 'string' &&
            label(entry.link.linkLabel, 'Link label') === trigger);
        if (matches.length !== 1 || matches[0].link.linkTarget !== 'parameter') {
            throw new Error(`Trigger "${trigger}" must identify one parameter link, not an external or ARM action.`);
        }
        const producer = matches[0];
        const identity = { itemName: producer.item.name, linkId: producer.link.id };
        if (Object.values(identity).some(value => typeof value !== 'string' || !value.trim() || /[\u0000-\u001F]/.test(value)) ||
            itemNames.get(identity.itemName) !== 1 || links.filter(entry => entry.link.id === identity.linkId).length !== 1) {
            throw new Error(`Trigger "${trigger}" requires a unique producer name and link id.`);
        }
        if (hideTriggerAfterLoad &&
            producer.item.conditionalVisibility?.parameterName === producer.link.cellValue &&
            !producer.globals.has(producer.link.cellValue)) {
            throw new Error(`Trigger "${trigger}" must declare its visibility parameter as global before the producer.`);
        }
        return { ...panel, trigger, producer: identity, hideTriggerAfterLoad };
    });

    const groups = new Map();
    for (const check of deferred) {
        const key = JSON.stringify([check.tab, check.trigger]);
        if (!groups.has(key)) {
            groups.set(key, { tab: check.tab, trigger: check.trigger, producer: check.producer, checks: [] });
        }
        groups.get(key).checks.push(check);
    }
    const interactions = planInteractionScenarios(workbook, options, tabs, panelCheck);
    return { source, importSource: interactions.importSource || source, itemCount, tabs, panels, deferred,
        deferredGroups: Array.from(groups.values()), interactions, sourceDiagnostics, timeout, screenshots, tenant };
}

function markScreenshotMasks(body, settings) {
    const document = body.ownerDocument;
    if (document.querySelector('[data-workbook-validation-mask],[data-workbook-validation-label],[data-workbook-validation-capture],[data-workbook-validation-style]')) {
        throw new Error('A previous screenshot mask is still present; refusing to capture.');
    }
    const automatic = settings.redaction === undefined || settings.redaction === 'auto';
    const elements = new Set(automatic ? body.querySelectorAll(
        'input,textarea,select,[contenteditable="true"],[role="textbox"],[role="combobox"],[role="searchbox"],' +
        '[role="gridcell"],[role="rowheader"],svg,canvas,img,picture,video,iframe,object,embed'
    ) : []);
    for (const selector of settings.maskSelectors) {
        const matches = body.querySelectorAll(selector);
        if (!matches.length) {
            throw new Error('An additional screenshot mask selector matched no elements; refusing to capture.');
        }
        for (const element of matches) elements.add(element);
    }
    const allowedLabels = new Set(settings.allowedLabels.map(label => label.replace(/\s+/g, ' ').trim()));
    const labels = new Set();
    const walker = document.createTreeWalker(body, 4);
    for (let node = automatic ? walker.nextNode() : null; node; node = walker.nextNode()) {
        const text = node.nodeValue.replace(/\s+/g, ' ').trim();
        const parent = node.parentElement;
        if (!text || !parent || parent.closest('script,style,noscript')) continue;
        const fixedLabel = parent.closest('[role="tab"],[role="heading"],[role="columnheader"],h1,h2,h3,h4,h5,h6');
        if (fixedLabel && allowedLabels.has(text) && !parent.closest('[role="gridcell"],[role="rowheader"]')) {
            labels.add(parent);
            continue;
        }
        if (/^[\uE000-\uF8FF\s]+$/.test(text)) continue;
        elements.add(parent);
    }
    for (const element of elements) element.setAttribute('data-workbook-validation-mask', settings.marker);
    for (const element of labels) element.setAttribute('data-workbook-validation-label', settings.marker);
    body.setAttribute('data-workbook-validation-capture', settings.marker);
    return elements.size;
}

function screenshotRedactionStyle(marker, redaction = 'auto') {
    const scope = `body[data-workbook-validation-capture="${marker}"]`;
    const automatic = redaction === 'auto' ?
        `${scope}, ${scope} * { color: transparent !important; -webkit-text-fill-color: transparent !important; text-shadow: none !important; background-image: none !important; }
        ${scope} [data-workbook-validation-label="${marker}"] { color: #111111 !important; -webkit-text-fill-color: #111111 !important; }
        ${scope} :is(svg,canvas,img,picture,video,iframe,object,embed) { visibility: hidden !important; }` : '';
    return `${automatic}
        ${scope}[data-workbook-validation-mask="${marker}"], ${scope} [data-workbook-validation-mask="${marker}"], ${scope} [data-workbook-validation-mask="${marker}"] * { background-color: #111111 !important; color: transparent !important; -webkit-text-fill-color: transparent !important; text-shadow: none !important; background-image: none !important; }
        ${scope} [data-workbook-validation-mask="${marker}"]:is(svg,canvas,img,picture,video,iframe,object,embed), ${scope} [data-workbook-validation-mask="${marker}"] :is(svg,canvas,img,picture,video,iframe,object,embed) { visibility: hidden !important; }`;
}

function applyScreenshotRedaction(body, settings) {
    const document = body.ownerDocument;
    const style = document.createElement('style');
    style.setAttribute('data-workbook-validation-style', settings.marker);
    style.textContent = settings.css;
    document.head.append(style);
    const probe = document.createElement('span');
    probe.textContent = 'Screenshot redaction probe';
    if (settings.redaction !== undefined && settings.redaction !== 'auto') {
        probe.setAttribute('data-workbook-validation-mask', settings.marker);
    }
    body.append(probe);
    try {
        const computed = document.defaultView.getComputedStyle(probe);
        if (computed.color !== 'rgba(0, 0, 0, 0)' ||
            computed.getPropertyValue('-webkit-text-fill-color') !== 'rgba(0, 0, 0, 0)') {
            throw new Error('Screenshot redaction CSS did not take effect; refusing to capture.');
        }
    } finally {
        probe.remove();
    }
}

function isolateScreenshotFrame(iframe, marker) {
    const document = iframe.ownerDocument;
    const window = document.defaultView;
    if (iframe.tagName !== 'IFRAME' || window !== window.top || iframe.getRootNode() !== document ||
        document.querySelector('[data-workbook-validation-isolation]')) {
        throw new Error('Cannot isolate this workbook frame from parent overlays; refusing to capture.');
    }
    const ancestors = new Set();
    for (let element = iframe; element; element = element.parentElement) ancestors.add(element);
    const original = new Map();
    const style = document.createElement('style');
    style.setAttribute('data-workbook-validation-isolation', marker);
    style.textContent = '*::before,*::after,::backdrop { visibility: hidden !important; opacity: 0 !important; }';
    const observer = new window.MutationObserver(records => {
        for (const record of records) {
            if (record.type === 'attributes') apply(record.target);
            for (const node of record.addedNodes || []) {
                if (node.nodeType === 1) {
                    apply(node);
                    for (const element of node.querySelectorAll('*')) apply(element);
                }
            }
        }
    });
    function set(element, property, value) {
        if (element.style.getPropertyValue(property) === value &&
            element.style.getPropertyPriority(property) === 'important') return;
        if (!original.has(element)) original.set(element, { hadStyle: element.hasAttribute('style'), properties: new Map() });
        const properties = original.get(element).properties;
        if (!properties.has(property)) {
            properties.set(property, [element.style.getPropertyValue(property), element.style.getPropertyPriority(property)]);
        }
        element.style.setProperty(property, value, 'important');
    }
    function apply(element) {
        set(element, 'visibility', element === iframe ? 'visible' : 'hidden');
        if (!ancestors.has(element)) {
            set(element, 'opacity', '0');
            if (element.matches('dialog,[popover]')) set(element, 'display', 'none');
        }
    }
    function restore() {
        observer.disconnect();
        for (const [element, { hadStyle, properties }] of original) {
            for (const [property, [value, priority]] of properties) {
                if (value) element.style.setProperty(property, value, priority);
                else element.style.removeProperty(property);
            }
            if (!hadStyle && element.style.length === 0) element.removeAttribute('style');
        }
        style.remove();
        iframe.removeAttribute('data-workbook-validation-isolation');
        delete iframe.__workbookValidationIsolation;
    }
    function verify() {
        if (!iframe.isConnected || !style.isConnected ||
            iframe.getAttribute('data-workbook-validation-isolation') !== marker ||
            window.getComputedStyle(iframe).visibility !== 'visible') {
            throw new Error('Workbook screenshot isolation is no longer valid; refusing to capture.');
        }
        for (const element of document.querySelectorAll('*')) {
            if (element.shadowRoot || (element === document.fullscreenElement && !ancestors.has(element))) {
                throw new Error('Cannot guarantee isolation of parent shadow/fullscreen overlays; refusing to capture.');
            }
            apply(element);
            if (element !== iframe && !ancestors.has(element) && window.getComputedStyle(element).opacity !== '0') {
                throw new Error('Parent overlay isolation did not take effect; refusing to capture.');
            }
        }
        for (const element of ancestors) {
            if (element === iframe) continue;
            if (window.getComputedStyle(element).visibility !== 'hidden') {
                throw new Error('Parent chrome isolation did not take effect; refusing to capture.');
            }
            for (const pseudo of ['::before', '::after']) {
                const computed = window.getComputedStyle(element, pseudo);
                if (!['none', 'normal', ''].includes(computed.content) &&
                    computed.visibility !== 'hidden' && computed.opacity !== '0' && computed.display !== 'none') {
                    throw new Error('Cannot isolate parent generated content; refusing to capture.');
                }
            }
        }
    }
    try {
        document.head.append(style);
        for (const element of document.querySelectorAll('*')) apply(element);
        iframe.setAttribute('data-workbook-validation-isolation', marker);
        iframe.__workbookValidationIsolation = { marker, restore, verify };
        observer.observe(document.documentElement, { childList: true, subtree: true, attributes: true, attributeFilter: ['style'] });
        verify();
    } catch (error) {
        restore();
        throw error;
    }
}

function verifyScreenshotIsolation(iframe, marker) {
    const state = iframe.__workbookValidationIsolation;
    if (!state || state.marker !== marker) throw new Error('Workbook screenshot isolation is missing.');
    state.verify();
}

function restoreScreenshotIsolation(iframe, marker) {
    const state = iframe.__workbookValidationIsolation;
    if (!state || state.marker !== marker) throw new Error('Cannot restore an unknown screenshot isolation scope.');
    state.restore();
}

function bindCaptureDocument(body, marker) {
    const document = body.ownerDocument;
    if (!body.isConnected || document.body !== body || document.defaultView?.document !== document ||
        document.__workbookValidationCapture) {
        throw new Error('Cannot bind the active workbook screenshot document.');
    }
    document.__workbookValidationCapture = { marker, body, root: document.documentElement };
}

function verifyCaptureDocument(body, settings) {
    const document = body.ownerDocument;
    const state = document.__workbookValidationCapture;
    if (!state || state.marker !== settings.marker || state.body !== body || state.root !== document.documentElement ||
        !body.isConnected || document.body !== body || document.defaultView?.document !== document) {
        throw new Error('The inner workbook document changed during screenshot capture.');
    }
    if (!settings.masked) return;
    const styles = document.querySelectorAll(`[data-workbook-validation-style="${settings.marker}"]`);
    if (body.getAttribute('data-workbook-validation-capture') !== settings.marker || styles.length !== 1 ||
        styles[0].textContent !== settings.css ||
        (body.getAttribute('data-workbook-validation-mask') !== settings.marker &&
            !body.querySelector(`[data-workbook-validation-mask="${settings.marker}"]`))) {
        throw new Error('The bound workbook document lost its screenshot redaction state.');
    }
    const probe = document.createElement('span');
    probe.textContent = 'Screenshot verification probe';
    if (settings.redaction !== 'auto') probe.setAttribute('data-workbook-validation-mask', settings.marker);
    body.append(probe);
    try {
        const computed = document.defaultView.getComputedStyle(probe);
        if (computed.color !== 'rgba(0, 0, 0, 0)' ||
            computed.getPropertyValue('-webkit-text-fill-color') !== 'rgba(0, 0, 0, 0)') {
            throw new Error('The bound workbook document is no longer redacted.');
        }
    } finally {
        probe.remove();
    }
}

function clearCaptureDocument(body, marker) {
    const document = body.ownerDocument;
    const state = document.__workbookValidationCapture;
    if (!state || state.marker !== marker || state.body !== body) {
        throw new Error('Cannot clean an unknown workbook capture document.');
    }
    for (const element of body.querySelectorAll(`[data-workbook-validation-mask="${marker}"]`)) {
        element.removeAttribute('data-workbook-validation-mask');
    }
    for (const element of body.querySelectorAll(`[data-workbook-validation-label="${marker}"]`)) {
        element.removeAttribute('data-workbook-validation-label');
    }
    body.removeAttribute('data-workbook-validation-mask');
    body.removeAttribute('data-workbook-validation-label');
    body.removeAttribute('data-workbook-validation-capture');
    for (const style of document.querySelectorAll(`[data-workbook-validation-style="${marker}"]`)) style.remove();
    delete document.__workbookValidationCapture;
}

async function captureWorkbookImage(page, target, settings, allowedLabels, index, timeout) {
    if (!Number.isSafeInteger(timeout) || timeout < 1 || timeout > 120000) throw new Error('Invalid screenshot operation timeout.');
    const outer = page.locator('iframe[name="Workbooks.ReactView"]');
    if (await outer.count() !== 1) throw new Error('Expected one workbook frame for screenshot isolation.');
    const outerHandle = await outer.elementHandle();
    if (!outerHandle) throw new Error('The workbook screenshot frame disappeared.');
    const marker = `capture-${Date.now().toString(36)}-${index}-${Math.random().toString(36).slice(2)}`;
    const file = `${marker}.png`;
    const separator = settings.directory.includes('\\') ? '\\' : '/';
    const path = settings.directory.replace(/[\\/]+$/, '') + separator + file;
    const masked = settings.redaction !== 'none';
    let maskedElements = 0;
    let isolated = false;
    let body;
    let bound = false;
    try {
        try {
            const frame = await outerHandle.contentFrame();
            if (!frame) throw new Error('The workbook screenshot frame has no active document.');
            body = await frame.locator('body').elementHandle();
            if (!body) throw new Error('The workbook screenshot document disappeared.');
            await body.evaluate(bindCaptureDocument, marker);
            bound = true;
            const css = masked ? screenshotRedactionStyle(marker, settings.redaction) : '';
            if (masked) {
                maskedElements = await body.evaluate(markScreenshotMasks, {
                    marker, allowedLabels, maskSelectors: settings.maskSelectors, redaction: settings.redaction
                });
                if (!maskedElements) throw new Error('No screenshot masks were applied; refusing to capture.');
                await body.evaluate(applyScreenshotRedaction, { marker, css, redaction: settings.redaction });
            }
            await outerHandle.evaluate(isolateScreenshotFrame, marker);
            isolated = true;
            const verification = { marker, masked, css, redaction: settings.redaction };
            await outerHandle.evaluate(verifyScreenshotIsolation, marker);
            await body.evaluate(verifyCaptureDocument, verification);
            await target.screenshot({ path, type: 'png', scale: 'css', animations: 'disabled', caret: 'hide', timeout });
            await body.evaluate(verifyCaptureDocument, verification);
            await outerHandle.evaluate(verifyScreenshotIsolation, marker);
        } finally {
            try {
                try {
                    if (bound) await body.evaluate(clearCaptureDocument, marker);
                } finally {
                    if (isolated) await outerHandle.evaluate(restoreScreenshotIsolation, marker);
                }
            } finally {
                try {
                    if (body) await body.dispose();
                } finally {
                    await outerHandle.dispose();
                }
            }
        }
    } catch (error) {
        throw new Error(`${error.message} Discard local image ${file} if written; do not publish or reuse a failed capture.`, { cause: error });
    }
    return { file, maskedElements, parentIsolated: true, documentBound: true, redaction: settings.redaction,
        reviewRequired: true, publicationApproved: false };
}

async function captureMaskedScreenshot(page, target, settings, allowedLabels, index, timeout = 30000) {
    settings = normalizeScreenshotOptions(settings);
    if (!settings || settings.redaction === 'none') {
        throw new Error('Masked capture requires an enabled auto or selective redaction mode.');
    }
    return captureWorkbookImage(page, target, settings, allowedLabels, index, timeout);
}

async function captureWorkbookScreenshot(page, target, settings, allowedLabels, index, timeout = 30000) {
    settings = normalizeScreenshotOptions(settings);
    if (!settings) throw new Error('Screenshot capture is not enabled.');
    return captureWorkbookImage(page, target, settings, allowedLabels, index, timeout);
}

function readGridSummary(element) {
    const count = element.getAttribute('aria-rowcount');
    if (count === null || !/^\d+$/.test(count) || !Number.isSafeInteger(Number(count)) || Number(count) < 1) {
        throw new Error('Cannot validate virtualized row limits without a reliable aria-rowcount.');
    }
    const columns = Array.from(element.querySelectorAll('[role="columnheader"]'), header =>
        (header.textContent || '').replace(/^[\uE000-\uF8FF\s]+/, '').replace(/\s+/g, ' ').trim()).filter(Boolean);
    return { rows: Number(count) - 1, columns };
}

function waitForPanelReady(element, settings) {
    return new Promise((resolve, reject) => {
        const document = element.ownerDocument;
        const window = document.defaultView;
        const deadline = Date.now() + settings.timeout;
        let stableSince;
        let timer;
        const observer = new window.MutationObserver(() => { stableSince = undefined; });
        function finish(error, result) {
            observer.disconnect();
            window.clearTimeout(timer);
            if (error) reject(error);
            else resolve(result);
        }
        function visible(node) {
            const style = window.getComputedStyle(node);
            return style.visibility !== 'hidden' && style.display !== 'none' && node.getClientRects().length > 0;
        }
        function inspect() {
            try {
                inspectState();
            } catch (error) {
                finish(error);
            }
        }
        function inspectState() {
            if (Date.now() >= deadline) {
                finish(new Error('The requested panel did not reach a stable ready state within the timeout; no-data and refresh loops are not passes.'));
                return;
            }
            if (!element.isConnected) {
                finish(new Error('The requested panel was replaced while settling; no stable result was qualified.'));
                return;
            }
            let rendererError = false;
            let truncation;
            const inspectedParents = new Set();
            const walker = document.createTreeWalker(element, 4);
            for (let node = walker.nextNode(); node; node = walker.nextNode()) {
                const parent = node.parentElement;
                if (!parent || parent.closest('[role="grid"],script,style,noscript') || !visible(parent)) continue;
                const texts = [node.nodeValue];
                if (!inspectedParents.has(parent)) {
                    inspectedParents.add(parent);
                    texts.push(parent.textContent || '');
                }
                for (const value of texts) {
                    const text = value.replace(/\s+/g, ' ').trim();
                    if (/^Error loading item\.?$/.test(text)) rendererError = true;
                    const match = text.match(/^Results were limited to the first ([\d,]+) of ([\d,]+) items\.?$/);
                    if (match) {
                        truncation = { returned: Number(match[1].replace(/,/g, '')), total: Number(match[2].replace(/,/g, '')) };
                        if (!Number.isSafeInteger(truncation.returned) || !Number.isSafeInteger(truncation.total) ||
                            truncation.returned > truncation.total) {
                            finish(new Error('The result-limit warning contains invalid aggregate counts.'));
                            return;
                        }
                    }
                }
            }
            if (rendererError) {
                finish(new Error('A requested workbook panel reported a renderer error.'));
                return;
            }
            const busy = (element.matches('[aria-busy="true"]') && visible(element)) ||
                Array.from(element.querySelectorAll('[role="progressbar"],[aria-busy="true"]')).some(visible);
            const grids = Array.from(element.querySelectorAll('[role="grid"]')).filter(visible);
            if (settings.requireGrid && grids.length > 1) {
                finish(new Error('The requested panel contains multiple visible grids.'));
                return;
            }
            let cellsMatch = true;
            if (settings.cells?.length && grids.length === 1) {
                const normalize = value => (value || '').replace(/^[\uE000-\uF8FF\s]+/, '').replace(/\s+/g, ' ').trim();
                const headers = Array.from(grids[0].querySelectorAll('[role="columnheader"]'), header => normalize(header.textContent));
                const rows = Array.from(grids[0].querySelectorAll('[role="row"]'))
                    .filter(row => visible(row) && row.querySelector('[role="gridcell"]'));
                for (const check of settings.cells) {
                    const indexes = headers.flatMap((header, index) => header === check.column ? [index] : []);
                    const row = rows[check.row];
                    const cells = row ? Array.from(row.querySelectorAll('[role="gridcell"]')) : [];
                    let expected;
                    if (typeof check.equals === 'string') expected = check.equals;
                    else {
                        const state = document.__workbookValidationInteractions;
                        if (!state) throw new Error('Captured-cell observations are unavailable.');
                        expected = state.resolve(check.equals);
                    }
                    if (indexes.length !== 1 || cells.length !== headers.length ||
                        normalize(cells[indexes[0]]?.textContent) !== expected) cellsMatch = false;
                }
            }
            if (!busy && cellsMatch && (!settings.requireGrid || grids.length === 1)) {
                if (stableSince === undefined) stableSince = Date.now();
                if (Date.now() - stableSince >= 250) {
                    finish(undefined, { settled: true, truncation });
                    return;
                }
            } else {
                stableSince = undefined;
            }
            timer = window.setTimeout(inspect, Math.min(50, Math.max(1, deadline - Date.now())));
        }
        observer.observe(element, {
            childList: true, subtree: true, characterData: true,
            attributes: true, attributeFilter: ['aria-busy', 'aria-rowcount', 'aria-hidden']
        });
        inspect();
    });
}

async function validatePanelContract(frame, check, timeout) {
    const heading = frame.getByRole('heading', { name: check.heading, exact: true });
    await heading.waitFor({ state: 'visible', timeout });
    if (await heading.count() !== 1) throw new Error('The requested panel heading is ambiguous.');
    const panel = heading.locator('xpath=ancestor::div[contains(@class,"styleWrapper-maximized")][1]');
    if (await panel.count() !== 1) throw new Error('Cannot locate the requested workbook panel.');
    const requiresGrid = check.minRows !== undefined || check.maxRows !== undefined || check.columns !== undefined || Boolean(check.cells?.length);
    const ready = await panel.evaluate(waitForPanelReady, { timeout, requireGrid: requiresGrid, cells: check.cells || [] });
    if (ready.truncation && !check.allowTruncated) {
        throw new Error('The requested panel returned truncated results. Narrow the scope or explicitly allowTruncated.');
    }
    const result = { heading: check.heading, settled: ready.settled };
    if (ready.truncation) result.truncation = ready.truncation;
    if (requiresGrid) {
        const grid = panel.getByRole('grid');
        const summary = await grid.evaluate(readGridSummary);
        if (check.minRows !== undefined && summary.rows < check.minRows) {
            throw new Error(`"${check.heading}" returned ${summary.rows} rows, below minRows ${check.minRows}.`);
        }
        if (check.maxRows !== undefined && summary.rows > check.maxRows) {
            throw new Error(`"${check.heading}" returned ${summary.rows} rows, above maxRows ${check.maxRows}.`);
        }
        if (check.columns !== undefined && JSON.stringify(summary.columns) !== JSON.stringify(check.columns)) {
            throw new Error(`"${check.heading}" column labels differ from the requested contract.`);
        }
        result.grid = summary;
        if (check.cells?.length) result.cellAssertions = check.cells.length;
    }
    return result;
}

async function resolveParameterTrigger(frame, group, timeout) {
    const owner = frame.locator(`[id=${JSON.stringify(group.producer.itemName)}]`);
    await owner.waitFor({ state: 'visible', timeout });
    const linkSelector = `[id=${JSON.stringify(group.producer.linkId)}]`;
    const options = { name: group.trigger, exact: true, includeHidden: true };
    const trigger = owner.locator(`${linkSelector}:not([href]),${linkSelector}[href=""],${linkSelector}[href="#"]`)
        .and(owner.getByRole('menuitem', options)
            .or(owner.getByRole('button', options))
            .or(owner.getByRole('link', options)));
    if (await owner.count() !== 1 || await frame.locator(linkSelector).count() !== 1 || await trigger.count() !== 1) {
        throw new Error('Cannot uniquely map the verified parameter producer/link to a DOM control. No action was activated.');
    }
    return trigger;
}

async function activateWorkbookControl(locator, timeout, key = 'Enter') {
    await locator.waitFor({ state: 'visible', timeout });
    if (!await locator.isEnabled({ timeout })) {
        throw new Error('A requested workbook control is disabled; refusing to activate it.');
    }
    await locator.focus({ timeout });
    await locator.press(key, { timeout });
}

async function validateWorkbookInBrowser(page, workbookSource, options = {}) {
    const plan = createValidationPlan(workbookSource, options);
    const progress = { phase: 'tenant-verification' };
    try {
        return await executeWorkbookValidation(page, plan, progress);
    } catch (error) {
        if (!error.report) {
            error.report = {
                status: 'blocked', phase: progress.phase,
                sourceSha256: progress.sourceSha256, importedSourceSha256: progress.importedSourceSha256,
                evidenceMode: plan.interactions.evidenceMode, workbookSaved: false,
                instrumentation: { enabled: plan.interactions.scenarios.length > 0, productionSourceModified: false },
                needsCloserLook: pendingInteractionReview(plan, 'validation-interrupted'),
                discardLocalCaptures: Boolean(progress.captureFailed)
            };
        }
        throw error;
    }
}

async function executeWorkbookValidation(page, plan, progress) {
    await verifySelectedTenant(page, plan.tenant);
    progress.phase = 'source-import';
    if (await page.getByRole('heading', { name: /\bUnsaved Workbook\b/ }).count() !== 1) {
        throw new Error('Open a new empty unsaved workbook. Existing workbook content will not be replaced.');
    }
    const frame = page.locator('iframe[name="Workbooks.ReactView"]').contentFrame();
    const editorInput = frame.getByRole('textbox', { name: 'Editor content', exact: true });
    await editorInput.waitFor({ state: 'visible', timeout: plan.timeout });
    const hashes = await editorInput.evaluate(async (element, request) => {
        const source = request.importSource;
        const editors = globalThis.monaco?.editor?.getEditors?.() || [];
        const active = editors.filter(editor => editor.getDomNode()?.contains(element));
        if (active.length !== 1) {
            throw new Error('Expected one active Advanced Editor; no content was replaced.');
        }
        const model = active[0].getModel();
        if (!model) {
            throw new Error('The active Advanced Editor has no model; no content was replaced.');
        }
        let existing;
        try {
            existing = JSON.parse(model.getValue().replace(/^\uFEFF/, ''));
        } catch (error) {
            if (error instanceof SyntaxError) {
                throw new Error('Advanced Editor is not an empty workbook; no content was replaced.');
            }
            throw error;
        }
        if (!existing || existing.version !== 'Notebook/1.0' ||
            !Array.isArray(existing.items) || existing.items.length) {
            throw new Error('Advanced Editor is not an empty workbook; no content was replaced.');
        }
        model.setValue(source);
        if (model.getValue().replace(/\r\n/g, '\n') !== source) {
            throw new Error('Advanced Editor content differs from the requested source.');
        }
        async function hash(value) {
            const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value));
            return Array.from(new Uint8Array(digest), byte => byte.toString(16).padStart(2, '0')).join('');
        }
        return { original: await hash(request.source), imported: await hash(source) };
    }, { source: plan.source, importSource: plan.importSource });
    const sourceSha256 = hashes.original;
    progress.sourceSha256 = hashes.original;
    progress.importedSourceSha256 = hashes.imported;

    progress.phase = 'apply-source';
    await verifySelectedTenant(page, plan.tenant);
    await activateWorkbookControl(frame.getByRole('menuitem', { name: 'Apply', exact: true }), plan.timeout);
    const done = frame.getByRole('menuitem', { name: 'Done Editing', exact: true });
    await done.waitFor({ state: 'visible', timeout: plan.timeout });
    await verifySelectedTenant(page, plan.tenant);
    await activateWorkbookControl(done, plan.timeout);
    await frame.getByRole('menubar', { name: /^Workbooks toolbar/ })
        .getByRole('menuitem', { name: 'Edit', exact: true })
        .waitFor({ state: 'visible', timeout: plan.timeout });
    progress.phase = 'panel-and-tab-contracts';

    const screenshots = [];
    const panelChecks = [];
    async function checkPanels(tab) {
        for (const check of plan.panels.filter(check => check.tab === tab)) {
            panelChecks.push({ tab, ...await validatePanelContract(frame, check, plan.timeout) });
        }
    }
    async function capture(target, allowedLabels, stage) {
        if (plan.screenshots) {
            try {
                await verifySelectedTenant(page, plan.tenant);
                const result = await captureWorkbookScreenshot(page, target, plan.screenshots, allowedLabels, screenshots.length, plan.timeout);
                screenshots.push({ ...result, stage });
            } catch (error) {
                progress.captureFailed = true;
                error.validationCode = 'screenshot-capture-failed';
                throw error;
            }
        }
    }
    const tabsVisited = [];
    const tablist = frame.getByRole('tablist').first();
    if (plan.tabs.length) {
        await tablist.waitFor({ state: 'visible', timeout: plan.timeout });
        const actual = (await tablist.getByRole('tab').allTextContents())
            .map(value => value.replace(/\s+/g, ' ').trim());
        if (JSON.stringify(actual) !== JSON.stringify(plan.tabs)) {
            throw new Error(`Primary tab labels differ: expected ${JSON.stringify(plan.tabs)}, found ${JSON.stringify(actual)}.`);
        }
        for (const name of plan.tabs) {
            await verifySelectedTenant(page, plan.tenant);
            await activateWorkbookControl(tablist.getByRole('tab', { name, exact: true }), plan.timeout);
            await tablist.getByRole('tab', { name, exact: true, selected: true })
                .waitFor({ state: 'visible', timeout: plan.timeout });
            tabsVisited.push(name);
            await checkPanels(name);
            const labels = plan.panels.filter(check => check.tab === name)
                .flatMap(check => [check.heading, ...(check.columns || [])]);
            await capture(page.locator('iframe[name="Workbooks.ReactView"]'), [...plan.tabs, ...labels], 'tab');
        }
    } else {
        await checkPanels(undefined);
        const labels = plan.panels.flatMap(check => [check.heading, ...(check.columns || [])]);
        await capture(page.locator('iframe[name="Workbooks.ReactView"]'), labels, 'workbook');
    }

    const deferredChecks = [];
    let parameterActionsClicked = 0;
    for (const group of plan.deferredGroups) {
        await verifySelectedTenant(page, plan.tenant);
        if (group.tab !== undefined) {
            await activateWorkbookControl(tablist.getByRole('tab', { name: group.tab, exact: true }), plan.timeout);
            await tablist.getByRole('tab', { name: group.tab, exact: true, selected: true })
                .waitFor({ state: 'visible', timeout: plan.timeout });
        }
        const trigger = await resolveParameterTrigger(frame, group, plan.timeout);
        await trigger.waitFor({ state: 'visible', timeout: plan.timeout });
        await trigger.scrollIntoViewIfNeeded({ timeout: plan.timeout });
        for (const check of group.checks) {
            if (await frame.getByRole('heading', { name: check.heading, exact: true, includeHidden: true }).count()) {
                throw new Error(`Deferred content "${check.heading}" was mounted before its trigger.`);
            }
        }
        await activateWorkbookControl(trigger, plan.timeout);
        parameterActionsClicked++;
        for (const check of group.checks) {
            const result = { trigger: check.trigger, ...await validatePanelContract(frame, check, plan.timeout) };
            if (check.hideTriggerAfterLoad) {
                await trigger.waitFor({ state: 'hidden', timeout: plan.timeout });
                result.producerHidden = true;
            }
            deferredChecks.push(result);
            if (plan.screenshots) {
                const heading = frame.getByRole('heading', { name: check.heading, exact: true });
                const panel = heading.locator('xpath=ancestor::div[contains(@class,"styleWrapper-maximized")][1]');
                const target = await panel.count() === 1 ? panel : heading;
                await target.evaluate(element => element.scrollIntoView({ block: 'center', inline: 'nearest' }));
                await capture(page.locator('iframe[name="Workbooks.ReactView"]'),
                    [check.heading, ...(check.columns || [])], 'deferred');
            }
        }
    }
    progress.phase = 'interaction-scenarios';
    const interaction = await runInteractionScenarios(page, frame, plan, {
        verifyTenant: () => verifySelectedTenant(page, plan.tenant),
        activate: activateWorkbookControl,
        async navigate(name) {
            await verifySelectedTenant(page, plan.tenant);
            await activateWorkbookControl(tablist.getByRole('tab', { name, exact: true }), plan.timeout);
            await tablist.getByRole('tab', { name, exact: true, selected: true }).waitFor({ state: 'visible', timeout: plan.timeout });
        },
        async assertTab(name) {
            await tablist.getByRole('tab', { name, exact: true, selected: true }).waitFor({ state: 'visible', timeout: plan.timeout });
        },
        checkPanel: check => validatePanelContract(frame, check, plan.timeout),
        capture: labels => capture(page.locator('iframe[name="Workbooks.ReactView"]'), [...plan.tabs, ...labels], 'interaction')
    });
    const interactionDataContracts = interaction.scenarios.flatMap(scenario => scenario.steps)
        .reduce((count, step) => count + (step.dataContracts || 0), 0);
    const dataContractsChecked = [...panelChecks, ...deferredChecks].filter(check => check.grid).length + interactionDataContracts;
    const report = {
        sourceSha256,
        importedSourceSha256: hashes.imported,
        evidenceMode: plan.interactions.evidenceMode,
        instrumentation: { enabled: plan.interactions.scenarios.length > 0,
            privateParameterProbes: plan.interactions.probes.length,
            sourceBoundaryMarkers: plan.interactions.bindings.length * 2, productionSourceModified: false },
        tenantVerified: true,
        itemCount: plan.itemCount,
        importedItemCount: plan.itemCount + plan.interactions.bindings.length * 2 + plan.interactions.probes.length,
        tabsVisited,
        parameterActionsClicked,
        panelChecks,
        deferredChecks,
        dataContractsChecked,
        coverageLevel: interaction.scenarios.length ? 'interaction-contracts' :
            dataContractsChecked ? 'requested-data-contracts' : 'smoke-only',
        interactionScenarios: interaction.scenarios,
        interactionStepsChecked: interaction.scenarios.flatMap(scenario => scenario.steps)
            .filter(step => step.status === 'passed').length,
        needsCloserLook: interaction.needsCloserLook,
        reviewState: interaction.needsCloserLook.length ? 'needs-closer-look' : 'requested-checks-completed',
        sourceDiagnostics: plan.sourceDiagnostics,
        screenshots: {
            enabled: Boolean(plan.screenshots),
            captures: screenshots,
            guidance: plan.screenshots ?
                'Review every local image before sharing; nothing was uploaded. If auto redaction hides too much, ask the user to choose manual masks, AI-assisted mask selection, or explicitly approved unredacted capture. Never turn masking off automatically; no AI service is called.' :
                'Optional screenshots are available with auto redaction by default. Ask the user whether to capture; manual/AI-assisted masks and unredacted local capture require explicit approval.'
        },
        coverage: 'Only source import, primary tabs, and requested panels/interactions were checked; no-data is not proof of health. ' +
            (dataContractsChecked ? 'ARIA rows describe the displayed grid, not a complete resource inventory.' :
                'No query-data contract was qualified; tab navigation is not query validation.') +
            (interaction.scenarios.length ? ' Interaction assertions used an explicitly instrumented unsaved copy; exact published layout is not qualified.' : ''),
        workbookSaved: false
    };
    if (interaction.scenarios.some(scenario => scenario.status !== 'passed')) {
        const error = new Error('Requested interaction validation did not pass; inspect the aggregate report. Discard local captures if the report requires disposal.');
        report.status = 'failed';
        report.discardLocalCaptures = Boolean(progress.captureFailed);
        error.report = report;
        throw error;
    }
    progress.phase = 'complete';
    report.status = 'checks-passed';
    return report;
}

function loadValidationInput(workbookPath, checksPath, screenshotDirectory, runtime = {}) {
    if (typeof workbookPath !== 'string' || !workbookPath.trim()) {
        throw new Error('Set WORKBOOK_BROWSER_TEMPLATE or provide --workbook.');
    }
    if (checksPath !== undefined && (typeof checksPath !== 'string' || !checksPath.trim())) {
        throw new Error('The checks file must be a non-empty path.');
    }
    const source = extractWorkbookSource(fs.readFileSync(workbookPath, 'utf8'));
    let options = {};
    if (checksPath !== undefined) {
        try {
            options = JSON.parse(fs.readFileSync(checksPath, 'utf8'));
        } catch (error) {
            if (error instanceof SyntaxError) throw new Error('The checks profile must be valid JSON; private contents are not logged.');
            throw error;
        }
    }
    if (!options || typeof options !== 'object' || Array.isArray(options)) {
        throw new Error('Browser validation options must be an object.');
    }
    if (screenshotDirectory !== undefined) {
        options = { ...options, screenshots: { ...options.screenshots, directory: screenshotDirectory } };
    }
    if (runtime.tenantId !== undefined || runtime.confirmTenant !== undefined) {
        options = {
            ...options,
            tenant: {
                ...options.tenant,
                id: runtime.tenantId === undefined ? options.tenant?.id : runtime.tenantId,
                confirmed: runtime.confirmTenant === true
            }
        };
    }
    if (runtime.redaction !== undefined || runtime.allowSensitiveCapture !== undefined) {
        options = {
            ...options,
            screenshots: {
                ...options.screenshots,
                ...(runtime.redaction === undefined ? {} : { redaction: runtime.redaction }),
                ...(runtime.allowSensitiveCapture === undefined ? {} : { allowSensitiveCapture: runtime.allowSensitiveCapture })
            }
        };
    }
    if (runtime.evidenceMode !== undefined) options = { ...options, evidenceMode: runtime.evidenceMode };
    const plan = createValidationPlan(source, options);
    return {
        source, options, sourceDiagnostics: plan.sourceDiagnostics,
        reviewPlan: {
            status: 'not-run',
            plannedSourceSha256: crypto.createHash('sha256').update(plan.source).digest('hex'),
            plannedImportedSourceSha256: crypto.createHash('sha256').update(plan.importSource).digest('hex'),
            evidenceMode: plan.interactions.evidenceMode,
            instrumentation: plan.interactions.scenarios.length > 0,
            needsCloserLook: pendingInteractionReview(plan, 'not-executed')
        }
    };
}

function validateCdpEndpoint(value) {
    const message = 'Use a loopback HTTP CDP endpoint without credentials, paths, query strings, or fragments.';
    let endpoint;
    try {
        endpoint = new URL(value);
    } catch (error) {
        throw new Error(message);
    }
    if (endpoint.protocol !== 'http:' || !['localhost', '127.0.0.1', '[::1]'].includes(endpoint.hostname) ||
        endpoint.username || endpoint.password || endpoint.search || endpoint.hash ||
        endpoint.pathname !== '/' || endpoint.port === '0') {
        throw new Error(message);
    }
    return endpoint.href;
}

function createPlaywrightScript(workbookSource, options = {}) {
    const plan = createValidationPlan(workbookSource, options);
    // Keep the emitted runner independent of Node imports and the browser tool's filesystem access.
    const functions = [...Object.values(interactionHelpers), isAzurePortalUrl, normalizeTenantSelection, requireConfirmedTenant, verifySelectedTenant,
        normalizeScreenshotOptions, createValidationPlan, markScreenshotMasks, screenshotRedactionStyle,
        applyScreenshotRedaction, isolateScreenshotFrame, verifyScreenshotIsolation, restoreScreenshotIsolation,
        bindCaptureDocument, verifyCaptureDocument, clearCaptureDocument,
        captureWorkbookImage, captureMaskedScreenshot, captureWorkbookScreenshot, readGridSummary,
        waitForPanelReady, validatePanelContract, resolveParameterTrigger, activateWorkbookControl,
        executeWorkbookValidation, validateWorkbookInBrowser]
        .map(callback => callback.toString()).join('\n\n');
    return `async (page) => {\n${functions}\ntry {\nreturn await validateWorkbookInBrowser(page, ${JSON.stringify(plan.source)}, ${JSON.stringify(options)});\n} catch (error) {\nif (error.report) console.error(JSON.stringify(error.report));\nthrow error;\n}\n}\n`;
}

module.exports = {
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
    resolveParameterTrigger,
    activateWorkbookControl,
    validateWorkbookInBrowser,
    loadValidationInput,
    validateCdpEndpoint,
    createPlaywrightScript
};
