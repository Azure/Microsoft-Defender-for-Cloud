const fs = require('fs');
const path = require('path');
const minimist = require('minimist');
const { loadValidationInput, createPlaywrightScript } = require('./workbookBrowserValidator');

function main(argv) {
    const args = minimist(argv, {
        string: ['workbook', 'checks', 'output', 'screenshots', 'tenant', 'redaction', 'evidence-mode'],
        boolean: ['help', 'confirm-tenant', 'allow-sensitive-capture'],
        unknown() {
            throw new Error('Unsupported argument. Use --workbook, --checks, --output, --screenshots, --tenant, --confirm-tenant, --redaction, --allow-sensitive-capture, --evidence-mode, or --help.');
        }
    });
    if (args.help) {
        console.log('Usage: npm run test:browser:script -- --workbook <file> [--checks <json>] [--tenant <guid> --confirm-tenant] [--evidence-mode <synthetic|authenticated|unspecified>] [--screenshots <local-directory> --redaction <auto|manual|ai-assisted|none> --allow-sensitive-capture] --output <new-script.js>');
        return;
    }
    if (args._.length || typeof args.output !== 'string' || !args.output.trim()) {
        throw new Error('Provide --workbook and --output; the output file must not already exist.');
    }
    const explicitFlag = name => argv.some(argument => argument === `--${name}` || argument === `--no-${name}` ||
        argument.startsWith(`--${name}=`) || argument.startsWith(`--no-${name}=`)) ?
        args[name] : undefined;
    const input = loadValidationInput(args.workbook, args.checks, args.screenshots, {
        tenantId: args.tenant,
        confirmTenant: explicitFlag('confirm-tenant'),
        redaction: args.redaction,
        allowSensitiveCapture: explicitFlag('allow-sensitive-capture'),
        evidenceMode: args['evidence-mode']
    });
    fs.writeFileSync(args.output, createPlaywrightScript(input.source, input.options), { encoding: 'utf8', flag: 'wx' });
    console.log(`Created ${path.basename(args.output)}. Run it in a new empty unsaved workbook's Advanced Editor.`);
    if (input.options.scenarios?.length) {
        console.log('Interaction scenarios use an explicitly instrumented unsaved test copy with private parameter probes. Original/imported hashes are reported separately; production files are not changed.');
    }
    if (input.reviewPlan.needsCloserLook.length) {
        console.log(`Needs closer look: ${input.reviewPlan.needsCloserLook.length} planned review items remain unexecuted. Generation is not validation.`);
    }
    if (input.sourceDiagnostics.length) {
        console.warn(`Source risk diagnostics: ${input.sourceDiagnostics.map(finding =>
            `${finding.code} (item ${finding.itemIndex})`).join(', ')}. Review these risks; diagnostics never rewrite production files.`);
    }
    if (!input.options.tenant?.confirmed) {
        console.log('PAUSED for live execution: ask which Azure tenant to use and wait for explicit user selection/confirmation, even in autopilot. Do not select a default.');
    }
    console.log(input.options.screenshots ?
        input.options.screenshots.redaction && input.options.screenshots.redaction !== 'auto' ?
            'WARNING: approved selective/unredacted screenshots may contain sensitive content. Keep local for manual editing/review; no AI service or upload runs automatically.' :
            'Screenshots are enabled with conservative masking. If too much is hidden, offer manual or AI-assisted mask selection, or explicitly approved unredacted local capture. Review every image before sharing; no automatic upload.' :
        'Would screenshots help? Opt in with --screenshots <local-directory>; screenshots remain disabled by default.');
}

if (require.main === module) {
    try {
        main(process.argv.slice(2));
    } catch (error) {
        console.error(error.message);
        process.exitCode = 1;
    }
}

module.exports = { main };
