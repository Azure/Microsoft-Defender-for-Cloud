const assert = require('chai').assert;
const { rejects } = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const vm = require('vm');
const { spawnSync } = require('child_process');
const { extractWorkbookSource } = require('../../workbook-browser/workbookSource');
const { createValidationPlan, loadValidationInput } = require('../../workbook-browser/workbookBrowserValidator');

const browserDirectory = path.resolve(__dirname, '..', '..', 'workbook-browser');
const repository = path.resolve(__dirname, '..', '..', '..');
const source = fs.readFileSync(path.join(browserDirectory, 'fixtures', 'Smoke.workbook'), 'utf8');

function armSource(data, variables = {}, type = 'Microsoft.Insights/workbooks') {
    const property = /\/workbookTemplates$/i.test(type) ? 'templateData' : 'serializedData';
    return JSON.stringify({
        variables,
        resources: [{ type, properties: { [property]: data } }]
    });
}

describe('Extracting Defender for Cloud workbook sources without Azure...', () => {
    it('preserves exact native source, including BOM and Windows line endings', () => {
        const windows = '\uFEFF' + source.replace(/\r?\n/g, '\r\n');
        assert.equal(extractWorkbookSource(windows), windows);
        assert.equal(createValidationPlan(extractWorkbookSource(windows)).source, source.replace(/\r\n/g, '\n'));
    });

    it('extracts literal serialized JSON without changing its text', () => {
        assert.equal(extractWorkbookSource(armSource(source)), source);
    });

    it('accepts a literal workbook object and ignores unrelated resources', () => {
        const document = JSON.parse(armSource(JSON.parse(source)));
        document.resources.unshift({ type: 'Microsoft.Storage/storageAccounts' });
        const extracted = extractWorkbookSource(JSON.stringify(document));
        assert.deepEqual(JSON.parse(extracted), JSON.parse(source));
    });

    it('resolves literal string and object variables', () => {
        for (const value of [source, JSON.parse(source)]) {
            const extracted = extractWorkbookSource(armSource("[variables('workbookContent')]", { workbookContent: value }));
            assert.deepEqual(JSON.parse(extracted), JSON.parse(source));
        }
    });

    it('supports string(variables(...)) with ARM case-insensitivity and whitespace', () => {
        const expression = "[ StRiNg ( VaRiAbLes ( 'WORKBOOKCONTENT' ) ) ]";
        const extracted = extractWorkbookSource(armSource(expression, { workbookContent: JSON.parse(source) }));
        assert.deepEqual(JSON.parse(extracted), JSON.parse(source));
    });

    it('unescapes ARM object literals exactly once without evaluating the resulting text', () => {
        const workbook = JSON.parse(source);
        const parameter = workbook.items[0].content.parameters[0];
        parameter.jsonData = '[[{"value":"Yes","selected":true}]';
        parameter.value = "[[parameters('keep-as-literal')]";
        workbook.items[2].content.json = '[Guide](https://example.invalid/)';
        workbook.items[2].content.title = '[[no-escape] trailing text';
        const extracted = JSON.parse(extractWorkbookSource(armSource(
            "[string(variables('content'))]", { content: workbook }
        )));
        assert.equal(extracted.items[0].content.parameters[0].jsonData, '[{"value":"Yes","selected":true}]');
        assert.equal(extracted.items[0].content.parameters[0].value, "[parameters('keep-as-literal')]");
        assert.equal(extracted.items[2].content.json, workbook.items[2].content.json);
        assert.equal(extracted.items[2].content.title, workbook.items[2].content.title);
        assert.equal(parameter.jsonData, '[[{"value":"Yes","selected":true}]');
    });

    it('does not unescape native workbook strings', () => {
        const workbook = JSON.parse(source);
        workbook.items[2].content.json = "[[parameters('keep-both-brackets')]";
        const native = JSON.stringify(workbook);
        assert.equal(extractWorkbookSource(native), native);
    });

    it('decodes a base64 workbook variable as UTF-8', () => {
        const unicode = source.replace('Browser validation example',
            'Synthetic ' + String.fromCodePoint(0xe9) + ' example');
        const encoded = Buffer.from(unicode, 'utf8').toString('base64');
        assert.equal(extractWorkbookSource(armSource(
            "[base64ToString(variables('workbookDataBase64'))]", { workbookDataBase64: encoded }
        )), unicode);
    });

    it('extracts workbookTemplates templateData without deploying the template', () => {
        for (const data of [JSON.parse(source), "[variables('content')]"]) {
            const extracted = extractWorkbookSource(armSource(data, { content: JSON.parse(source) },
                'microsoft.insights/workbookTemplates'));
            assert.deepEqual(JSON.parse(extracted), JSON.parse(source));
        }
    });

    it('rejects invalid input and malformed notebook payloads explicitly', () => {
        for (const input of [undefined, '', 'not JSON', 'null', '[]', '{}']) {
            assert.throws(() => extractWorkbookSource(input), /JSON|Notebook/);
        }
        for (const data of ['null', '{}', '[]', 'not JSON',
            JSON.stringify({ version: 'Notebook/2.0', items: [] }),
            JSON.stringify({ version: 'Notebook/1.0', items: {} })]) {
            assert.throws(() => extractWorkbookSource(armSource(data)), /JSON|Notebook|Unsupported ARM expression/);
        }
        assert.throws(() => extractWorkbookSource(JSON.stringify({ version: 'Notebook/1.0' })), /items array/);
    });

    it('requires exactly one top-level workbook resource rather than choosing an arbitrary one', () => {
        const document = JSON.parse(armSource(source));
        document.resources.push(document.resources[0]);
        assert.throws(() => extractWorkbookSource(JSON.stringify(document)), /exactly one.*found 2/);
        assert.throws(() => extractWorkbookSource('{"resources":[]}'), /exactly one.*found 0/);
        assert.throws(() => extractWorkbookSource('{"resources":{}}'), /resources array/);
        const nested = { resources: [{ type: 'Microsoft.Resources/deployments', properties: { template: document } }] };
        assert.throws(() => extractWorkbookSource(JSON.stringify(nested)), /nested deployments/);
    });

    it('rejects missing properties and does not fall back to an unused workbook variable', () => {
        for (const properties of [undefined, null, {}, { serializedData: null }]) {
            const document = { variables: { workbookContent: JSON.parse(source) },
                resources: [{ type: 'Microsoft.Insights/workbooks', properties }] };
            assert.throws(() => extractWorkbookSource(JSON.stringify(document)), /serializedData|Notebook/);
        }
    });

    it('rejects missing, ambiguous, and nonliteral variable definitions', () => {
        const expression = "[variables('content')]";
        for (const variables of [{}, null, { content: JSON.parse(source), CONTENT: JSON.parse(source) }]) {
            assert.throws(() => extractWorkbookSource(armSource(expression, variables)), /exist and be unambiguous/);
        }
        for (const content of ["[parameters('content')]", "[variables('content')]"]) {
            assert.throws(() => extractWorkbookSource(armSource(expression, { content })), /Unsupported ARM expression/);
        }
    });

    it('rejects nested expressions in ARM object variables instead of importing unevaluated data', () => {
        const workbook = JSON.parse(source);
        workbook.items[2].content.json = "[parameters('description')]";
        assert.throws(() => extractWorkbookSource(armSource(
            "[string(variables('content'))]", { content: workbook }
        )), /Unsupported ARM expression/);
    });

    it('keeps expression-like text inside serialized JSON as data', () => {
        for (const text of ["[parameters('literalExample')]", "[[parameters('keep-both-brackets')]"]) {
            const workbook = JSON.parse(source);
            workbook.items[2].content.json = text;
            const serialized = JSON.stringify(workbook);
            assert.equal(extractWorkbookSource(armSource(serialized)), serialized);
        }
    });

    it('never evaluates general ARM expressions or script-like input', () => {
        for (const expression of ["[parameters('workbookContent')]", "[concat('a','b')]",
            "[reference('resource')]", "[variables('content')]; globalThis.injected = true"]) {
            assert.throws(() => extractWorkbookSource(armSource(expression)), /Unsupported ARM expression/);
        }
        assert.isUndefined(globalThis.injected);
    });

    it('rejects corrupt base64, invalid UTF-8, and decoded non-workbook data', () => {
        const expression = "[base64ToString(variables('content'))]";
        for (const content of ['', 'not-base64!', 'e30', 123, {}, Buffer.from([0xff]).toString('base64'),
            Buffer.from('{}').toString('base64')]) {
            assert.throws(() => extractWorkbookSource(armSource(expression, { content })), /base64|UTF-8|Notebook/);
        }
    });

    const examples = [
        ['native .workbook', 'ASC Recommendations Graph', 'ascrecommendationgraph.workbook'],
        ['native .json', 'Azure Security Benchmark v3', 'AzureSecurityBenchmarkv3.json'],
        ['serializedData ARM', 'ASC Recommendations Graph', 'armTemplate.json'],
        ['object-variable ARM', 'Defender for Servers Monitoring', 'azuredeploy.json'],
        ['escaped-object ARM', 'Azure Security Benchmark v3', 'armTemplate.json'],
        ['escaped onboarding ARM', 'Defender for Cloud Onboarding', 'azuredeploy.json'],
        ['escaped cost-estimation ARM', 'Defender for Containers Cost Estimation', 'azuredeploy.json'],
        ['escaped framework ARM', 'WellArchitected Framework Security', 'armTemplate.json'],
        ['pricing-estimator ARM', 'Microsoft Defender for Key Vault Price Estimation', 'armTemplate.json']
    ];
    for (const [label, directory, filename] of examples) {
        it(`loads an existing ${label} example through the shared browser input path`, () => {
            const input = loadValidationInput(path.join(repository, 'Workbooks', directory, filename));
            const workbook = JSON.parse(input.source.replace(/^\uFEFF/, ''));
            assert.equal(workbook.version, 'Notebook/1.0');
            assert.isArray(workbook.items);
            assert.isAbove(createValidationPlan(input.source).itemCount, 0);
        });
    }

    it('directs the dynamic Synack ARM template to its native workbook rather than evaluating secrets', () => {
        const directory = path.join(repository, 'Workbooks', 'Synack Vulnerabilities');
        assert.throws(() => loadValidationInput(path.join(directory, 'armTemplate.json')), /Unsupported ARM expression/);
        assert.isAbove(createValidationPlan(loadValidationInput(
            path.join(directory, 'SynackVulnerabilities.workbook')).source).itemCount, 0);
    });
});

describe('Generating portable browser scripts from ARM templates...', () => {
    let directory;
    before(() => { directory = fs.mkdtempSync(path.join(os.tmpdir(), 'defender-workbook-source-')); });
    after(() => {
        for (const filename of fs.readdirSync(directory)) fs.unlinkSync(path.join(directory, filename));
        fs.rmdirSync(directory);
    });

    function generate(workbook, output) {
        return spawnSync(process.execPath, [path.join(browserDirectory, 'generateScript.js'),
            '--workbook', workbook, '--output', output], { encoding: 'utf8', cwd: repository, timeout: 10000 });
    }

    it('loads either native extension independently of the filename', () => {
        for (const extension of ['json', 'workbook']) {
            const filename = path.join(directory, `native.${extension}`);
            fs.writeFileSync(filename, source);
            assert.equal(loadValidationInput(filename).source, source);
        }
    });

    it('embeds only extracted workbook data, not ARM parameters or unrelated values', async () => {
        const filename = path.join(directory, 'arm.json');
        const output = path.join(directory, 'arm-runner.js');
        fs.writeFileSync(filename, armSource("[string(variables('content'))]", {
            content: JSON.parse(source), unrelated: 'do-not-embed-unrelated-template-data'
        }));
        const result = generate(filename, output);
        assert.equal(result.status, 0, result.stderr);
        const script = fs.readFileSync(output, 'utf8');
        assert.notInclude(script, 'do-not-embed-unrelated-template-data');
        assert.notInclude(script, "require('");
        const run = vm.runInNewContext(`(${script})`);
        await rejects(run({ url() { throw new Error('Offline generation must not access a browser.'); } }), /PAUSED/);
    });

    it('leaves no success-shaped runner when ARM extraction fails', () => {
        const filename = path.join(directory, 'unsupported.json');
        const output = path.join(directory, 'must-not-exist.js');
        fs.writeFileSync(filename, armSource("[parameters('content')]"));
        const result = generate(filename, output);
        assert.equal(result.status, 1);
        assert.include(result.stderr, 'Unsupported ARM expression');
        assert.isFalse(fs.existsSync(output));
    });

    it('fails explicitly without browser configuration instead of skipping the opt-in suite', () => {
        const env = { ...process.env };
        for (const name of Object.keys(env)) {
            if (name.startsWith('WORKBOOK_BROWSER_')) delete env[name];
        }
        const result = spawnSync(process.execPath, [require.resolve('mocha/bin/mocha.js'),
            path.join(browserDirectory, 'workbookValidation.test.js')],
        { encoding: 'utf8', env, timeout: 15000 });
        assert.equal(result.status, 1, result.stderr);
        assert.include(result.stdout + result.stderr, 'WORKBOOK_BROWSER_TEMPLATE');
    });
});
