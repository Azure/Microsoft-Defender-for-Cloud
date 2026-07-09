"""Unit tests for ``activities.resolve_owner`` (§4.3 #5, §5.2.3)."""

from __future__ import annotations

import time
from types import SimpleNamespace
from typing import Any

import activities.resolve_owner as resolve
import httpx
import pytest
import respx
from clients.graph_client import GraphClient
from models.enrichment import OwnerInfo

# Captured at import time so the seam test can exercise the *real* builder even
# while the autouse fixture below monkeypatches the module attribute.
_REAL_BUILD_GRAPH = resolve._build_graph_client

_GRAPH_HOST = "graph.microsoft.com"


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
    monkeypatch.setattr(
        resolve, "_build_graph_client", lambda: GraphClient(credential=_FakeCredential())
    )


def _graph_route(status: int, json: dict[str, Any] | None = None) -> None:
    respx.mock.route(method="GET", host=_GRAPH_HOST).mock(
        return_value=httpx.Response(status, json=json or {})
    )


async def test_resolve_owner_graph_hit() -> None:
    """An email tag resolvable in Graph yields ``source == 'graph'`` and an object id."""
    with respx.mock:
        _graph_route(
            200,
            {
                "id": "00000000-0000-0000-0000-000000000001",
                "mail": "alice@contoso.com",
                "userPrincipalName": "alice@contoso.com",
            },
        )
        info = OwnerInfo.model_validate(await resolve.activity_resolve_owner("alice@contoso.com"))

    assert info.source == "graph"
    assert info.email == "alice@contoso.com"
    assert info.aad_object_id == "00000000-0000-0000-0000-000000000001"


async def test_resolve_owner_graph_miss_keeps_tag() -> None:
    """An email tag not found in Graph (404) degrades to ``source == 'tag'``."""
    with respx.mock:
        _graph_route(404, {"error": {"code": "Request_ResourceNotFound"}})
        info = OwnerInfo.model_validate(await resolve.activity_resolve_owner("ghost@contoso.com"))

    assert info.source == "tag"
    assert info.email == "ghost@contoso.com"
    assert info.aad_object_id is None


async def test_resolve_owner_non_email_tag() -> None:
    """A non-email tag (e.g. a team name) is kept as a tag hint without a Graph call."""
    with respx.mock:
        route = respx.mock.route(method="GET", host=_GRAPH_HOST)
        info = OwnerInfo.model_validate(
            await resolve.activity_resolve_owner("Platform Security Team")
        )

    assert info.source == "tag"
    assert info.email == "Platform Security Team"
    assert route.call_count == 0


async def test_resolve_owner_empty_tag_is_unknown() -> None:
    """No owner tag yields ``source == 'unknown'``."""
    info = OwnerInfo.model_validate(await resolve.activity_resolve_owner(None))
    assert info.source == "unknown"
    assert info.email is None


async def test_resolve_owner_degrades_on_graph_error() -> None:
    """A persistent Graph 5xx degrades to the tag value, never raising (§5.2.3)."""
    with respx.mock:
        _graph_route(500, {"error": "boom"})
        info = OwnerInfo.model_validate(await resolve.activity_resolve_owner("alice@contoso.com"))

    assert info.source == "tag"
    assert info.email == "alice@contoso.com"


def test_build_graph_client_seam_returns_real_client() -> None:
    """The real ``_build_graph_client`` seam constructs a ``GraphClient`` (§7)."""
    client = _REAL_BUILD_GRAPH()
    assert isinstance(client, GraphClient)
