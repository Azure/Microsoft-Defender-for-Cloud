"""Unit tests for ``clients.arg_client`` and ``clients.arg_queries`` (§4.3).

All HTTP is mocked with ``respx``; no real ARG/ARM calls are made (§5 testing
expectations). Covers happy path, 429 retry, 5xx retry/exhaustion, auth failure,
timeout, and pagination.
"""

from __future__ import annotations

import asyncio
import json
import time
from types import SimpleNamespace
from typing import Any

import clients.arg_client as arg_mod
import httpx
import pytest
import respx
from clients import arg_queries
from clients.arg_client import ArgClient, ArgClientError

_ARG_HOST = "management.azure.com"
_ARG_PATH = "/providers/Microsoft.ResourceGraph/resources"


class _FakeCredential:
    """Async credential test double mirroring ``AsyncTokenCredential`` (§7)."""

    def __init__(
        self,
        *,
        token: str = "fake-token",
        expires_in: float = 3600.0,
        error: Exception | None = None,
    ) -> None:
        self._token = token
        self._expires_on = int(time.time() + expires_in)
        self._error = error
        self.call_count = 0

    async def get_token(self, *scopes: str, **kwargs: Any) -> SimpleNamespace:
        self.call_count += 1
        if self._error is not None:
            raise self._error
        return SimpleNamespace(token=self._token, expires_on=self._expires_on)

    async def close(self) -> None:  # pragma: no cover - parity with real credential
        return None


def _route(respx_mock: respx.MockRouter) -> respx.Route:
    return respx_mock.route(method="POST", host=_ARG_HOST, path=_ARG_PATH)


# --------------------------------------------------------------------------- #
# ArgClient
# --------------------------------------------------------------------------- #


async def test_query_happy_path() -> None:
    """A single 200 response yields the data rows and sends a well-formed body."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(
            return_value=httpx.Response(200, json={"data": [{"id": "r1"}, {"id": "r2"}]})
        )
        async with ArgClient(credential=cred) as client:
            rows = await client.query("resources", ["sub1", "sub2"])

    assert rows == [{"id": "r1"}, {"id": "r2"}]
    assert route.call_count == 1
    request = route.calls.last.request
    body = json.loads(request.content)
    assert body["subscriptions"] == ["sub1", "sub2"]
    assert body["query"] == "resources"
    assert body["options"]["resultFormat"] == "objectArray"
    assert request.headers["Authorization"] == "Bearer fake-token"
    assert "api-version=2022-10-01" in str(request.url)


async def test_query_caches_token_across_pages() -> None:
    """Pagination follows ``$skipToken`` and reuses the cached token (§5.2)."""
    cred = _FakeCredential()
    with respx.mock:
        _route(respx.mock).mock(
            side_effect=[
                httpx.Response(200, json={"data": [{"id": "r1"}], "$skipToken": "tok"}),
                httpx.Response(200, json={"data": [{"id": "r2"}]}),
            ]
        )
        async with ArgClient(credential=cred) as client:
            rows = await client.query("resources", ["sub1"])

    assert rows == [{"id": "r1"}, {"id": "r2"}]
    assert cred.call_count == 1  # token acquired once, reused for page 2


async def test_query_retries_on_429_then_succeeds() -> None:
    """A 429 is retried (tenacity) and the subsequent 200 wins (§4.3)."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(
            side_effect=[
                httpx.Response(429),
                httpx.Response(200, json={"data": [{"id": "r1"}]}),
            ]
        )
        async with ArgClient(credential=cred) as client:
            rows = await client.query("resources", ["sub1"])

    assert rows == [{"id": "r1"}]
    assert route.call_count == 2


async def test_query_retries_on_5xx_then_succeeds() -> None:
    """A 503 is retried and the subsequent 200 wins (§4.3)."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(
            side_effect=[
                httpx.Response(503),
                httpx.Response(200, json={"data": []}),
            ]
        )
        async with ArgClient(credential=cred) as client:
            rows = await client.query("resources", ["sub1"])

    assert rows == []
    assert route.call_count == 2


async def test_query_raises_after_retries_exhausted() -> None:
    """Persistent 5xx exhausts the 3 attempts and surfaces ArgClientError (§4.3)."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(return_value=httpx.Response(500))
        async with ArgClient(credential=cred) as client:
            with pytest.raises(ArgClientError):
                await client.query("resources", ["sub1"])

    assert route.call_count == 3


async def test_query_4xx_is_not_retried() -> None:
    """A non-throttle 4xx fails fast (no retry) as ArgClientError (§4.3)."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(return_value=httpx.Response(400, text="bad query"))
        async with ArgClient(credential=cred) as client:
            with pytest.raises(ArgClientError):
                await client.query("resources", ["sub1"])

    assert route.call_count == 1


async def test_query_auth_failure_raises() -> None:
    """A credential error is wrapped as ArgClientError before any HTTP call (§7)."""
    cred = _FakeCredential(error=RuntimeError("no managed identity"))
    with respx.mock:
        route = _route(respx.mock).mock(return_value=httpx.Response(200, json={"data": []}))
        async with ArgClient(credential=cred) as client:
            with pytest.raises(ArgClientError):
                await client.query("resources", ["sub1"])

    assert route.call_count == 0


async def test_query_timeout_is_retried_then_raises() -> None:
    """A read timeout is retried and finally surfaces as ArgClientError (§4.3, §6)."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(side_effect=httpx.ReadTimeout("read timed out"))
        async with ArgClient(credential=cred) as client:
            with pytest.raises(ArgClientError):
                await client.query("resources", ["sub1"])

    assert route.call_count == 3


async def test_query_transport_error_is_retried_then_raises() -> None:
    """A non-timeout transport error is retried then surfaces as ArgClientError."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(side_effect=httpx.ConnectError("refused"))
        async with ArgClient(credential=cred) as client:
            with pytest.raises(ArgClientError):
                await client.query("resources", ["sub1"])

    assert route.call_count == 3


async def test_throttle_sleeps_when_window_is_full(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """A full sliding window blocks the next query until it drains (§4.3)."""
    slept: list[float] = []

    async def _instant_sleep(seconds: float) -> None:
        slept.append(seconds)

    monkeypatch.setattr(arg_mod.asyncio, "sleep", _instant_sleep)
    client = ArgClient(credential=_FakeCredential())
    now = asyncio.get_running_loop().time()
    # Fill the window with fresh timestamps so the next call must wait.
    client._throttle_times.extend([now] * arg_mod._THROTTLE_MAX_QUERIES)

    await client._throttle()

    assert slept
    assert slept[0] > 0


async def test_throttle_purges_stale_timestamps() -> None:
    """Timestamps older than the window are dropped before admitting a query (§4.3)."""
    client = ArgClient(credential=_FakeCredential())
    now = asyncio.get_running_loop().time()
    stale = now - arg_mod._THROTTLE_WINDOW_SECONDS - 1.0
    client._throttle_times.extend([stale, stale, stale])

    await client._throttle()

    # The three stale entries were purged; only the fresh admission remains.
    assert len(client._throttle_times) == 1


async def test_query_requires_context_manager() -> None:
    """Calling query() without entering the context manager raises (§4.3)."""
    client = ArgClient(credential=_FakeCredential())
    with pytest.raises(ArgClientError):
        await client.query("resources", ["sub1"])


async def test_query_requires_subscriptions() -> None:
    """An empty subscription list is rejected before any HTTP call (§4.3)."""
    cred = _FakeCredential()
    async with ArgClient(credential=cred) as client:
        with pytest.raises(ArgClientError):
            await client.query("resources", [])


# --------------------------------------------------------------------------- #
# arg_queries
# --------------------------------------------------------------------------- #


def test_escape_kql_string_escapes_quotes_and_backslashes() -> None:
    assert arg_queries.escape_kql_string("a'b\\c") == "a\\'b\\\\c"


@pytest.mark.parametrize(
    ("builder", "table"),
    [
        (arg_queries.other_open_recommendations, "securityresources"),
        (arg_queries.governance_assignments, "securityresources"),
        (arg_queries.attack_paths_for_resource, "securityresources"),
        (arg_queries.vulnerability_subassessments, "securityresources"),
        (arg_queries.resource_details, "resources"),
    ],
)
def test_query_builders_target_expected_table(builder: Any, table: str) -> None:
    kql = builder("/subscriptions/s/resourceGroups/rg/providers/x/y/z")
    assert kql.startswith(table)
    assert "z" in kql  # resource id embedded


def test_query_builder_escapes_injection_attempt() -> None:
    kql = arg_queries.other_open_recommendations("rid' | project hacked=1 //")
    assert "rid\\' | project hacked=1 //" in kql


def test_other_recs_query_coalesces_pascalcase_resource_id() -> None:
    """Assessments store the id PascalCase; the filter must coalesce the casings."""
    kql = arg_queries.other_open_recommendations("/subscriptions/s/x/y/z")
    assert "properties.resourceDetails.Id" in kql
    assert "properties.resourceDetails.ResourceId" in kql
    assert "_rid =~" in kql
    assert "properties.status.code =~ 'Unhealthy'" in kql


def test_governance_query_matches_assigned_resource_id() -> None:
    """Governance assignments have no resourceDetails; match on assignedResourceId."""
    kql = arg_queries.governance_assignments("/subscriptions/s/x/y/z")
    assert "properties.assignedResourceId" in kql
    assert "_arid startswith" in kql
    assert "split(_arid, '/assessments/')[1]" in kql
    assert "resourceDetails" not in kql


def test_vulnerability_query_targets_cve_findings() -> None:
    """Subassessments use lowercase id; only true CVE findings are selected."""
    kql = arg_queries.vulnerability_subassessments("/subscriptions/s/x/y/z")
    assert "properties.resourceDetails.id" in kql
    assert "_cve startswith 'CVE-'" in kql
    assert "ServerVulnerabilityAssessment" in kql


def test_attack_path_query_matches_via_graph_entity_resource_id() -> None:
    """Attack paths are matched by the graph entity's ARM id, not internal entity ids."""
    kql = arg_queries.attack_paths_for_resource("/subscriptions/s/x/y/z")
    assert "microsoft.security/attackpaths" in kql
    assert "mv-expand entity = properties.graphComponent.entities" in kql
    assert "entity.entityIdentifiers.azureResourceId" in kql
    assert "_erid =~" in kql
    assert "riskFactors = properties.riskFactors" in kql


def test_union_queries_wraps_multiple_fragments() -> None:
    combined = arg_queries.union_queries("resources | take 1", "securityresources | take 1")
    # ARG-valid form: first fragment is the unwrapped head, rest are parenthesized.
    assert combined.startswith("resources | take 1")
    assert "| union" in combined
    assert "(\nsecurityresources | take 1\n)" in combined
    assert "(\nresources | take 1\n)" not in combined


def test_union_queries_single_fragment_is_passthrough() -> None:
    assert arg_queries.union_queries("resources | take 1") == "resources | take 1"


def test_union_queries_requires_a_fragment() -> None:
    with pytest.raises(ValueError):
        arg_queries.union_queries()
