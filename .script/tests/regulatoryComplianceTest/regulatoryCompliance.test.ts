import { existsSync, readFileSync } from "fs";
import { join } from "path";
import chai from "chai";

type Named = { name: string };
const { expect } = chai;

describe("Regulatory Compliance workbook", () => {
  const directory = join("Workbooks", "Regulatory Compliance");
  const workbookText = readFileSync(join(directory, "regulatorycompliance.json"), "utf8");
  const workbook = JSON.parse(workbookText);
  const template = JSON.parse(readFileSync(join(directory, "armTemplate.json"), "utf8"));
  const resource = template.resources.find((item: { type: string }) =>
    item.type.toLowerCase() === "microsoft.insights/workbooks");
  const overview = workbook.items.find((item: Named) => item.name === "RegulatoryComplianceOverview").content.items;
  const workloads = workbook.items.find((item: Named) => item.name === "RegulatoryComplianceWorkloads").content.items;
  const detail = workbook.items.find((item: Named) => item.name === "RegulatoryComplianceDetail").content.items;
  const workload = workloads.find((item: Named) => item.name === "WorkloadFilters").content.parameters
    .find((parameter: Named) => parameter.name === "Workload");
  const state = detail.find((item: Named) => item.name === "reg-comp-selection").content.parameters
    .find((parameter: Named) => parameter.name === "DetailState");
  const grid = detail.find((item: Named) => item.name === "RegulatoryComplianceBreakdown").content;

  it("provides standalone Notebook JSON for portal import, not an ARM envelope", () => {
    expect(workbook.version).to.equal("Notebook/1.0");
    expect(workbook.items).to.be.an("array").that.is.not.empty;
    expect(workbook.$schema).to.equal(
      "https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"
    );
    expect(workbook).not.to.have.property("resources");
    expect(existsSync(join(directory, "regulatorycompliance.workbook"))).to.equal(false);
  });

  it("deploys the exact UTF-8 standalone payload through a short ARM base64 expression", () => {
    expect(resource.properties.serializedData).to.equal("[base64ToString(variables('workbookDataBase64'))]");
    const encoded = template.variables.workbookDataBase64;
    const decoded = Buffer.from(encoded, "base64");
    expect(decoded.toString("base64")).to.equal(encoded);
    expect(decoded.toString("utf8")).to.equal(workbookText);
    expect(JSON.parse(decoded.toString("utf8"))).to.deep.equal(workbook);
  });

  it("uses the Storage deployment API while preserving existing Compliance defaults and resource identity", () => {
    expect(resource.apiVersion).to.equal("2023-06-01");
    expect(resource.kind).to.equal("shared");
    expect(resource.name).to.equal("[guid(resourceGroup().id, deployment().name)]");
    expect(resource.location).to.equal("[parameters('location')]");
    expect(resource.properties.displayName).to.equal("[parameters('workbookName')]");
    expect(resource.properties.sourceId).to.equal("[parameters('workbookSourceId')]");
    expect(resource.properties.category).to.equal("workbook");
    expect(resource.properties.version).to.equal("1.0");
    expect(resource.properties).not.to.have.property("tags");
    expect(template.parameters.workbookName.defaultValue).to.equal("Microsoft Defender for Cloud - Regulatory Compliance");
    expect(template.parameters.location.defaultValue).to.equal("[resourceGroup().location]");
    expect(template.parameters.workbookSourceId.defaultValue).to.equal("azure security center");
    expect(template.outputs.workbookId.value).to.equal(
      `[resourceId('Microsoft.Insights/workbooks', ${resource.name.slice(1, -1)})]`
    );
    expect(Buffer.byteLength(JSON.stringify(template), "utf8")).to.be.lessThan(4 * 1024 * 1024);
  });

  it("keeps deployment bytes stable across Windows and Unix Git checkouts", () => {
    const attributes = readFileSync(join(directory, ".gitattributes"), "utf8");
    for (const filename of ["regulatorycompliance.json", "armTemplate.json"]) {
      expect(attributes.split(/\r?\n/)).to.include(`${filename} text eol=lf`);
      expect(readFileSync(join(directory, filename), "utf8")).not.to.contain("\r\n");
    }
  });

  it("documents separate paste and deployment paths with valid local artifact links", () => {
    const readme = readFileSync(join(directory, "README.md"), "utf8");
    expect(readme).to.contain("Workbook Template");
    expect(readme).to.contain("Gallery Template");
    expect(readme).to.contain("not `armTemplate.json`");
    expect(readme).to.contain("variables.workbookDataBase64");
    expect(readme).to.contain("base64ToString");
    expect(readme).not.to.contain("./regulatorycompliance.workbook");
    for (const filename of ["regulatorycompliance.json", "armTemplate.json"]) {
      expect(readme).to.contain(`](./${filename})`);
      expect(existsSync(join(directory, filename))).to.equal(true);
    }
  });

  it("uses the portal Full size so coverage tiles determine their height and can wrap", () => {
    const coverage = overview.find((item: Named) => item.name === "ComplianceCoverage").content;
    expect(coverage.size).to.equal(3);
    expect(coverage.visualization).to.equal("tiles");
    expect(coverage.tileSettings.size).to.equal("auto");
  });

  it("charts standard-reported control counts without treating missing results as zero", () => {
    const chart = overview.find((item: Named) => item.name === "OverviewControlOutcomes").content;
    expect(chart.visualization).to.equal("barchart");
    expect(chart.crossComponentResources).to.deep.equal(["{Subscription}"]);
    expect(chart.query).to.contain("\"{Control:escapejson}\" == '*'");
    expect(chart.query).to.contain("isnotnull(Passed) and isnotnull(Failed)");
    expect(chart.query).to.contain("isnotnull(Skipped) and isnotnull(Unsupported)");
    expect(chart.query).to.contain("CompleteRows = count()");
    expect(chart.query).to.contain("| where CompleteRows > 0");
    expect(chart.query).to.contain("| mv-expand Outcome = Outcomes limit 4");
    expect(chart.query).not.to.contain("PassPercent");
  });

  it("detects control states within exactly the grid's scope without depending on itself", () => {
    const filter = "\r\n| where '{DetailState}' == 'All' or State == '{DetailState}'";
    const index = grid.query.indexOf(filter);
    expect(index).to.be.greaterThan(0);
    expect(state.query.slice(0, index)).to.equal(grid.query.slice(0, index));
    expect(state.query).not.to.contain("{DetailState}");
    expect(state.query).to.contain("| distinct value, label");
    expect(state.query).not.to.contain("| take ");
    expect(state.queryType).to.equal(1);
    expect(state.resourceType).to.equal("microsoft.resourcegraph/resources");
    expect(state.crossComponentResources).to.deep.equal(grid.crossComponentResources);
    expect(state).not.to.have.property("jsonData");
  });

  it("keeps All available by default even when the scoped state query returns no rows", () => {
    expect(state.value).to.equal("value::all");
    expect(state.defaultValue).to.equal("value::all");
    expect(state.typeSettings.additionalResourceOptions).to.include("value::all");
    expect(state.typeSettings.selectAllValue).to.equal("All");
  });

  for (const name of ["Failed", "Passed", "Skipped", "Unsupported"]) {
    it(`preserves ${name} in the shared case-insensitive control-state normalization`, () => {
      expect(state.query).to.contain(`RawState =~ '${name}', '${name}'`);
    });
  }

  it("retains explicit not-applicable and unknown states instead of marking them passed", () => {
    expect(state.query).to.contain(
      "RawState =~ 'NotApplicable' or RawState =~ 'Not applicable', 'Not applicable', 'Unknown')"
    );
    const formatter = grid.gridSettings.formatters.find((item: { columnMatch: string }) => item.columnMatch === "State");
    const threshold = formatter.formatOptions.thresholdsGrid
      .find((item: { thresholdValue: string }) => item.thresholdValue === "Not applicable");
    expect(threshold.representation).to.equal("Unavailable");
  });

  it("offers workload checkboxes with one native All option selected by default", () => {
    expect(workload.multiSelect).to.equal(true);
    expect(workload.isRequired).to.equal(true);
    expect(workload.value).to.deep.equal(["value::all"]);
    expect(workload.defaultValue).to.equal("value::all");
    expect(workload.typeSettings.additionalResourceOptions).to.deep.equal(["value::all"]);
    expect(workload.typeSettings.selectAllValue).to.equal("*");
    expect(JSON.parse(workload.jsonData).map((option: { value: string }) => option.value)).not.to.include("All");
    expect(workload.quote).to.equal("'");
    expect(workload.delimiter).to.equal(",");
  });

  it("uses identical list membership in summary and findings for All, one, or several workloads", () => {
    const predicate = "| where '*' in ({Workload}) or Workload in ({Workload})";
    const queries = ["WorkloadSummary", "WorkloadResourceFindings"]
      .map(name => workloads.find((item: Named) => item.name === name).content.query);
    for (const query of queries) {
      expect(query.split(predicate)).to.have.lengthOf(2);
      expect(query).not.to.contain("'{Workload}'");
      for (const values of [["*"], ["Compute"], ["Compute", "Storage"]]) {
        const expanded = values.map(value => workload.quote + value + workload.quote).join(workload.delimiter);
        const filter = predicate.replace(/\{Workload\}/g, expanded);
        expect(filter).to.equal(`| where '*' in (${expanded}) or Workload in (${expanded})`);
        expect(query.replace(/\{Workload\}/g, expanded)).to.contain(filter);
      }
    }
    expect(queries[0]).not.to.contain("{WorkloadState}");
    expect(queries[1]).to.contain("{WorkloadState}");
  });
});
