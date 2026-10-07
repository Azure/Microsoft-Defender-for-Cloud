"""§4.3/§4.4 — tests for the MDC payload model and its id/severity helpers."""

from __future__ import annotations

import json
from pathlib import Path

import pytest
from models.mdc_payload import MdcRecommendationPayload

_FIXTURES = Path(__file__).resolve().parents[2] / "fixtures" / "sample_payloads"
_SUBSCRIPTION = "00000000-0000-0000-0000-000000000000"


def _load(name: str) -> dict[str, object]:
    return json.loads((_FIXTURES / name).read_text(encoding="utf-8"))


@pytest.mark.parametrize("name", sorted(p.name for p in _FIXTURES.glob("*.json")))
def test_every_fixture_parses(name: str) -> None:
    payload = MdcRecommendationPayload.model_validate(_load(name))
    assert payload.resource_id is not None
    assert payload.subscription_id == _SUBSCRIPTION


def test_vm_high_helpers() -> None:
    payload = MdcRecommendationPayload.model_validate(_load("vm_endpoint_protection_high.json"))
    assert payload.severity == "High"
    assert payload.resource_group == "rg-web-prod"
    assert payload.resource_type == "Microsoft.Compute/virtualMachines"
    assert payload.resource_name == "contoso-web-01"
    assert payload.display_name == "Endpoint protection should be installed on your machines"
    assert payload.metadata is not None
    assert payload.metadata.assessment_type == "BuiltIn"


def test_storage_medium_helpers() -> None:
    payload = MdcRecommendationPayload.model_validate(_load("storage_secure_transfer_medium.json"))
    assert payload.severity == "Medium"
    assert payload.resource_type == "Microsoft.Storage/storageAccounts"
    assert payload.resource_name == "contosodatalake"


def test_minimal_low_defaults() -> None:
    payload = MdcRecommendationPayload.model_validate(_load("sql_db_minimal_low.json"))
    # No metadata block -> severity defaults to Low.
    assert payload.severity == "Low"
    assert payload.metadata is None
    # Nested provider/type parses across the servers/databases segments.
    assert payload.resource_type == "Microsoft.Sql/servers/databases"
    assert payload.resource_name == "orders"


def test_empty_payload_helpers_are_safe() -> None:
    payload = MdcRecommendationPayload()
    assert payload.resource_id is None
    assert payload.subscription_id is None
    assert payload.resource_group is None
    assert payload.resource_type is None
    assert payload.resource_name is None
    assert payload.severity == "Low"
    assert payload.recommendation_url is None
    assert payload.resource_portal_url is None


def test_recommendation_url_prefers_payload_links() -> None:
    """The portal link supplied on the payload is used verbatim (https-normalized)."""
    with_uri = MdcRecommendationPayload.model_validate(
        {"name": "a", "properties": {"links": {"azurePortalUri": "https://portal.azure.com/#rec"}}}
    )
    assert with_uri.recommendation_url == "https://portal.azure.com/#rec"

    # ARG-style azurePortal without scheme is normalized to https.
    arg_style = MdcRecommendationPayload.model_validate(
        {"name": "a", "properties": {"links": {"azurePortal": "portal.azure.com/#rec"}}}
    )
    assert arg_style.recommendation_url == "https://portal.azure.com/#rec"


def test_assessment_resource_id_prefers_canonical_construction() -> None:
    """The assessment id is built from resource_id+name, ignoring a mis-scoped payload id."""
    payload = MdcRecommendationPayload.model_validate(
        {
            # A mis-scoped (RG-scoped) payload id that omits the resource segment.
            "id": "/subscriptions/s/resourceGroups/rg/providers/Microsoft.Security/assessments/k",
            "name": "k",
            "properties": {
                "resourceDetails": {"id": "/subscriptions/s/resourceGroups/rg/providers/p/t/vm1"}
            },
        }
    )
    assert payload.assessment_resource_id == (
        "/subscriptions/s/resourceGroups/rg/providers/p/t/vm1"
        "/providers/Microsoft.Security/assessments/k"
    )


def test_assessment_resource_id_falls_back_to_payload_id() -> None:
    """When resource id/name are unavailable, the payload assessment id is used."""
    payload = MdcRecommendationPayload.model_validate(
        {"id": "/subscriptions/s/providers/Microsoft.Security/assessments/k"}
    )
    assert payload.assessment_resource_id == (
        "/subscriptions/s/providers/Microsoft.Security/assessments/k"
    )


def test_recommendation_url_constructs_from_key_and_resource_id() -> None:
    """Without a payload link, the Recommendations-blade URL is reconstructed."""
    payload = MdcRecommendationPayload.model_validate(
        {
            "name": "assess-key-1",
            "properties": {
                "resourceDetails": {
                    "id": "/subscriptions/s/resourceGroups/rg/providers/p/t/contoso-vm"
                }
            },
        }
    )
    url = payload.recommendation_url
    assert url is not None
    assert "assessmentKey/assess-key-1" in url
    assert "resourceId/%2Fsubscriptions%2Fs%2F" in url  # resource id URL-encoded
    assert (
        payload.resource_portal_url
        == "https://portal.azure.com/#@/resource/subscriptions/s/resourceGroups/rg/"
        "providers/p/t/contoso-vm/overview"
    )


def test_resource_id_without_known_segments_yields_none() -> None:
    """A resource id lacking subscriptions/resourceGroups/providers -> ``None`` helpers."""
    payload = MdcRecommendationPayload.model_validate(
        {"name": "a", "properties": {"resourceDetails": {"id": "/foo/bar/baz"}}}
    )
    assert payload.resource_id == "/foo/bar/baz"
    assert payload.subscription_id is None
    assert payload.resource_group is None
    assert payload.resource_type is None
    assert payload.resource_name == "baz"


def test_resource_type_requires_namespace_and_type_tokens() -> None:
    """``providers`` followed by only a namespace token -> ``resource_type`` is ``None``."""
    payload = MdcRecommendationPayload.model_validate(
        {
            "name": "a",
            "properties": {"resourceDetails": {"id": "/subscriptions/s/providers/Microsoft.Foo"}},
        }
    )
    assert payload.resource_type is None
