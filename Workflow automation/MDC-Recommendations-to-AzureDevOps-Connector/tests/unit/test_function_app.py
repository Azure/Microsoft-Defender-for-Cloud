"""Unit tests for ``function_app`` HTTP starter + instance-id dedupe (§5.1, §5.2.4).

No real Durable client or Functions host is involved: the durable client is a hand
double exposing ``get_status`` / ``start_new`` / ``create_check_status_response``, and
``HttpRequest`` is a minimal double over ``get_json``.
"""

from __future__ import annotations

import hashlib
from typing import Any

import azure.durable_functions as df
import azure.functions as func
import function_app

_RESOURCE_ID = (
    "/subscriptions/sub-1/resourceGroups/rg-web/providers/"
    "Microsoft.Compute/virtualMachines/contoso-web-01"
)


class _FakeRequest:
    """Minimal ``func.HttpRequest`` double over ``get_json``."""

    def __init__(self, payload: Any, *, raise_value_error: bool = False) -> None:
        self._payload = payload
        self._raise = raise_value_error

    def get_json(self) -> Any:
        if self._raise:
            raise ValueError("not JSON")
        return self._payload


class _FakeStatus:
    def __init__(self, runtime_status: df.OrchestrationRuntimeStatus | None) -> None:
        self.runtime_status = runtime_status


class _FakeDurableClient:
    """Records orchestration starts and serves a canned status (§5.2.4)."""

    def __init__(self, status: _FakeStatus | None = None) -> None:
        self._status = status
        self.started: list[tuple[str, str, Any]] = []
        self.status_queries: list[str] = []

    async def get_status(self, instance_id: str) -> _FakeStatus | None:
        self.status_queries.append(instance_id)
        return self._status

    async def start_new(self, name: str, instance_id: str, payload: Any) -> str:
        self.started.append((name, instance_id, payload))
        return instance_id

    def create_check_status_response(self, req: Any, instance_id: str) -> func.HttpResponse:
        return func.HttpResponse(instance_id, status_code=202)


def _payload() -> dict[str, Any]:
    return {
        "name": "assessment-guid-1",
        "properties": {"resourceDetails": {"id": _RESOURCE_ID}},
    }


def _expected_instance_id(payload: dict[str, Any]) -> str:
    name = str(payload.get("name") or "")
    rid = str(payload["properties"]["resourceDetails"]["id"])
    return hashlib.sha256(f"{name}|{rid}".encode()).hexdigest()


def test_instance_id_is_deterministic_sha256() -> None:
    """``_instance_id`` = sha256(assessment_id|resource_id) (§5.2.4)."""
    payload = _payload()
    assert function_app._instance_id(payload) == _expected_instance_id(payload)


def test_instance_id_handles_missing_fields() -> None:
    """Absent ``properties``/``resourceDetails`` collapse to empty id components."""
    assert function_app._instance_id({}) == hashlib.sha256(b"|").hexdigest()
    assert (
        function_app._instance_id({"name": "a", "properties": "not-a-dict"})
        == hashlib.sha256(b"a|").hexdigest()
    )
    assert (
        function_app._instance_id({"name": "a", "properties": {"resourceDetails": "nope"}})
        == hashlib.sha256(b"a|").hexdigest()
    )


async def test_http_start_starts_orchestration_when_none_running() -> None:
    """No existing instance -> start_new is called with the deterministic id."""
    payload = _payload()
    client = _FakeDurableClient(status=None)
    resp = await function_app._handle_http_start(_FakeRequest(payload), client)

    instance_id = _expected_instance_id(payload)
    assert resp.status_code == 202
    assert client.started == [(function_app._ORCHESTRATOR_NAME, instance_id, payload)]
    assert client.status_queries == [instance_id]


async def test_http_start_refires_terminal_instance() -> None:
    """A terminal instance for the same key is re-fired (the update path) (§5.2.4)."""
    payload = _payload()
    client = _FakeDurableClient(status=_FakeStatus(df.OrchestrationRuntimeStatus.Completed))
    resp = await function_app._handle_http_start(_FakeRequest(payload), client)

    assert resp.status_code == 202
    assert len(client.started) == 1


async def test_http_start_treats_running_instance_as_duplicate() -> None:
    """A still-running instance is a duplicate -> no second orchestration started."""
    payload = _payload()
    client = _FakeDurableClient(status=_FakeStatus(df.OrchestrationRuntimeStatus.Running))
    resp = await function_app._handle_http_start(_FakeRequest(payload), client)

    assert resp.status_code == 202
    assert client.started == []


async def test_http_start_starts_when_status_object_has_none_runtime() -> None:
    """A non-existent key surfaces as a status object whose runtime_status is None;
    this must start the orchestration, not be treated as a duplicate (§5.2.4)."""
    payload = _payload()
    client = _FakeDurableClient(status=_FakeStatus(None))
    resp = await function_app._handle_http_start(_FakeRequest(payload), client)

    assert resp.status_code == 202
    assert len(client.started) == 1


async def test_http_start_rejects_invalid_json() -> None:
    """A body that is not JSON -> 400 (§5.2.4)."""
    client = _FakeDurableClient()
    resp = await function_app._handle_http_start(_FakeRequest(None, raise_value_error=True), client)
    assert resp.status_code == 400
    assert client.started == []


async def test_http_start_rejects_non_object_payload() -> None:
    """A JSON value that is not an object -> 400 (§5.2.4)."""
    client = _FakeDurableClient()
    resp = await function_app._handle_http_start(_FakeRequest([1, 2, 3]), client)
    assert resp.status_code == 400
    assert client.started == []
