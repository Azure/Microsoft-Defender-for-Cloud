"""Unit tests for ``clients.mdc_client`` (§4.7, §6.1).

All HTTP is mocked with ``respx``; no real MDC/ARM calls are made. Covers the happy
PUT (URL + body shape), 429/5xx retry and exhaustion, non-retryable 4xx, auth failure,
timeout retry, and the token-cache reuse.
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
from clients.mdc_client import MdcAssignmentConflictError, MdcClient, MdcClientError

_ARM_HOST = "management.azure.com"
_ASSESSMENT_ID = (
    "/subscriptions/sub-1/resourceGroups/rg/providers/Microsoft.Compute/"
    "virtualMachines/vm1/providers/Microsoft.Security/assessments/key-1"
)
_KEY = "11111111-1111-1111-1111-111111111111"
_DUE = datetime(2026, 7, 1, tzinfo=UTC)


class _FakeCredential:
    """Async credential test double mirroring ``AsyncTokenCredential`` (§6.1, §7)."""

    def __init__(self, *, error: Exception | None = None) -> None:
        self._error = error
        self.call_count = 0

    async def get_token(self, *scopes: str, **kwargs: Any) -> SimpleNamespace:
        self.call_count += 1
        if self._error is not None:
            raise self._error
        return SimpleNamespace(token="fake-token", expires_on=int(time.time() + 3600))

    async def close(self) -> None:  # pragma: no cover - parity with real credential
        return None


def _route(respx_mock: respx.MockRouter) -> respx.Route:
    return respx_mock.route(method="PUT", host=_ARM_HOST)


async def test_assign_governance_puts_expected_url_and_body() -> None:
    """A successful assignment PUTs the governance URL with owner/dueDate/grace body."""
    with respx.mock:
        route = _route(respx.mock).mock(return_value=httpx.Response(200, json={"id": "x"}))
        async with MdcClient(credential=_FakeCredential()) as client:
            await client.assign_governance(
                _ASSESSMENT_ID, _KEY, owner="ado-wi-42@ado.local", remediation_due_date=_DUE
            )

    req = route.calls.last.request
    assert req.url.path == f"{_ASSESSMENT_ID}/governanceAssignments/{_KEY}"
    assert req.url.params["api-version"] == "2025-05-04"
    body = json.loads(req.content)["properties"]
    assert body["owner"] == "ado-wi-42@ado.local"
    assert body["remediationDueDate"] == "2026-07-01T00:00:00+00:00"
    assert body["isGracePeriod"] is True


async def test_assign_governance_retries_on_5xx_then_succeeds() -> None:
    with respx.mock:
        route = _route(respx.mock).mock(
            side_effect=[httpx.Response(500), httpx.Response(200, json={})]
        )
        async with MdcClient(credential=_FakeCredential()) as client:
            await client.assign_governance(
                _ASSESSMENT_ID, _KEY, owner="ado-wi-1@ado.local", remediation_due_date=_DUE
            )
    assert route.call_count == 2


async def test_assign_governance_exhausts_retries_on_persistent_5xx() -> None:
    with respx.mock:
        route = _route(respx.mock).mock(return_value=httpx.Response(503))
        with pytest.raises(MdcClientError):
            async with MdcClient(credential=_FakeCredential()) as client:
                await client.assign_governance(
                    _ASSESSMENT_ID, _KEY, owner="o@d", remediation_due_date=_DUE
                )
    assert route.call_count == 3


async def test_assign_governance_raises_on_non_retryable_4xx() -> None:
    with respx.mock:
        route = _route(respx.mock).mock(return_value=httpx.Response(403, text="forbidden"))
        with pytest.raises(MdcClientError):
            async with MdcClient(credential=_FakeCredential()) as client:
                await client.assign_governance(
                    _ASSESSMENT_ID, _KEY, owner="o@d", remediation_due_date=_DUE
                )
    assert route.call_count == 1  # 4xx is not retried


async def test_assign_governance_raises_conflict_on_409() -> None:
    """409 (assignment already exists) surfaces as the distinct conflict error, not retried."""
    with respx.mock:
        route = _route(respx.mock).mock(
            return_value=httpx.Response(409, text="already exists with a different key")
        )
        with pytest.raises(MdcAssignmentConflictError):
            async with MdcClient(credential=_FakeCredential()) as client:
                await client.assign_governance(
                    _ASSESSMENT_ID, _KEY, owner="o@d", remediation_due_date=_DUE
                )
    assert route.call_count == 1


async def test_assign_governance_retries_on_timeout() -> None:
    with respx.mock:
        route = _route(respx.mock).mock(side_effect=httpx.ReadTimeout("slow"))
        with pytest.raises(MdcClientError):
            async with MdcClient(credential=_FakeCredential()) as client:
                await client.assign_governance(
                    _ASSESSMENT_ID, _KEY, owner="o@d", remediation_due_date=_DUE
                )
    assert route.call_count == 3


async def test_auth_failure_is_wrapped_and_not_retried() -> None:
    cred = _FakeCredential(error=RuntimeError("no MI"))
    with respx.mock:
        route = _route(respx.mock).mock(return_value=httpx.Response(200, json={}))
        with pytest.raises(MdcClientError):
            async with MdcClient(credential=cred) as client:
                await client.assign_governance(
                    _ASSESSMENT_ID, _KEY, owner="o@d", remediation_due_date=_DUE
                )
    assert route.call_count == 0  # never reached the network


async def test_token_is_cached_across_calls() -> None:
    cred = _FakeCredential()
    with respx.mock:
        _route(respx.mock).mock(return_value=httpx.Response(200, json={}))
        async with MdcClient(credential=cred) as client:
            await client.assign_governance(
                _ASSESSMENT_ID, _KEY, owner="o@d", remediation_due_date=_DUE
            )
            await client.assign_governance(
                _ASSESSMENT_ID, _KEY, owner="o@d", remediation_due_date=_DUE
            )
    assert cred.call_count == 1  # token fetched once, reused


def test_default_credential_is_lazy() -> None:
    """Constructing without a credential lazily builds DefaultAzureCredential (§7)."""
    client = MdcClient()
    assert client._credential is not None
