const { TextDecoder } = require('util');

function isObject(value) {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function parseJson(source, label) {
    try {
        return JSON.parse(source.replace(/^\uFEFF/, ''));
    } catch (error) {
        if (error instanceof SyntaxError) {
            throw new Error(`${label} must be valid JSON.`);
        }
        throw error;
    }
}

function resolveLiteral(value) {
    if (typeof value === 'string' && value.startsWith('[') && value.endsWith(']')) {
        if (value.startsWith('[[')) return value.slice(1);
        throw new Error('Unsupported ARM expression in workbook data. Use the native .workbook or Notebook/1.0 .json file instead.');
    }
    if (Array.isArray(value)) {
        return value.map(resolveLiteral);
    }
    if (isObject(value)) {
        return Object.fromEntries(Object.entries(value).map(([key, nested]) => [key, resolveLiteral(nested)]));
    }
    return value;
}

function resolveWorkbookData(value, variables) {
    if (typeof value !== 'string' || !value.trim().startsWith('[')) {
        // ARM literal escaping applies to object values, not JSON encoded inside a string.
        return typeof value === 'string' ? value : resolveLiteral(value);
    }
    const direct = /^\[\s*variables\s*\(\s*'([^']+)'\s*\)\s*\]$/i.exec(value.trim());
    const wrapped = /^\[\s*(string|base64ToString)\s*\(\s*variables\s*\(\s*'([^']+)'\s*\)\s*\)\s*\]$/i.exec(value.trim());
    if (!direct && !wrapped) {
        throw new Error('Unsupported ARM expression for workbook data. Only literal variables, string(variables(...)), and base64ToString(variables(...)) are supported; use a native workbook otherwise.');
    }
    const name = direct ? direct[1] : wrapped[2];
    const names = isObject(variables) ?
        Object.keys(variables).filter(key => key.toLowerCase() === name.toLowerCase()) : [];
    if (names.length !== 1) {
        throw new Error('The referenced ARM workbook variable must exist and be unambiguous.');
    }
    const literal = resolveLiteral(variables[names[0]]);
    if (wrapped && wrapped[1].toLowerCase() === 'base64tostring') {
        if (typeof literal !== 'string' || !literal.length ||
            Buffer.from(literal, 'base64').toString('base64') !== literal) {
            throw new Error('The ARM workbook variable must contain canonical base64.');
        }
        try {
            return new TextDecoder('utf-8', { fatal: true }).decode(Buffer.from(literal, 'base64'));
        } catch (error) {
            if (error instanceof TypeError) {
                throw new Error('The ARM workbook base64 variable must decode to valid UTF-8.');
            }
            throw error;
        }
    }
    return literal;
}

function assertNotebook(value) {
    if (!isObject(value) || value.version !== 'Notebook/1.0' || !Array.isArray(value.items)) {
        throw new Error('Expected a Notebook/1.0 workbook with an items array.');
    }
}

function extractWorkbookSource(source) {
    if (typeof source !== 'string' || !source.trim()) {
        throw new Error('Workbook input must be a non-empty JSON string.');
    }
    const document = parseJson(source, 'Workbook input');
    if (isObject(document) && document.version === 'Notebook/1.0') {
        assertNotebook(document);
        return source;
    }
    if (!isObject(document) || !Array.isArray(document.resources)) {
        throw new Error('Expected a native Notebook/1.0 workbook or an ARM template with a resources array.');
    }
    const resources = document.resources.filter(resource => isObject(resource) &&
        typeof resource.type === 'string' && /^microsoft\.insights\/(workbooks|workbooktemplates)$/i.test(resource.type));
    if (resources.length !== 1) {
        throw new Error(`Expected exactly one workbook resource in the ARM template; found ${resources.length}. Use a native workbook for ambiguous or nested deployments.`);
    }
    const resource = resources[0];
    const property = /\/workbooktemplates$/i.test(resource.type) ? 'templateData' : 'serializedData';
    if (!isObject(resource.properties) || !Object.prototype.hasOwnProperty.call(resource.properties, property)) {
        throw new Error(`The ARM workbook resource must define properties.${property}.`);
    }
    const data = resolveWorkbookData(resource.properties[property], document.variables);
    const workbook = typeof data === 'string' ? parseJson(data, 'ARM workbook data') : data;
    assertNotebook(workbook);
    return typeof data === 'string' ? data : JSON.stringify(workbook);
}

module.exports = { extractWorkbookSource };
