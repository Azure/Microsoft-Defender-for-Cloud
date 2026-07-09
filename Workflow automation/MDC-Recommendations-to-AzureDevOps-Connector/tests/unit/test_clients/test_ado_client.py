"""Unit tests for ``clients.ado_client`` (§4.4, §5.2, §6.1).

All HTTP is mocked with ``respx``; no real ADO calls are made (§5 testing
expectations). Covers happy paths (WIQL/create/update/comment), JSON Patch shape,
429 retry, 5xx retry/exhaustion, 401 -> token-refresh, auth failure, and timeout.
"""

from __future__ import annotations

import json
import time
from datetime import UTC, datetime
from types import SimpleNamespace
from typing import Any

import httpx
import pytest
import respx
from clients.ado_client import AdoClient, AdoClientError
from models.briefing import WorkItemResult

_ADO_HOST = "dev.azure.com"
_ORG_URL = "https://dev.azure.com/contoso"
_PROJECT = "Security"


class _FakeCredential:
    """Async credential test double mirroring ``AsyncTokenCredential`` (§6.1, §7)."""

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


def _client(cred: _FakeCredential | None = None) -> AdoClient:
    return AdoClient(
        organization_url=_ORG_URL,
        project=_PROJECT,
        credential=cred or _FakeCredential(),
    )


def _route(respx_mock: respx.MockRouter, method: str) -> respx.Route:
    return respx_mock.route(method=method, host=_ADO_HOST)


# --------------------------------------------------------------------------- #
# query_wiql
# --------------------------------------------------------------------------- #


async def test_query_wiql_returns_ids() -> None:
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock, "POST").mock(
            return_value=httpx.Response(200, json={"workItems": [{"id": 11}, {"id": 22}]})
        )
        async with _client(cred) as client:
            ids = await client.query_wiql("SELECT [System.Id] FROM WorkItems")

    assert ids == [11, 22]
    request = route.calls.last.request
    assert request.headers["Authorization"] == "Bearer fake-token"
    assert json.loads(request.content)["query"].startswith("SELECT")
    assert "_apis/wit/wiql?api-version=7.1" in str(request.url)


async def test_query_wiql_empty_result() -> None:
    cred = _FakeCredential()
    with respx.mock:
        _route(respx.mock, "POST").mock(return_value=httpx.Response(200, json={}))
        async with _client(cred) as client:
            ids = await client.query_wiql("SELECT [System.Id] FROM WorkItems")

    assert ids == []


# --------------------------------------------------------------------------- #
# create / update / comment
# --------------------------------------------------------------------------- #


async def test_create_work_item_happy_path_and_patch_shape() -> None:
    cred = _FakeCredential()
    fields = {
        "System.WorkItemType": "Security Recommendation",
        "System.Title": "Enable encryption",
        "Custom.MDCAssessmentId": "abc",
        "Microsoft.VSTS.Common.Priority": 1,
        "Microsoft.VSTS.Scheduling.DueDate": datetime(2026, 7, 1, tzinfo=UTC),
    }
    with respx.mock:
        route = _route(respx.mock, "POST").mock(
            return_value=httpx.Response(
                200,
                json={
                    "id": 42,
                    "_links": {"html": {"href": "https://dev.azure.com/contoso/_wi/42"}},
                },
            )
        )
        async with _client(cred) as client:
            result = await client.create_work_item(fields)

    assert isinstance(result, WorkItemResult)
    assert result.id == 42
    assert result.action == "created"
    assert result.url == "https://dev.azure.com/contoso/_wi/42"

    request = route.calls.last.request
    # WIT type goes in the URL, not the patch body.
    assert "/workitems/$Security%20Recommendation?api-version=7.1" in str(request.url)
    assert request.headers["Content-Type"] == "application/json-patch+json"
    patch = json.loads(request.content)
    assert all(op["op"] == "add" for op in patch)
    assert all(op["path"].startswith("/fields/") for op in patch)
    assert {"op": "add", "path": "/fields/System.Title", "value": "Enable encryption"} in patch
    # WorkItemType excluded from the patch.
    assert all(op["path"] != "/fields/System.WorkItemType" for op in patch)
    # datetime serialized to ISO-8601.
    due = next(op for op in patch if op["path"] == "/fields/Microsoft.VSTS.Scheduling.DueDate")
    assert due["value"] == "2026-07-01T00:00:00+00:00"


async def test_create_work_item_defaults_work_item_type() -> None:
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock, "POST").mock(
            return_value=httpx.Response(200, json={"id": 1, "url": "u"})
        )
        async with _client(cred) as client:
            result = await client.create_work_item({"System.Title": "t"})

    assert result.url == "u"  # falls back to data.url when no _links.html
    assert "/workitems/$Security%20Recommendation?" in str(route.calls.last.request.url)


async def test_update_work_item_happy_path() -> None:
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock, "PATCH").mock(
            return_value=httpx.Response(200, json={"id": 7, "url": "https://x/7"})
        )
        async with _client(cred) as client:
            result = await client.update_work_item(7, {"Custom.Severity": "High"})

    assert result.id == 7
    assert result.action == "updated"
    request = route.calls.last.request
    assert "/workitems/7?api-version=7.1" in str(request.url)
    assert request.headers["Content-Type"] == "application/json-patch+json"


async def test_add_comment_posts_text() -> None:
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock, "POST").mock(return_value=httpx.Response(200, json={"id": 1}))
        async with _client(cred) as client:
            result = await client.add_comment(7, "material change")

    assert result is None
    request = route.calls.last.request
    assert "/workItems/7/comments?api-version=7.1-preview.4" in str(request.url)
    assert json.loads(request.content) == {"text": "material change"}


# --------------------------------------------------------------------------- #
# retry / auth / timeout
# --------------------------------------------------------------------------- #


async def test_request_retries_on_429_then_succeeds() -> None:
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock, "POST").mock(
            side_effect=[
                httpx.Response(429),
                httpx.Response(200, json={"workItems": [{"id": 1}]}),
            ]
        )
        async with _client(cred) as client:
            ids = await client.query_wiql("SELECT [System.Id] FROM WorkItems")

    assert ids == [1]
    assert route.call_count == 2


async def test_request_retries_on_5xx_then_raises() -> None:
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock, "POST").mock(return_value=httpx.Response(503))
        async with _client(cred) as client:
            with pytest.raises(AdoClientError):
                await client.query_wiql("SELECT [System.Id] FROM WorkItems")

    assert route.call_count == 3


async def test_request_401_refreshes_token_then_succeeds() -> None:
    """A 401 invalidates the cached token and the retry re-acquires it (§6.1)."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock, "POST").mock(
            side_effect=[
                httpx.Response(401),
                httpx.Response(200, json={"workItems": []}),
            ]
        )
        async with _client(cred) as client:
            ids = await client.query_wiql("SELECT [System.Id] FROM WorkItems")

    assert ids == []
    assert route.call_count == 2
    assert cred.call_count == 2  # token fetched again after the 401


async def test_request_non_retryable_4xx_raises() -> None:
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock, "POST").mock(
            return_value=httpx.Response(400, text="bad request")
        )
        async with _client(cred) as client:
            with pytest.raises(AdoClientError):
                await client.query_wiql("SELECT [System.Id] FROM WorkItems")

    assert route.call_count == 1


async def test_request_auth_failure_raises() -> None:
    cred = _FakeCredential(error=RuntimeError("no managed identity"))
    with respx.mock:
        route = _route(respx.mock, "POST").mock(return_value=httpx.Response(200, json={}))
        async with _client(cred) as client:
            with pytest.raises(AdoClientError):
                await client.query_wiql("SELECT [System.Id] FROM WorkItems")

    assert route.call_count == 0


async def test_request_timeout_is_retried_then_raises() -> None:
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock, "POST").mock(side_effect=httpx.ReadTimeout("read timed out"))
        async with _client(cred) as client:
            with pytest.raises(AdoClientError):
                await client.query_wiql("SELECT [System.Id] FROM WorkItems")

    assert route.call_count == 3


async def test_missing_config_raises_on_enter() -> None:
    client = AdoClient(organization_url="", project="", credential=_FakeCredential())
    with pytest.raises(AdoClientError):
        async with client:
            pass


async def test_request_transport_error_is_retried_then_raises() -> None:
    """A non-timeout transport error is retried then surfaces as AdoClientError."""
    cred = _FakeCredential()
    with respx.mock:
        route = respx.mock.route(host=_ADO_HOST).mock(side_effect=httpx.ConnectError("refused"))
        async with _client(cred) as client:
            with pytest.raises(AdoClientError):
                await client.query_wiql("SELECT [System.Id] FROM WorkItems")

    assert route.call_count == 3
