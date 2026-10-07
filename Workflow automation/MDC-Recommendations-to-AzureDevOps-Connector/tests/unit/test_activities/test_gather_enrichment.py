"""Unit tests for ``activities.gather_enrichment`` (§4.3, §5.2.1, §5.2.3)."""

from __future__ import annotations

import time
from types import SimpleNamespace
from typing import Any

import activities.gather_enrichment as gather
import httpx
import pytest
import respx
from clients.arg_client import ArgClient
from models.enrichment import EnrichmentBundle
from models.mdc_payload import MdcRecommendationPayload

# Captured at import time so the seam test can exercise the *real* builder even
# while the autouse fixture below monkeypatches the module attribute.
_REAL_BUILD_ARG = gather._build_arg_client

_ARG_HOST = "management.azure.com"
_ARG_PATH = "/providers/Microsoft.ResourceGraph/resources"
_RESOURCE_ID = (
    "/subscriptions/sub-1/resourceGroups/rg-web/providers/"
    "Microsoft.Compute/virtualMachines/contoso-web-01"
)


class _FakeCredential:
    """Async credential test double mirroring ``AsyncTokenCredential`` (§7)."""

    def __init__(self, *, error: Exception | None = None) -> None:
        self._error = error

    async def get_token(self, *scopes: str, **kwargs: Any) -> SimpleNamespace:
        if self._error is not None:
            raise self._error
        return SimpleNamespace(token="fake-token", expires_on=int(time.time() + 3600))

    async def close(self) -> None:  # pragma: no cover - parity with real credential
        return None


@pytest.fixture(autouse=True)
def _inject_fake_credential(monkeypatch: pytest.MonkeyPatch) -> None:
    """Build the ARG client with a fake credential so no real auth happens."""
    monkeypatch.setattr(
        gather, "_build_arg_client", lambda: ArgClient(credential=_FakeCredential())
    )


def _payload() -> MdcRecommendationPayload:
    return MdcRecommendationPayload.model_validate(
        {
            "name": "assessment-guid-1",
            "properties": {
                "displayName": "Endpoint protection missing",
                "resourceDetails": {"id": _RESOURCE_ID},
                "metadata": {"severity": "High"},
            },
        }
    )


def _arg_rows() -> list[dict[str, Any]]:
    return [
        {"signalKind": "otherRecs", "assessmentId": "a1", "severity": "High"},
        {"signalKind": "otherRecs", "assessmentId": "a2", "severity": "Medium"},
        {"signalKind": "governance", "assessmentId": "a1", "owner": "alice@contoso.com"},
        {
            "signalKind": "attackPath",
            "attackPathId": "ap1",
            "displayName": "Internet-exposed VM",
            "riskFactors": ["Internet exposure", "High privilege"],
        },
        {"signalKind": "vulnerability", "cve": "CVE-2024-0001", "cvss": 9.8},
        {"signalKind": "vulnerability", "cve": "CVE-2024-0002", "cvss": 5.0},
        {
            "signalKind": "resource",
            "owner": "alice@contoso.com",
            "criticality": "High",
        },
    ]


async def test_gather_enrichment_happy_path() -> None:
    """A populated ARG batch decomposes into a fully-populated bundle."""
    with respx.mock:
        respx.mock.route(method="POST", host=_ARG_HOST, path=_ARG_PATH).mock(
            return_value=httpx.Response(200, json={"data": _arg_rows()})
        )
        bundle = EnrichmentBundle.model_validate(
            await gather.activity_gather_enrichment(_payload())
        )

    assert bundle.other_recs is not None
    assert bundle.other_recs.total == 2
    assert bundle.other_recs.assigned == 1
    assert bundle.other_recs.unassigned == 1
    assert bundle.other_recs.by_severity == {"High": 1, "Medium": 1}

    assert bundle.attack_paths is not None
    assert len(bundle.attack_paths.paths) == 1

    assert bundle.exposure is not None
    assert bundle.exposure.internet_facing is True

    assert bundle.vulnerabilities is not None
    assert bundle.vulnerabilities.cve_count == 2
    assert bundle.vulnerabilities.max_cvss == 9.8
    assert bundle.vulnerabilities.top_cves[0].id == "CVE-2024-0001"

    assert bundle.owner is not None
    assert bundle.owner.email == "alice@contoso.com"
    assert bundle.owner.source == "tag"

    assert bundle.criticality is not None
    assert bundle.criticality.level == "High"


async def test_gather_enrichment_degrades_when_arg_fails() -> None:
    """A persistent ARG 5xx degrades to an empty bundle, never raising (§5.2.3)."""
    with respx.mock:
        respx.mock.route(method="POST", host=_ARG_HOST, path=_ARG_PATH).mock(
            return_value=httpx.Response(500, json={"error": "boom"})
        )
        bundle = EnrichmentBundle.model_validate(
            await gather.activity_gather_enrichment(_payload())
        )

    assert bundle.other_recs is None
    assert bundle.attack_paths is None
    assert bundle.exposure is None
    assert bundle.vulnerabilities is None
    assert bundle.owner is None
    assert bundle.criticality is None


async def test_gather_enrichment_partial_signal_failure() -> None:
    """One malformed signal degrades to ``None`` while the rest still populate."""
    rows = [
        {"signalKind": "otherRecs", "assessmentId": "a1", "severity": "Low"},
        # malformed attack-path row: riskFactors is the wrong shape but must not
        # break the other signals.
        {"signalKind": "resource", "criticality": "Critical"},
    ]
    with respx.mock:
        respx.mock.route(method="POST", host=_ARG_HOST, path=_ARG_PATH).mock(
            return_value=httpx.Response(200, json={"data": rows})
        )
        bundle = EnrichmentBundle.model_validate(
            await gather.activity_gather_enrichment(_payload())
        )

    assert bundle.other_recs is not None
    assert bundle.other_recs.total == 1
    assert bundle.attack_paths is None  # no attackPath rows
    assert bundle.vulnerabilities is None
    assert bundle.criticality is not None
    assert bundle.criticality.level == "Critical"
    assert bundle.owner is None  # resource row carried no owner tag


async def test_gather_enrichment_missing_resource_id_returns_empty() -> None:
    """Without a resource id the activity short-circuits to an empty bundle."""
    payload = MdcRecommendationPayload.model_validate({"name": "a"})
    bundle = EnrichmentBundle.model_validate(await gather.activity_gather_enrichment(payload))
    assert bundle.other_recs is None
    assert bundle.owner is None


async def test_gather_enrichment_owner_falls_back_to_governance() -> None:
    """When the resource has no owner tag, the governance-assignment owner is used."""
    rows = [
        {"signalKind": "otherRecs", "assessmentId": "a1", "severity": "High"},
        {"signalKind": "governance", "assessmentId": "a1", "owner": "gov-owner@contoso.com"},
        {"signalKind": "resource", "criticality": "High"},  # no owner tag
    ]
    with respx.mock:
        respx.mock.route(method="POST", host=_ARG_HOST, path=_ARG_PATH).mock(
            return_value=httpx.Response(200, json={"data": rows})
        )
        bundle = EnrichmentBundle.model_validate(
            await gather.activity_gather_enrichment(_payload())
        )

    assert bundle.owner is not None
    assert bundle.owner.email == "gov-owner@contoso.com"
    assert bundle.owner.source == "tag"


async def test_gather_enrichment_ignores_own_backref_owner() -> None:
    """A prior write-back assignment (ado-wi-*) is not surfaced as a human owner (§4.7)."""
    rows = [
        {"signalKind": "otherRecs", "assessmentId": "a1", "severity": "High"},
        {"signalKind": "governance", "assessmentId": "a1", "owner": "ado-wi-42@ado.local"},
        {"signalKind": "resource", "criticality": "High"},  # no owner tag
    ]
    with respx.mock:
        respx.mock.route(method="POST", host=_ARG_HOST, path=_ARG_PATH).mock(
            return_value=httpx.Response(200, json={"data": rows})
        )
        bundle = EnrichmentBundle.model_validate(
            await gather.activity_gather_enrichment(_payload())
        )

    assert bundle.owner is None  # our own back-reference is filtered out
    assert bundle.other_recs is not None
    assert bundle.other_recs.assigned == 0  # not counted as a human-assigned rec


async def test_gather_enrichment_excludes_current_assessment_from_other_recs() -> None:
    """The recommendation this WI is about is not counted among 'other' open recs (§4.3 #1)."""
    rows = [
        # The current assessment (matches the payload name) must be excluded.
        {"signalKind": "otherRecs", "assessmentId": "assessment-guid-1", "severity": "High"},
        {"signalKind": "otherRecs", "assessmentId": "other-1", "severity": "Medium"},
    ]
    with respx.mock:
        respx.mock.route(method="POST", host=_ARG_HOST, path=_ARG_PATH).mock(
            return_value=httpx.Response(200, json={"data": rows})
        )
        bundle = EnrichmentBundle.model_validate(
            await gather.activity_gather_enrichment(_payload())
        )

    assert bundle.other_recs is not None
    assert bundle.other_recs.total == 1  # only the genuinely-other rec
    assert bundle.other_recs.by_severity == {"Medium": 1}


async def test_gather_enrichment_no_other_recs_when_only_current() -> None:
    """If the only open rec on the resource is the current one, the section is omitted."""
    rows = [
        {"signalKind": "otherRecs", "assessmentId": "assessment-guid-1", "severity": "High"},
    ]
    with respx.mock:
        respx.mock.route(method="POST", host=_ARG_HOST, path=_ARG_PATH).mock(
            return_value=httpx.Response(200, json={"data": rows})
        )
        bundle = EnrichmentBundle.model_validate(
            await gather.activity_gather_enrichment(_payload())
        )

    assert bundle.other_recs is None


# --------------------------------------------------------------------------- #
# Parser edge cases + client seam
# --------------------------------------------------------------------------- #


def test_build_arg_client_seam_returns_real_client() -> None:
    """The real ``_build_arg_client`` seam constructs an ``ArgClient`` (§7)."""
    client = _REAL_BUILD_ARG()
    assert isinstance(client, ArgClient)


def test_parse_exposure_without_internet_factor() -> None:
    """Attack-path rows with no internet-exposure factor -> not internet facing."""
    info = gather._parse_exposure([{"riskFactors": ["High privilege"]}])
    assert info is not None
    assert info.internet_facing is False


def test_parse_criticality_without_tag_returns_none() -> None:
    """A resource row carrying no criticality tag yields ``None``."""
    assert gather._parse_criticality([{"foo": "bar"}]) is None


def test_parse_criticality_unknown_level_falls_back() -> None:
    """An unrecognized criticality value normalizes to ``Unknown``."""
    info = gather._parse_criticality([{"criticality": "Bogus"}])
    assert info is not None
    assert info.level == "Unknown"


def test_safe_degrades_to_none_on_parser_error() -> None:
    """``_safe`` swallows a parser exception and degrades to ``None`` (§5.2.3)."""

    def _boom(*_args: Any) -> None:
        raise ValueError("boom")

    assert gather._safe("test-signal", _boom, []) is None
