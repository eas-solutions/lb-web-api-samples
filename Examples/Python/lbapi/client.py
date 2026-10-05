"""Web API client for LeegooBuilder."""

from __future__ import annotations

from typing import Any
import requests

from .config import Config, load_config
from .token_manager import TokenManager


AUTH_RETRY_FAIL_TYPES = {10, 20, 80}  # NotLoggedIn (10), TokenInvalid (20), TokenExpired (80)


class LbApiClient:
    """Client for interacting with the LeegooBuilder Web API using JSON."""

    def __init__(
        self,
        config: Config | None = None,
        token_manager: TokenManager | None = None,
    ) -> None:
        self.config = config or load_config()
        self.token_manager = token_manager or TokenManager(self.config)
        self.session = requests.Session()

    def _build_url(self, path: str) -> str:
        clean_path = path.lstrip("/")
        if clean_path.lower().startswith("api/"):
            clean_path = clean_path[4:]
        return f"{self.config.api_url}{clean_path}"

    def _get_headers(self, token: str) -> dict[str, str]:
        return {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}",
        }

    def _should_retry_auth(self, data: Any) -> bool:
        if isinstance(data, dict):
            op_result = data.get("operationResult")
            if isinstance(op_result, dict):
                fail_type = op_result.get("operationFailType")
                if fail_type in AUTH_RETRY_FAIL_TYPES:
                    return True
        return False

    def get(self, path: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
        """Send an authenticated GET request, parsing and returning the JSON result."""
        url = self._build_url(path)
        token = self.token_manager.get_token()
        headers = self._get_headers(token)

        response = self.session.get(url, params=params, headers=headers, timeout=30)
        response.raise_for_status()
        data = response.json()

        if self._should_retry_auth(data):
            # Token invalid/expired; force refresh and retry once
            token = self.token_manager.get_token(force_refresh=True)
            headers = self._get_headers(token)
            response = self.session.get(url, params=params, headers=headers, timeout=30)
            response.raise_for_status()
            data = response.json()

        return data

    def post(self, path: str, body: dict[str, Any] | None = None) -> dict[str, Any]:
        """Send an authenticated POST request, parsing and returning the JSON result."""
        url = self._build_url(path)
        token = self.token_manager.get_token()
        headers = self._get_headers(token)
        payload = body if body is not None else {}

        response = self.session.post(url, json=payload, headers=headers, timeout=30)
        response.raise_for_status()
        data = response.json()

        if self._should_retry_auth(data):
            # Token invalid/expired; force refresh and retry once
            token = self.token_manager.get_token(force_refresh=True)
            headers = self._get_headers(token)
            response = self.session.post(url, json=payload, headers=headers, timeout=30)
            response.raise_for_status()
            data = response.json()

        return data
