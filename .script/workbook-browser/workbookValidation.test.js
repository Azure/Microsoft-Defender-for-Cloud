const {
    isAzurePortalUrl,
    loadValidationInput,
    validateCdpEndpoint,
    requireConfirmedTenant,
    validateWorkbookInBrowser
} = require('./workbookBrowserValidator');

describe('Validating workbook browser behavior (opt-in)...', function () {
    let browser;
    let page;
    let input;

    before(async function () {
        const flag = name => {
            const value = process.env[name];
            if (value === undefined) return undefined;
            if (!['true', 'false'].includes(value)) throw new Error(`${name} must be true or false.`);
            return value === 'true';
        };
        input = loadValidationInput(process.env.WORKBOOK_BROWSER_TEMPLATE, process.env.WORKBOOK_BROWSER_CHECKS,
            process.env.WORKBOOK_BROWSER_SCREENSHOTS, {
                tenantId: process.env.WORKBOOK_BROWSER_TENANT_ID,
                confirmTenant: flag('WORKBOOK_BROWSER_TENANT_CONFIRMED'),
                redaction: process.env.WORKBOOK_BROWSER_REDACTION,
                allowSensitiveCapture: flag('WORKBOOK_BROWSER_ALLOW_SENSITIVE_CAPTURE'),
                evidenceMode: process.env.WORKBOOK_BROWSER_EVIDENCE_MODE
            });
        let phase = 'tenant-confirmation';
        try {
            requireConfirmedTenant(input.options.tenant);
            phase = 'browser-connection';
            const endpoint = validateCdpEndpoint(process.env.WORKBOOK_BROWSER_CDP_ENDPOINT);
            const { chromium } = require('playwright-core');
            browser = await chromium.connectOverCDP(endpoint, { timeout: 15000 });
            phase = 'eligible-unsaved-workbook';
            const candidates = [];
            for (const context of browser.contexts()) {
                for (const candidate of context.pages()) {
                    if (isAzurePortalUrl(candidate.url()) &&
                        await candidate.getByRole('heading', { name: /\bUnsaved Workbook\b/ }).count() === 1 &&
                        await candidate.locator('iframe[name="Workbooks.ReactView"]').contentFrame()
                            .getByRole('textbox', { name: 'Editor content', exact: true }).count() === 1) {
                        candidates.push(candidate);
                    }
                }
            }
            if (candidates.length !== 1) {
                throw new Error(`Open exactly one new empty unsaved workbook in Advanced Editor; found ${candidates.length} eligible pages.`);
            }
            page = candidates[0];
        } catch (error) {
            console.log(JSON.stringify({ ...input.reviewPlan, status: 'blocked', phase }, null, 2));
            throw error;
        }
    });

    after(async function () {
        if (browser) {
            // This client creates no contexts; closing a connected browser disconnects this client.
            await browser.close();
        }
    });

    it('imports the exact source and checks primary tabs and requested contracts', async function () {
        try {
            const report = await validateWorkbookInBrowser(page, input.source, input.options);
            console.log(JSON.stringify(report, null, 2));
        } catch (error) {
            if (error.report) console.log(JSON.stringify(error.report, null, 2));
            throw error;
        }
    });
});
