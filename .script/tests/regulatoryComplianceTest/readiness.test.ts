import { readFileSync } from "fs";
import { join } from "path";
import chai from "chai";

const { expect } = chai;
const stream = "RegulatoryComplianceAssessment";
const snapshot = "RegulatoryComplianceAssessmentSnapshot";
const destination = (name: string): string =>
  `/subscriptions/destination/resourceGroups/logs/providers/Microsoft.OperationalInsights/workspaces/${name}`;

interface Source {
  eventSource: string;
  ruleSets?: unknown;
}

interface Automation {
  subscriptionId: string;
  enabled: boolean | null;
  scopes: string[];
  actions: { actionType: string; workspaceResourceId: string }[];
  sources: Source[];
}

interface Counts {
  pass: number;
  partial: number;
  disabled: number;
  unknown: number;
}

interface Evidence {
  workspace: string;
  streaming: Counts;
  snapshots: Counts;
  findings: string[];
}

const counts = (): Counts => ({ pass: 0, partial: 0, disabled: 0, unknown: 0 });
const automation = (subscriptionId: string, options: Partial<Automation> = {}): Automation => ({
  subscriptionId,
  enabled: true,
  scopes: [`/subscriptions/${subscriptionId}`],
  actions: [{ actionType: "Workspace", workspaceResourceId: destination("shared") }],
  sources: [{ eventSource: stream }, { eventSource: snapshot }],
  ...options
});

function classify(subscriptionId: string, automations: Automation[]): Evidence[] {
  const rows = new Map<string, Evidence>();
  const subscription = subscriptionId.toLowerCase();
  for (const item of automations.filter(value => value.subscriptionId.toLowerCase() === subscription)) {
    const listsComplete = item.scopes.length <= 2000 && item.actions.length <= 2000 && item.sources.length <= 2000;
    for (const scope of item.scopes.slice(0, 2000)) {
      for (const action of item.actions.slice(0, 2000)) {
        if (action.actionType.toLowerCase() !== "workspace") continue;
        const workspace = action.workspaceResourceId.toLowerCase().replace(/\/+$/, "");
        const validWorkspace = /^\/subscriptions\/[^/]+\/resourcegroups\/[^/]+\/providers\/microsoft[.]operationalinsights\/workspaces\/[^/]+$/.test(workspace);
        for (const source of item.sources.slice(0, 2000)) {
          const eventSource = source.eventSource.toLowerCase();
          if (eventSource !== stream.toLowerCase() && eventSource !== snapshot.toLowerCase()) continue;
          let row = rows.get(workspace);
          if (!row) {
            row = { workspace, streaming: counts(), snapshots: counts(), findings: [] };
            rows.set(workspace, row);
          }
          const unfiltered = source.ruleSets == null || (Array.isArray(source.ruleSets) && source.ruleSets.length === 0);
          const fullScope = scope.toLowerCase().replace(/\/+$/, "") === `/subscriptions/${subscription}`;
          const complete = item.enabled === true && fullScope && validWorkspace && unfiltered && listsComplete;
          const frequency = eventSource === stream.toLowerCase() ? row.streaming : row.snapshots;
          if (complete) frequency.pass++;
          else if (item.enabled === true) frequency.partial++;
          else if (item.enabled === false) frequency.disabled++;
          else frequency.unknown++;
          if (item.enabled === true) {
            if (!fullScope && !row.findings.includes("scope")) row.findings.push("scope");
            if (!unfiltered && !row.findings.includes("filters")) row.findings.push("filters");
            if (!validWorkspace && !row.findings.includes("destination")) row.findings.push("destination");
            if (!listsComplete && !row.findings.includes("expansion")) row.findings.push("expansion");
          }
        }
      }
    }
  }
  return Array.from(rows.values());
}

function frequencyStatus(value: Counts): string {
  if (value.pass) return "Pass";
  if (value.partial) return "Partial / review";
  if (value.unknown) return "Unknown enabled state";
  if (value.disabled) return "Disabled observed";
  return "Not observed";
}

function configurationStatus(row: Evidence | undefined): string {
  if (!row) return "Unknown / not observed";
  const a = row.streaming;
  const b = row.snapshots;
  if (a.pass && b.pass) return "Configuration pass";
  if (a.pass || b.pass || a.partial || b.partial) return "Partial / review";
  if (a.unknown || b.unknown) return "Unknown / review";
  if (a.disabled || b.disabled) return "Disabled / review";
  return "Unknown / not observed";
}

describe("Compliance over time readiness", () => {
  const directory = join("Workbooks", "Regulatory Compliance");
  const workbook = JSON.parse(readFileSync(join(directory, "regulatorycompliance.json"), "utf8"));
  const group = workbook.items.find((item: { name: string }) => item.name === "ComplianceOverTimeReadiness");
  const items = group.content.items;
  const grid = items.find((item: { name: string }) => item.name === "ReadinessConfigurations").content;
  const chart = items.find((item: { name: string }) => item.name === "ReadinessConfigurationChart").content;
  const history = items.find((item: { name: string }) => item.name === "ReadinessHistory");
  const parameters = items.find((item: { name: string }) => item.name === "ReadinessHistoryParameters").content.parameters;
  const workspace = parameters.find((parameter: { name: string }) => parameter.name === "HistoryWorkspace");
  const toggle = parameters.find((parameter: { name: string }) => parameter.name === "CheckHistory");

  it("adds a subscription-scoped, read-only tab without applying the standard filter", () => {
    const links = workbook.items.find((item: { type: number }) => item.type === 11).content.links;
    expect(links.some((link: { subTarget: string }) => link.subTarget === "Readiness")).to.equal(true);
    expect(group.conditionalVisibility).to.deep.equal({
      parameterName: "selectedTab", comparison: "isEqualTo", value: "Readiness"
    });
    expect(grid.crossComponentResources).to.deep.equal(["{Subscription}"]);
    expect(grid.query).not.to.contain("{Control");
    expect(history.content.query).not.to.contain("{Control");
  });

  it("uses the same per-workspace evidence for the chart and the configuration grid", () => {
    const gridBase = grid.query.split("\r\n| project Subscription, subscriptionId, Workspace, Configuration")[0];
    const chartBase = chart.query.split("\r\n| summarize BestConfiguration")[0];
    expect(chartBase).to.equal(gridBase);
    expect(chart.visualization).to.equal("barchart");
    expect(chart.query).to.contain("by subscriptionId");
    expect(chart.query).to.contain("Config pass");
    expect(chart.query).to.contain("Needs review");
    expect(chart.query).to.contain("Not observed");
  });

  it("requires enabled, unfiltered subscription-wide events at the same valid workspace", () => {
    expect(grid.query).to.contain("by subscriptionId, Workspace");
    expect(grid.query).to.contain("Enabled == 'true' and FullScope and ValidWorkspace and Unfiltered and ListsComplete");
    expect(grid.query).to.contain("StreamingPass > 0 and SnapshotPass > 0");
    expect(grid.query).to.contain("iff(isnull(Source.ruleSets), true, coalesce(array_length(Source.ruleSets) == 0, false))");
    expect(grid.query).to.contain("ScopeCount <= 2000 and ActionCount <= 2000 and SourceCount <= 2000");
    expect(grid.query).to.contain("tostring(Action.actionType) =~ 'Workspace'");
  });

  it("passes paired events in one workspace, including separate automations and normalized IDs", () => {
    const rows = classify("a", [
      automation("a", { sources: [{ eventSource: stream }], actions: [{ actionType: "Workspace", workspaceResourceId: destination("SHARED") + "/" }] }),
      automation("a", { sources: [{ eventSource: snapshot }] })
    ]);
    expect(rows).to.have.lengthOf(1);
    expect(configurationStatus(rows[0])).to.equal("Configuration pass");
    expect(frequencyStatus(rows[0].streaming)).to.equal("Pass");
    expect(frequencyStatus(rows[0].snapshots)).to.equal("Pass");
  });

  it("does not combine a stream and snapshot sent to different workspaces", () => {
    const rows = classify("a", [
      automation("a", { actions: [{ actionType: "Workspace", workspaceResourceId: destination("a") }], sources: [{ eventSource: stream }] }),
      automation("a", { actions: [{ actionType: "Workspace", workspaceResourceId: destination("b") }], sources: [{ eventSource: snapshot }] })
    ]);
    expect(rows.map(configurationStatus)).to.deep.equal(["Partial / review", "Partial / review"]);
    expect(rows.map(row => [frequencyStatus(row.streaming), frequencyStatus(row.snapshots)]))
      .to.deep.equal([["Pass", "Not observed"], ["Not observed", "Pass"]]);
  });

  it("treats disabled, unknown, unrelated, Event Hub-only, and unobserved configurations conservatively", () => {
    expect(configurationStatus(classify("a", [automation("a", { enabled: false })])[0])).to.equal("Disabled / review");
    expect(configurationStatus(classify("a", [automation("a", { enabled: null })])[0])).to.equal("Unknown / review");
    expect(configurationStatus(classify("a", [automation("a", { actions: [{ actionType: "EventHub", workspaceResourceId: destination("a") }] })])[0]))
      .to.equal("Unknown / not observed");
    expect(configurationStatus(classify("a", [automation("a", { sources: [{ eventSource: "Assessments" }] })])[0]))
      .to.equal("Unknown / not observed");
    expect(configurationStatus(classify("a", [automation("b")])[0])).to.equal("Unknown / not observed");
  });

  it("flags partial scope, filters, invalid destinations, and oversized arrays instead of passing", () => {
    const cases: { options: Partial<Automation>; finding: string }[] = [
      { options: { scopes: ["/subscriptions/a/resourceGroups/rg"] }, finding: "scope" },
      { options: { sources: [{ eventSource: stream, ruleSets: [{ rules: ["x"] }] }, { eventSource: snapshot }] }, finding: "filters" },
      { options: { sources: [{ eventSource: stream, ruleSets: "invalid" }, { eventSource: snapshot }] }, finding: "filters" },
      { options: { actions: [{ actionType: "Workspace", workspaceResourceId: "" }] }, finding: "destination" },
      { options: { scopes: new Array(2001).fill("/subscriptions/a") }, finding: "expansion" }
    ];
    for (const value of cases) {
      const row = classify("a", [automation("a", value.options)])[0];
      expect(configurationStatus(row), value.finding).to.equal("Partial / review");
      expect(row.findings, value.finding).to.include(value.finding);
    }
  });

  it("preserves extra review findings even when an unfiltered alternative provides a pass", () => {
    const row = classify("a", [automation("a", {
      sources: [{ eventSource: stream, ruleSets: [{ rules: ["x"] }] }, { eventSource: stream }, { eventSource: snapshot, ruleSets: [] }]
    })])[0];
    expect(configurationStatus(row)).to.equal("Configuration pass");
    expect(row.findings).to.include("filters");
    expect(grid.query).to.contain("A complete configuration exists; review the other findings");
  });

  it("reports additional disabled and unknown configurations even when another configuration passes", () => {
    expect(grid.query).to.contain("StreamingDisabled > 0 or SnapshotDisabled > 0, 'Disabled configuration observed; '");
    expect(grid.query).to.contain("StreamingUnknown > 0 or SnapshotUnknown > 0, 'Unknown enabled state observed; '");
    expect(grid.query).to.contain("A complete configuration exists; review the other findings");
  });

  it("requires an explicit workspace history check and allows destinations outside the source subscriptions", () => {
    expect(workspace.multiSelect).to.equal(false);
    expect(workspace.value).to.equal("");
    expect(workspace.crossComponentResources).to.deep.equal(["value::all"]);
    expect(toggle.value).to.equal("Off");
    expect(history.conditionalVisibility).to.deep.equal({
      parameterName: "CheckHistory", comparison: "isEqualTo", value: "On"
    });
    expect(history.content.crossComponentResources).to.deep.equal(["{HistoryWorkspace}"]);
    expect(history.content.timeContext.durationMs).to.equal(90 * 24 * 60 * 60 * 1000);
  });

  it("opens Microsoft's Compliance Over Time template without passing unrelated parameters", () => {
    const link = items.find((item: { name: string }) => item.name === "OpenComplianceOverTime").content.links[0];
    expect(link.linkTarget).to.equal("WorkbookTemplate");
    expect(link.workbookContext.templateId).to.equal("Community-Workbooks/Azure Security Center/Compliance");
    expect(link.workbookContext.componentId).to.equal("Azure Monitor");
    expect(link.workbookContext.passSpecificParams).to.equal(true);
    expect(link.workbookContext.templateParameters).to.deep.equal([]);
  });

  it("attributes history to selected source subscriptions and the workspace, never the destination subscription", () => {
    const query: string = history.content.query;
    expect(query).to.contain("RegulatoryComplianceSubscriptionId");
    expect(query).to.contain("WorkspaceId = tostring(TenantId)");
    expect(query).to.contain("datatable(SourceSubscription:string)[{Subscription:subid}]");
    expect(query).to.contain("join kind=leftouter (RecordedHistory) on SourceSubscription");
    expect(query).not.to.contain("_SubscriptionId");
    expect(query).not.to.contain("isfuzzy=true");
  });

  it("distinguishes no snapshot, stale snapshots, limited history, and absent streaming", () => {
    const query: string = history.content.query;
    expect(query).to.contain("SnapshotRecords == 0, 'No snapshot observed in 90 days'");
    expect(query).to.contain("LatestSnapshot < ago(8d), 'No snapshot in the last 8 days'");
    expect(query).to.contain("LatestSnapshot - FirstSnapshot < 6d, 'Recent snapshot; history still limited'");
    expect(query).to.contain("None observed; changes trigger streaming");
    expect(query).to.contain("UnknownFrequencyRecords = countif(isnull(IsSnapshot))");
    expect(query).not.to.contain("Configuration pass");
  });
});
