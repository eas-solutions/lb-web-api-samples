"""Unit tests for lbapi.client."""

from __future__ import annotations

from unittest.mock import MagicMock, patch
import pytest
import requests

from lbapi.config import Config
from lbapi.client import LbApiClient


@pytest.fixture
def mock_client() -> LbApiClient:
    cfg = Config(api_url="http://mock-api:8080/api/")
    tm = MagicMock()
    tm.get_token.return_value = "mock-bearer-token"
    return LbApiClient(config=cfg, token_manager=tm)


def test_build_url(mock_client: LbApiClient) -> None:
    assert mock_client._build_url("Project/GetProjects") == "http://mock-api:8080/api/Project/GetProjects"
    assert mock_client._build_url("/api/Project/GetProjects") == "http://mock-api:8080/api/Project/GetProjects"
    assert mock_client._build_url("api/Authentication/Validate") == "http://mock-api:8080/api/Authentication/Validate"


def test_get_request(mock_client: LbApiClient) -> None:
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {"operationResult": {"successful": True}}
    mock_client.session.get = MagicMock(return_value=mock_resp)

    data = mock_client.get("Authentication/Validate")
    assert data["operationResult"]["successful"] is True

    mock_client.session.get.assert_called_once_with(
        "http://mock-api:8080/api/Authentication/Validate",
        params=None,
        headers={
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer mock-bearer-token",
        },
        timeout=30,
    )


def test_post_request(mock_client: LbApiClient) -> None:
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {"operationResult": {"successful": True}}
    mock_client.session.post = MagicMock(return_value=mock_resp)

    payload = {"ProjectsContent": [10]}
    data = mock_client.post("Project/GetProjects", payload)
    assert data["operationResult"]["successful"] is True

    mock_client.session.post.assert_called_once_with(
        "http://mock-api:8080/api/Project/GetProjects",
        json=payload,
        headers={
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer mock-bearer-token",
        },
        timeout=30,
    )


def test_auth_retry_on_expired_token(mock_client: LbApiClient) -> None:
    expired_resp = MagicMock()
    expired_resp.status_code = 200
    expired_resp.json.return_value = {
        "operationResult": {"successful": False, "operationFailType": 80, "shortMessage": "Token expired"}
    }

    success_resp = MagicMock()
    success_resp.status_code = 200
    success_resp.json.return_value = {
        "operationResult": {"successful": True}
    }

    mock_client.session.post = MagicMock(side_effect=[expired_resp, success_resp])
    mock_client.token_manager.get_token.side_effect = ["old-token", "refreshed-token"]

    data = mock_client.post("Project/GetProjects", {})
    assert data["operationResult"]["successful"] is True
    assert mock_client.session.post.call_count == 2
    mock_client.token_manager.get_token.assert_called_with(force_refresh=True)


def test_http_error_raises(mock_client: LbApiClient) -> None:
    error_resp = MagicMock()
    error_resp.status_code = 500
    error_resp.raise_for_status.side_effect = requests.HTTPError("Server error 500")
    mock_client.session.post = MagicMock(return_value=error_resp)

    with pytest.raises(requests.HTTPError):
        mock_client.post("Project/GetProjects", {})
