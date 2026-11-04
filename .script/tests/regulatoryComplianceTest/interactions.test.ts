import { expect } from "chai";
import fs from "fs";
import path from "path";
import { IsValidJsonFile } from "../../jsonFileValidator";
import { ExitCode } from "../../utils/exitCode";

interface Visibility {
  parameterName: string;
  comparison: string;
  value: string;
}

interface Criteria {
  leftOperand?: string;
  operator: string;
  rightValType?: string;
  rightVal?: string;
  resultValType: string;
  resultVal: string;
}

interface Parameter {
  name: string;
  type: number;
  multiSelect?: boolean;
  isGlobal?: boolean;
  isHiddenWhenLocked?: boolean;
  value?: string | string[];
  defaultValue?: string;
  query?: string;
  crossComponentResources?: string[];
  criteriaData?: { criteriaContext: Criteria }[];
}

interface Link {
  cellValue: string;
  linkTarget: string;
  linkLabel: string;
  subTarget: string;
}

interface Item {
  name: string;
  type: number;
  conditionalVisibility?: Visibility;
  content: {
    items?: Item[];
    parameters?: Parameter[];
    query?: string;
    json?: string;
    crossComponentResources?: string[];
    exportedParameters?: {
      fieldName: string;
      parameterName: string;
      parameterType: number;
      defaultValue: string;
    }[];
    links?: Link[];
  };
}

interface Counts {
  Passed: number | null;
  Failed: number | null;
  Skipped: number | null;
  Unsupported: number | null;
}

interface Row extends Counts {
  id: string;
}

const folder = path.resolve(__dirname, "..", "..", "..", "Workbooks", "Regulatory Compliance");
const source = fs.readFileSync(path.join(folder, "regulatorycompliance.workbook"));
const workbook: { items: Item[] } = JSON.parse(source.toString("utf8"));
const allItems: Item[] = [];

function collect(items: Item[]): void {
  for (const entry of items) {
    allItems.push(entry);
    if (entry.content.items) collect(entry.content.items);
  }
}
collect(workbook.items);

function item(name: string): Item {
  const matches = allItems.filter(entry => entry.name === name);
  expect(matches.length, name).to.equal(1);
  return matches[0];
}

function query(name: string): string {
  const value = item(name).content.query;
  if (typeof value !== "string") throw new Error(`Missing query: ${name}`);
  return value;
}

function parameter(name: string): Parameter {
  const matches: Parameter[] = [];
  for (const entry of allItems) {
    for (const candidate of entry.content.parameters || []) {
      if (candidate.name === name) matches.push(candidate);
    }
  }
  expect(matches.length, name).to.equal(1);
  return matches[0];
}

function membership(detail: string, subscriptions: string[]): string {
  const criteria = parameter("WorkloadDetailInGlobal").criteriaData;
  if (!criteria) throw new Error("Missing membership criteria");
  const values: { [name: string]: string | string[] } = {
    WorkloadDetailSubscription: detail,
    Subscription: subscriptions
  };
  for (const rule of criteria) {
    const context = rule.criteriaContext;
    expect(context.resultValType).to.equal("static");
    if (context.operator === "Default") return context.resultVal;
    if (!context.leftOperand) throw new Error("Missing left operand");
    const left = values[context.leftOperand];
    if (left === undefined) throw new Error(`Unknown operand: ${context.leftOperand}`);
    const right = context.rightValType === "param" ? values[context.rightVal || ""] : context.rightVal;
    let matches: boolean;
    if (context.operator === "is Empty") {
      matches = left.length === 0;
    } else if (context.operator === "contains" && typeof right === "string") {
      matches = left.includes(right);
    } else {
      throw new Error(`Unsupported membership criterion: ${context.operator}`);
    }
    if (matches) return context.resultVal;
  }
  throw new Error("Membership criteria have no default");
}

const countNames: (keyof Counts)[] = ["Passed", "Failed", "Skipped", "Unsupported"];
const fixtures: Row[] = [
  { id: "failed", Passed: 3, Failed: 2, Skipped: 0, Unsupported: 0 },
  { id: "passed", Passed: 7, Failed: 0, Skipped: 0, Unsupported: 0 },
  { id: "skipped", Passed: 0, Failed: 0, Skipped: 4, Unsupported: 0 },
  { id: "unsupported", Passed: 0, Failed: 0, Skipped: 0, Unsupported: 6 },
  { id: "incomplete", Passed: 1, Failed: 0, Skipped: null, Unsupported: 0 }
];

function selectOutcome(rows: Row[], outcome: string): Row[] {
  if (outcome === "All") return rows;
  const selected = countNames.find(name => name === outcome);
  if (!selected) return [];
  return rows.filter(row => {
    const complete = countNames.every(name => {
      const count = row[name];
      return count !== null && count >= 0;
    });
    const count = row[selected];
    return complete && count !== null && count > 0;
  });
}

describe("regulatoryComplianceInteractions", () => {
  const detail = "/subscriptions/00000000-0000-0000-0000-000000000001";
  const other = "/subscriptions/00000000-0000-0000-0000-000000000002";
  const detailQueries = [
    "WorkloadResourceCoverage",
    "WorkloadResources",
    "WorkloadSelectedResourceCoverage",
    "WorkloadResourceFindings"
  ];

  it("uses a single native subscription picker with an empty default and globally scoped options", () => {
    const picker = parameter("WorkloadDetailSubscription");
    expect(picker.type).to.equal(6);
    expect(picker.multiSelect).to.equal(false);
    expect(picker.value).to.equal("");
    expect(picker.defaultValue).to.equal("");
    expect(picker.query).to.include("| project value = id, label = name");
    expect(picker.crossComponentResources).to.deep.equal(["{Subscription}"]);
  });

  it("declares hidden membership criteria immediately after the picker, before consumers", () => {
    const parameters = item("WorkloadResourceFilters").content.parameters;
    if (!parameters) throw new Error("Missing resource filters");
    const index = parameters.findIndex(value => value.name === "WorkloadDetailSubscription");
    expect(parameters[index + 1].name).to.equal("WorkloadDetailInGlobal");
    expect(parameters[index + 1].isHiddenWhenLocked).to.equal(true);
    expect(parameters[index + 1].criteriaData).to.have.length(4);
    expect(JSON.stringify(parameters[index + 1])).not.to.include("WorkloadResourceScope");
    expect(allItems.indexOf(item("WorkloadResourceFilters"))).to.be.lessThan(allItems.indexOf(item("WorkloadResourceBrowser")));
  });

  [
    { title: "empty detail under All", detail: "", global: ["value::all"], expected: "no" },
    { title: "empty detail under explicit subscriptions", detail: "", global: [detail], expected: "no" },
    { title: "detail under All", detail, global: ["value::all"], expected: "yes" },
    { title: "detail included explicitly", detail, global: [other, detail], expected: "yes" },
    { title: "detail excluded explicitly", detail, global: [other], expected: "no" },
    { title: "empty global scope", detail, global: [], expected: "no" }
  ].forEach(testCase => {
    it(`evaluates membership for ${testCase.title}`, () => {
      expect(membership(testCase.detail, testCase.global)).to.equal(testCase.expected);
    });
  });

  it("handles All, inclusion, exclusion and clearing transitions without depending on a resource selection", () => {
    expect([
      membership(detail, ["value::all"]),
      membership(detail, [detail, other]),
      membership(detail, [other]),
      membership(detail, [detail]),
      membership("", [detail])
    ]).to.deep.equal(["yes", "yes", "no", "yes", "no"]);
  });

  it("composes supported native visibility gates for nonempty detail and global membership", () => {
    const browser = item("WorkloadResourceBrowser");
    expect(browser.conditionalVisibility).to.deep.equal({
      parameterName: "WorkloadDetailSubscription", comparison: "isNotEqualTo", value: ""
    });
    const gate = item("WorkloadDetailGlobalScopeGate");
    expect(browser.content.items).to.deep.equal([gate]);
    expect(gate.conditionalVisibility).to.deep.equal({
      parameterName: "WorkloadDetailInGlobal", comparison: "isEqualTo", value: "yes"
    });
    for (const name of detailQueries) {
      expect(gate.content.items && gate.content.items.some(entry => entry.name === name), name).to.equal(true);
    }
  });

  detailQueries.forEach(name => {
    it(`scopes ${name} to the detail subscription and intersects both join inputs with global scope`, () => {
      expect(item(name).content.crossComponentResources).to.deep.equal(["{WorkloadDetailSubscription}"]);
      const kql = query(name);
      const lines = kql.split(/\r?\n/);
      const equality = '| where subscriptionId == "{WorkloadDetailSubscription:id}"';
      const indices = lines.map((line, index) => line.trim() === equality ? index : -1).filter(index => index >= 0);
      expect(indices).to.have.length(2);
      for (const index of indices) {
        expect(lines[index + 1].trim()).to.equal("| where subscriptionId in~ ({Subscription:subid})");
      }
      expect(kql).not.to.include("{WorkloadDetailSubscription:escapejson}");
      expect(kql.split("{Subscription:subid}")).to.have.length(3);
    });
  });

  it("keeps the all-state workload summary globally scoped and independent of detail filters", () => {
    expect(item("WorkloadSummary").content.crossComponentResources).to.deep.equal(["{Subscription}"]);
    expect(query("WorkloadSummary")).not.to.match(/WorkloadDetailSubscription|WorkloadResourceSearch|WorkloadResourceScope/);
  });

  it("keeps resource selection separate from its producing query and gates recommendation queries", () => {
    expect(query("WorkloadResources")).not.to.include("{WorkloadResourceScope");
    expect(item("WorkloadResources").content.exportedParameters).to.deep.equal([{
      fieldName: "", parameterName: "WorkloadResourceScope", parameterType: 1, defaultValue: "{}"
    }]);
    for (const name of ["WorkloadSelectedResourceCoverage", "WorkloadResourceFindings"]) {
      expect(query(name)).to.include("{WorkloadResourceScope:escapejson}");
      expect(item(name).conditionalVisibility).to.deep.equal({
        parameterName: "WorkloadResourceScope", comparison: "isNotEqualTo", value: "{}"
      });
    }
  });

  it("accurately labels the detail-only clear without blanking the subscription or refreshing the grid", () => {
    const links = item("ClearWorkloadResourceSelection").content.links;
    if (!links) throw new Error("Missing resource detail hide link");
    expect(links).to.have.length(1);
    expect(links[0]).to.include({
      cellValue: "WorkloadResourceScope",
      linkTarget: "parameter",
      linkLabel: "Hide resource details",
      subTarget: "{}"
    });
  });

  it("keeps reselection guidance visible after details are hidden and preserves completeness warnings", () => {
    const guidance = item("WorkloadDetailGuidance");
    expect(guidance.conditionalVisibility).to.equal(undefined);
    expect(guidance.content.json).to.include("not the grid's selected row");
    expect(guidance.content.json).to.include("deselect its row checkbox, then select it again");
    expect(guidance.content.json).to.include("Keyboard users");
    expect(guidance.content.json).to.include("native partial-query warnings");
    expect(guidance.content.json).to.include("do **not** guarantee complete Resource Graph results or exports");
    expect(guidance.content.json).to.include("every parameter-update race");
  });

  it("exports the chart label as a text outcome with All as the no-selection default", () => {
    expect(item("OverviewControlOutcomes").content.exportedParameters).to.deep.equal([{
      fieldName: "label", parameterName: "OverviewOutcome", parameterType: 1, defaultValue: "All"
    }]);
    const outcome = parameter("OverviewOutcome");
    expect(outcome.type).to.equal(1);
    expect(outcome.value).to.equal("All");
    expect(outcome.isGlobal).to.equal(true);
    expect(outcome.isHiddenWhenLocked).to.equal(true);
    expect(query("OverviewControlOutcomes")).not.to.include("{OverviewOutcome");
    expect(query("ComplianceCoverage")).not.to.include("{OverviewOutcome");
  });

  it("uses the chart's exact complete four-count guard inside the selected-outcome branch only", () => {
    const guardLine = query("OverviewControlOutcomes").split(/\r?\n/).find(line => line.startsWith("| where isnotnull(Passed)"));
    if (!guardLine) throw new Error("Missing chart guard");
    const completeGuard = countNames.map(name => `isnotnull(${name})`).join(" and ") +
      " and " + countNames.map(name => `${name} >= 0`).join(" and ");
    expect(guardLine).to.equal(`| where ${completeGuard}`);
    const positive = ["Failed", "Passed", "Skipped", "Unsupported"].map(state =>
      `("{OverviewOutcome:escapejson}" == '${state}' and ${state} > 0)`).join(" or ");
    const expected = `| where "{OverviewOutcome:escapejson}" == 'All' or (${guardLine.slice(8)} and (${positive}))`;
    const kql = query("regulatorycompliancesummary");
    expect(kql.split(/\r?\n/).filter(line => line.includes("{OverviewOutcome:escapejson}"))).to.deep.equal([expected]);
    for (const column of ["passedControls", "failedControls", "skippedControls", "unsupportedControls"]) {
      expect(kql).to.include(`tolong(properties.${column})`);
    }
  });

  [
    { state: "All", ids: ["failed", "passed", "skipped", "unsupported", "incomplete"] },
    { state: "Failed", ids: ["failed"] },
    { state: "Passed", ids: ["failed", "passed"] },
    { state: "Skipped", ids: ["skipped"] },
    { state: "Unsupported", ids: ["unsupported"] }
  ].forEach(testCase => {
    it(`applies the ${testCase.state} contract to five invented fixture rows`, () => {
      expect(selectOutcome(fixtures, testCase.state).map(row => row.id)).to.deep.equal(testCase.ids);
    });
  });

  for (const name of countNames) {
    for (const invalid of [null, -1]) {
      it(`retains ${name}=${invalid} under All but excludes it from every selected outcome`, () => {
        const row: Row = { id: "invalid", Passed: 1, Failed: 1, Skipped: 1, Unsupported: 1 };
        row[name] = invalid;
        expect(selectOutcome([row], "All")).to.deep.equal([row]);
        for (const state of countNames) expect(selectOutcome([row], state)).to.deep.equal([]);
      });
    }
  }

  it("requires a strictly positive selected count, handles empty scopes, and does not broaden invalid outcomes", () => {
    const zero: Row = { id: "zero", Passed: 0, Failed: 0, Skipped: 0, Unsupported: 0 };
    for (const state of countNames) {
      expect(selectOutcome([zero], state)).to.deep.equal([]);
      expect(selectOutcome([], state)).to.deep.equal([]);
    }
    expect(selectOutcome([], "All")).to.deep.equal([]);
    expect(selectOutcome(fixtures, "unexpected")).to.deep.equal([]);
  });

  it("provides an always-available native clear action that changes only the outcome filter", () => {
    const clear = item("ClearOverviewOutcome");
    expect(clear.conditionalVisibility).to.equal(undefined);
    const links = clear.content.links;
    if (!links) throw new Error("Missing outcome clear link");
    expect(links).to.have.length(1);
    expect(links[0]).to.include({
      cellValue: "OverviewOutcome", linkTarget: "parameter", subTarget: "All", linkLabel: "Clear outcome filter (show all)"
    });
    expect(selectOutcome(fixtures, links[0].subTarget)).to.deep.equal(fixtures);
    expect(query("OverviewControlOutcomes")).to.include("{Control:escapejson}");
    expect(query("regulatorycompliancesummary")).to.include("{Control:escapejson}");
    for (const name of ["OverviewControlOutcomes", "regulatorycompliancesummary"]) {
      expect(item(name).content.crossComponentResources).to.deep.equal(["{Subscription}"]);
    }
  });

  it("shows active outcome state, Enter-key guidance, legend-toggle reset, and parameter-clear limitations", () => {
    const guidance = item("OverviewControlOutcomesGuidance");
    expect(guidance.conditionalVisibility).to.equal(undefined);
    expect(guidance.content.json).to.include("Active table outcome filter: {OverviewOutcome}");
    expect(guidance.content.json).to.include("press **Enter**");
    expect(guidance.content.json).to.include("selecting it again returns the table to All");
    expect(guidance.content.json).to.include("Space may not activate");
    expect(guidance.content.json).to.include("A legend highlight can remain");
  });

  it("embeds the exact LF UTF-8 standalone bytes without changing the ARM decoding expression", () => {
    const template: {
      variables: { workbookDataBase64: string };
      resources: { properties: { serializedData: string } }[];
    } = JSON.parse(fs.readFileSync(path.join(folder, "armTemplate.json"), "utf8"));
    expect(Buffer.from(template.variables.workbookDataBase64, "base64").equals(source)).to.equal(true);
    expect(source.includes(Buffer.from("\r"))).to.equal(false);
    expect(source.slice(0, 3).equals(Buffer.from([0xef, 0xbb, 0xbf]))).to.equal(false);
    expect(template.resources[0].properties.serializedData).to.equal("[base64ToString(variables('workbookDataBase64'))]");
  });

  it("passes the repository JSON validator for both workbook and ARM artifacts", async () => {
    for (const name of ["regulatorycompliance.workbook", "armTemplate.json"]) {
      expect(await IsValidJsonFile(path.join(folder, name))).to.equal(ExitCode.SUCCESS);
    }
  });
});
