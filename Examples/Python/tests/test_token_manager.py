"""Unit tests for lbapi.token_manager."""

from __future__ import annotations

import json
from pathlib import Path
import tempfile
from unittest.mock import MagicMock, patch
import pytest

from lbapi.config import Config
from lbapi.token_manager import TokenManager


@pytest.fixture
def temp_cache_config() -> Config:
    temp_dir = tempfile.mkdtemp()
    cache_path = Path(temp_dir) / ".test_token_cache.json"
    return Config(
        api_url="http://mock-api:1234/api/",
        username="Admin",
        password="pwd",
        culture="de-DE",
        language="de-DE",
        token_cache_path=str(cache_path),
        base_dir=Path(temp_dir),
    )


def test_token_manager_cache_save_load(temp_cache_config: Config) -> None:
    tm = TokenManager(temp_cache_config)
    assert tm.load_cache() is None

    tm.save_cache("access-token-123", "renewal-token-456")
    cached = tm.load_cache()
    assert cached is not None
    assert cached["token"] == "access-token-123"
    assert cached["renewalToken"] == "renewal-token-456"
    assert cached["username"] == "Admin"
    assert cached["apiUrl"] == "http://mock-api:1234/api/"

    tm.clear_cache()
    assert tm.load_cache() is None


DUMMY_JWT = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IkFkbWluIiwiZXhwIjoyNTI0NjA4MDAwfQ.signature"


@patch("requests.get")
def test_validate_token_success(mock_get: MagicMock, temp_cache_config: Config) -> None:
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {"successful": True}
    mock_get.return_value = mock_resp

    tm = TokenManager(temp_cache_config)
    assert tm.validate_token(DUMMY_JWT) is True
    mock_get.assert_called_once_with(
        "http://mock-api:1234/api/Authentication/Validate",
        headers={"Accept": "application/json", "Authorization": f"Bearer {DUMMY_JWT}"},
        timeout=10,
    )


@patch("requests.get")
def test_validate_token_failure(mock_get: MagicMock, temp_cache_config: Config) -> None:
    mock_resp = MagicMock()
    mock_resp.status_code = 401
    mock_get.return_value = mock_resp

    tm = TokenManager(temp_cache_config)
    assert tm.validate_token(DUMMY_JWT) is False


@patch("requests.post")
def test_renew_token_success(mock_post: MagicMock, temp_cache_config: Config) -> None:
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {"token": "new-jwt-token"}
    mock_post.return_value = mock_resp

    tm = TokenManager(temp_cache_config)
    new_token = tm.renew_token("old-jwt", "renew-key")
    assert new_token == "new-jwt-token"

    cached = tm.load_cache()
    assert cached is not None
    assert cached["token"] == "new-jwt-token"


@patch("requests.post")
def test_login_success(mock_post: MagicMock, temp_cache_config: Config) -> None:
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {
        "operationResult": {"successful": True},
        "user": {"token": "fresh-login-jwt"},
        "renewalToken": "fresh-renewal-token",
    }
    mock_post.return_value = mock_resp

    tm = TokenManager(temp_cache_config)
    token = tm.login()
    assert token == "fresh-login-jwt"

    cached = tm.load_cache()
    assert cached is not None
    assert cached["token"] == "fresh-login-jwt"
    assert cached["renewalToken"] == "fresh-renewal-token"


@patch("requests.post")
def test_login_failure_raises(mock_post: MagicMock, temp_cache_config: Config) -> None:
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {
        "operationResult": {"successful": False, "shortMessage": "Bad credentials"},
    }
    mock_post.return_value = mock_resp

    tm = TokenManager(temp_cache_config)
    with pytest.raises(RuntimeError, match="Bad credentials"):
        tm.login()


def test_get_token_flow(temp_cache_config: Config) -> None:
    tm = TokenManager(temp_cache_config)

    # 1. First time with no cache: calls login
    with patch.object(tm, "login", return_value="login-token-1") as mock_login:
        token = tm.get_token()
        assert token == "login-token-1"
        mock_login.assert_called_once()

    # Save cache
    tm.save_cache("cached-token-1", "renewal-1")

    # 2. Cached token is valid: returns cached token without login
    with patch.object(tm, "validate_token", return_value=True) as mock_val, \
         patch.object(tm, "login") as mock_login:
        token = tm.get_token()
        assert token == "cached-token-1"
        mock_val.assert_called_once_with("cached-token-1")
        mock_login.assert_not_called()

    # 3. Cached token is invalid, renewal succeeds: returns renewed token
    with patch.object(tm, "validate_token", side_effect=[False, True]) as mock_val, \
         patch.object(tm, "renew_token", return_value="renewed-token-2") as mock_renew, \
         patch.object(tm, "login") as mock_login:
        token = tm.get_token()
        assert token == "renewed-token-2"
        mock_renew.assert_called_once_with("cached-token-1", "renewal-1")
        mock_login.assert_not_called()

    # 4. Username changed in config: bypasses cache and logs in
    tm.config.username = "OtherUser"
    with patch.object(tm, "login", return_value="other-user-token") as mock_login:
        token = tm.get_token()
        assert token == "other-user-token"
        mock_login.assert_called_once()
