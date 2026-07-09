"""Unit tests for ``clients.graph_client`` (§4.3 #5).

All HTTP is mocked with ``respx``; no real Graph calls are made (§5 testing
expectations). Covers happy path, not-found (None), 429 retry, 5xx
retry/exhaustion, non-404 client error, auth failure, and timeout.
"""

from __future__ import annotations

import time
from types import SimpleNamespace
from typing import Any

import httpx
import pytest
import respx
from clients.graph_client import GraphClient, GraphClientError
from models.enrichment import AadUser

_GRAPH_HOST = "graph.microsoft.com"


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
    return respx_mock.route(method="GET", host=_GRAPH_HOST)


async def test_resolve_user_happy_path() -> None:
    """A 200 maps Graph JSON into an AadUser and carries the bearer token."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(
            return_value=httpx.Response(
                200,
                json={
                    "id": "00000000-0000-0000-0000-000000000001",
                    "mail": "alice@contoso.com",
                    "userPrincipalName": "alice@contoso.com",
                },
            )
        )
        async with GraphClient(credential=cred) as client:
            user = await client.resolve_user("alice@contoso.com")

    assert isinstance(user, AadUser)
    assert user.id == "00000000-0000-0000-0000-000000000001"
    assert user.mail == "alice@contoso.com"
    assert user.user_principal_name == "alice@contoso.com"
    request = route.calls.last.request
    assert request.headers["Authorization"] == "Bearer fake-token"
    assert "%24select=id%2Cmail%2CuserPrincipalName" in str(request.url)


async def test_resolve_user_encodes_email_in_path() -> None:
    """The email path segment is URL-encoded (no raw '#'/'/' leaking)."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(return_value=httpx.Response(200, json={"id": "1"}))
        async with GraphClient(credential=cred) as client:
            await client.resolve_user("a/b#c@contoso.com")

    assert "/users/a%2Fb%23c%40contoso.com" in str(route.calls.last.request.url)


async def test_resolve_user_not_found_returns_none() -> None:
    """A 404 yields None (best-effort) and does not raise (§5.2.3)."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(return_value=httpx.Response(404))
        async with GraphClient(credential=cred) as client:
            user = await client.resolve_user("ghost@contoso.com")

    assert user is None
    assert route.call_count == 1  # 404 is not retried


async def test_resolve_user_empty_email_returns_none_without_call() -> None:
    """An empty email short-circuits to None without any HTTP call (§4.3 #5)."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(return_value=httpx.Response(200, json={"id": "1"}))
        async with GraphClient(credential=cred) as client:
            user = await client.resolve_user("")

    assert user is None
    assert route.call_count == 0


async def test_resolve_user_retries_on_429_then_succeeds() -> None:
    """A 429 is retried (tenacity) and the subsequent 200 wins (§4.3 #5)."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(
            side_effect=[
                httpx.Response(429),
                httpx.Response(200, json={"id": "1", "mail": "a@contoso.com"}),
            ]
        )
        async with GraphClient(credential=cred) as client:
            user = await client.resolve_user("a@contoso.com")

    assert user is not None
    assert user.id == "1"
    assert route.call_count == 2


async def test_resolve_user_retries_on_5xx_then_raises() -> None:
    """Persistent 5xx exhausts the 3 attempts and surfaces GraphClientError (§4.3 #5)."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(return_value=httpx.Response(503))
        async with GraphClient(credential=cred) as client:
            with pytest.raises(GraphClientError):
                await client.resolve_user("a@contoso.com")

    assert route.call_count == 3


async def test_resolve_user_non_404_client_error_raises() -> None:
    """A non-404 4xx fails fast (no retry) as GraphClientError (§4.3 #5)."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(return_value=httpx.Response(403, text="forbidden"))
        async with GraphClient(credential=cred) as client:
            with pytest.raises(GraphClientError):
                await client.resolve_user("a@contoso.com")

    assert route.call_count == 1


async def test_resolve_user_auth_failure_raises() -> None:
    """A credential error is wrapped as GraphClientError before any HTTP call (§7)."""
    cred = _FakeCredential(error=RuntimeError("no managed identity"))
    with respx.mock:
        route = _route(respx.mock).mock(return_value=httpx.Response(200, json={"id": "1"}))
        async with GraphClient(credential=cred) as client:
            with pytest.raises(GraphClientError):
                await client.resolve_user("a@contoso.com")

    assert route.call_count == 0


async def test_resolve_user_timeout_is_retried_then_raises() -> None:
    """A read timeout is retried and finally surfaces as GraphClientError (§4.3 #5, §6)."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(side_effect=httpx.ReadTimeout("read timed out"))
        async with GraphClient(credential=cred) as client:
            with pytest.raises(GraphClientError):
                await client.resolve_user("a@contoso.com")

    assert route.call_count == 3


async def test_resolve_user_requires_context_manager() -> None:
    """Calling resolve_user() without entering the context manager raises (§4.3 #5)."""
    client = GraphClient(credential=_FakeCredential())
    with pytest.raises(GraphClientError):
        await client.resolve_user("a@contoso.com")


async def test_resolve_user_transport_error_is_retried_then_raises() -> None:
    """A non-timeout transport error is retried then surfaces as GraphClientError."""
    cred = _FakeCredential()
    with respx.mock:
        route = _route(respx.mock).mock(side_effect=httpx.ConnectError("refused"))
        async with GraphClient(credential=cred) as client:
            with pytest.raises(GraphClientError):
                await client.resolve_user("a@contoso.com")

    assert route.call_count == 3
