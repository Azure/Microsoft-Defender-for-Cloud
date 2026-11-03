import { readFileSync } from "fs";
import { join } from "path";
import chai from "chai";

const { expect } = chai;
type Named = { name: string };
const workbook = JSON.parse(readFileSync(join("Workbooks", "Regulatory Compliance", "regulatorycompliance.json"), "utf8"));
const readiness = workbook.items.find((item: Named) => item.name === "ComplianceOverTimeReadiness");
const group = readiness.content.items.find((item: Named) => item.name === "ComplianceHistoryViews");
const item = (name: string) => group.content.items.find((value: Named) => value.name === name).content;
const latest = item("HistoryLatestPosture");
const rate = item("HistoryWeeklyPassRate");
const coverage = item("HistoryWeeklyCoverage");
const changes = item("HistoryControlChanges");
const parameter = item("HistoryStandardParameters").parameters[0];
const enabled = { parameterName: "CheckHistory", comparison: "isEqualTo", value: "On" };

function rank(state: string, recommendation = "recommendation"): number {
  const normalized = state.toLowerCase();
  if (normalized === "failed") return 6;
  if (!recommendation) return 5;
  return ({ passed: 4, skipped: 3, notapplicable: 2, "not applicable": 2, unsupported: 1 } as { [state: string]: number })[normalized] || 5;
}

interface Assessment {
  subscription: string;
  standard: string;
  control: string;
  recommendation: string;
  resource: string;
  time: number;
  state: string;
}

function controlRanks(rows: Assessment[]): Map<string, number> {
  const assessments = new Map<string, Assessment>();
  for (const row of rows) {
    const key = JSON.stringify([row.subscription, row.standard, row.control, row.recommendation, row.resource]);
    const previous = assessments.get(key);
    if (!previous || row.time > previous.time || (row.time === previous.time && rank(row.state) > rank(previous.state))) {
      assessments.set(key, row);
    }
  }
  const controls = new Map<string, number>();
  for (const row of assessments.values()) {
    const key = JSON.stringify([row.subscription, row.standard, row.control]);
    controls.set(key, Math.max(controls.get(key) || 0, rank(row.state, row.recommendation)));
  }
  return controls;
}

describe("Export and compliance history", () => {
  it("keeps all historical panels opt-in and separates the technical tab key from the display label", () => {
    expect(group.conditionalVisibility).to.deep.equal(enabled);
    for (const panel of group.content.items.filter((value: { type: number }) => value.type === 3)) {
      expect(panel.conditionalVisibility).to.deep.equal(enabled);
      expect(panel.content.crossComponentResources).to.deep.equal(["{HistoryWorkspace}"]);
      expect(panel.content.timeContext.durationMs).to.equal(90 * 24 * 60 * 60 * 1000);
    }
    const links = workbook.items.find((value: { type: number }) => value.type === 11).content.links;
    expect(links.find((value: { subTarget: string }) => value.subTarget === "Readiness").linkLabel)
      .to.equal("Export & compliance history");
  });

  it("discovers historical standards independently of current ARG standards and its own selection", () => {
    expect(parameter.query).to.contain("SecurityRegulatoryCompliance");
    expect(parameter.query).to.contain("RegulatoryComplianceSubscriptionId");
    expect(parameter.query).not.to.contain("{HistoryStandard");
    expect(parameter.query).not.to.contain("{Control");
    expect(parameter.queryType).to.equal(0);
    expect(parameter.crossComponentResources).to.deep.equal(["{HistoryWorkspace}"]);
    expect(parameter.value).to.equal("value::all");
    expect(parameter.typeSettings.selectAllValue).to.equal("*");
  });

  it("shares the same snapshot, identity, scope, and denominator definitions in all new panels", () => {
    const base = (query: string) => query.split("\r\nlet LatestDays =")[0].split("\r\nlet WeeklyPosture =")[0];
    for (const panel of [rate, coverage, changes]) expect(base(panel.query)).to.equal(base(latest.query));
    for (const panel of [latest, rate, coverage, changes]) {
      expect(panel.query).to.contain("datatable(SourceSubscription:string)[{Subscription:subid}]");
      expect(panel.query).to.contain("\"{HistoryStandard:escapejson}\" == '*'");
      expect(panel.query).to.contain("| where IsSnapshot == true and isnotempty(Standard)");
      expect(panel.query).not.to.contain("_SubscriptionId");
      expect(panel.query).not.to.contain("isfuzzy=true");
    }
  });

  it("deduplicates within source, standard, control, recommendation, resource, and snapshot day", () => {
    expect(latest.query).to.contain("arg_max(TimeGenerated, StateRank) by SourceSubscription, Standard, SnapshotDay, ControlId, RecommendationId, AssessedResourceId");
    expect(latest.query).to.contain("StateRank = max(StateRank)");
    expect(latest.query).to.contain("State =~ 'Failed', 6, isempty(RecommendationId), 5");
    expect(latest.query).to.contain("Assessed > 0 and IncompleteRecords == 0");
    const row: Assessment = { subscription: "a", standard: "one", control: "c", recommendation: "r", resource: "x", time: 1, state: "Failed" };
    expect(Array.from(controlRanks([row, { ...row, time: 2, state: "Passed" }]).values())).to.deep.equal([4]);
    expect(Array.from(controlRanks([row, { ...row, state: "Passed" }]).values())).to.deep.equal([6]);
    expect(Array.from(controlRanks([{ ...row, state: "Passed" }, { ...row, resource: "y", state: "Unknown" }]).values())).to.deep.equal([5]);
    expect(controlRanks([row, { ...row, subscription: "b" }, { ...row, standard: "two" }]).size).to.equal(3);
  });

  it("does not turn unsupported, skipped, missing, or unknown states into an assessed pass", () => {
    expect(rank("Skipped")).to.equal(3);
    expect(rank("Unsupported")).to.equal(1);
    expect(rank("NotApplicable")).to.equal(2);
    expect(rank("unexpected")).to.equal(5);
    expect(rank("Passed", "")).to.equal(5);
    expect(rank("Failed", "")).to.equal(6);
    expect(latest.query).to.contain("Other = countif(ControlState !in ('Passed', 'Failed'))");
    expect(latest.query).to.contain("real(null)");
  });

  it("compares actual previous snapshot days using only controls assessed in both", () => {
    expect(latest.query).to.contain("PreviousDay = maxif(SnapshotDay, SnapshotDay < LatestDay)");
    expect(latest.query).to.contain("CurrentState in ('Passed', 'Failed') and PreviousState in ('Passed', 'Failed')");
    expect(latest.query).to.contain("MatchedControls > 0 and IncompleteRecords == 0 and PreviousIncomplete == 0");
    expect(latest.query).to.contain("100.0 * PassedDifference / MatchedControls");
    for (const panel of [latest, changes]) {
      expect(panel.query).to.contain("PreviousDay = format_datetime(PreviousDay, 'yyyy-MM-dd')");
      expect(panel.query).to.contain("LatestDay = format_datetime(LatestDay, 'yyyy-MM-dd')");
    }
    expect(latest.query).not.to.contain("ago(7d)");
  });

  it("plots observed weekly points only without zero-filling missing data or connecting gaps", () => {
    expect(rate.query).to.contain("arg_max(SnapshotDay, *) by SourceSubscription, Standard, Week");
    expect(rate.query).to.contain("range Week from startofweek(ago(90d))");
    expect(rate.query).to.contain("join kind=leftouter (WeeklyPosture)");
    expect(coverage.query).to.contain("iff(isnotnull(SnapshotDay), Assessed, long(null))");
    expect(rate.query).to.contain("where isnotnull(PassPercent)");
    expect(coverage.query).to.contain("where isnotnull(AssessedControls)");
    expect(rate.visualization).to.equal("scatterchart");
    expect(coverage.visualization).to.equal("scatterchart");
    expect(rate.chartSettings.ySettings).to.deep.equal({ min: 0, max: 100 });
    expect(rate.chartSettings.showMetrics).to.equal(false);
    expect(coverage.chartSettings.ySettings.min).to.equal(0);
    expect(rate.query).not.to.contain("series_fill");
  });

  it("reports additions and missing controls as observations, not automatic remediation", () => {
    expect(changes.query).to.contain("kind=fullouter");
    expect(changes.query).to.contain("Newly observed control");
    expect(changes.query).to.contain("Not observed in latest snapshot");
    expect(changes.query).to.contain("PreviousState == 'Failed' and CurrentState == 'Passed', 'Recovered to passed'");
    expect(changes.query).to.contain("where Change != 'Unchanged'");
    expect(changes.noDataMessage).to.contain("not proof of no change");
    expect(changes.showExportToExcel).to.equal(true);
  });

  it("keeps delivery evidence across all standards and exposes incomplete identifiers", () => {
    const delivery = readiness.content.items.find((value: Named) => value.name === "ReadinessHistory").content;
    expect(delivery.query).not.to.contain("{HistoryStandard");
    expect(delivery.query).to.contain("IncompleteSnapshotRecords = countif");
    expect(delivery.query).to.contain("isempty(ComplianceStandard) or isempty(ComplianceControl) or isempty(RecommendationId)");
    expect(latest.query).to.contain("Stale snapshot; review delivery");
    expect(latest.query).to.contain("Incomplete identifiers; results partial");
  });
});
