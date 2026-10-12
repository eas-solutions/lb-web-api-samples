"""Token manager for LeegooBuilder Web API authentication.

Note:
This TokenManager is an example implementation that demonstrates token acquisition,
caching, validation, and renewal against the LeegooBuilder Web API.
Customers may replace or adapt this implementation to suit their custom authentication
infrastructure, vault/secret management systems, or security policies.
"""

from __future__ import annotations

import base64
import json
from pathlib import Path
import time
from typing import Any
import requests

from .config import Config, load_config


def is_jwt_valid(token: str) -> bool:
    """Check if token is a well-formed JWT and has not expired."""
    try:
        parts = token.split(".")
        if len(parts) != 3:
            return False
        payload_b64 = parts[1]
        payload_b64 += "=" * (-len(payload_b64) % 4)
        payload = json.loads(base64.urlsafe_b64decode(payload_b64).decode("utf-8"))
        exp = payload.get("exp")
        if exp is not None and time.time() >= exp:
            return False
        return True
    except Exception:
        return False


class TokenManager:
    """Manages acquisition, caching, validation, and renewal of API tokens.

    This is an example implementation that customers may replace or adapt.
    """

    def __init__(self, config: Config | None = None) -> None:
        self.config = config or load_config()

    def _cache_file_path(self) -> Path:
        return self.config.resolved_cache_path

    def load_cache(self) -> dict[str, Any] | None:
        """Load cached token data from disk if present and valid."""
        path = self._cache_file_path()
        if not path.is_file():
            return None
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            return data if isinstance(data, dict) else None
        except Exception:
            return None

    def save_cache(self, token: str, renewal_token: str | None = None) -> None:
        """Save token details to the local cache file."""
        path = self._cache_file_path()
        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            data = {
                "apiUrl": self.config.api_url,
                "username": self.config.username,
                "token": token,
                "renewalToken": renewal_token,
            }
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
        except Exception:
            # Failure to cache does not prevent token usage
            pass

    def clear_cache(self) -> None:
        """Remove the token cache file if it exists."""
        path = self._cache_file_path()
        if path.is_file():
            try:
                path.unlink()
            except Exception:
                pass

    def validate_token(self, token: str) -> bool:
        """Validate an access token against local structure and GET /api/Authentication/Validate."""
        if not token or not is_jwt_valid(token):
            return False

        url = f"{self.config.api_url}Authentication/Validate"
        headers = {
            "Accept": "application/json",
            "Authorization": f"Bearer {token}",
        }
        try:
            response = requests.get(url, headers=headers, timeout=10)
            if response.status_code != 200:
                return False
            data = response.json()
            if isinstance(data, dict):
                if data.get("successful") is True:
                    return True
                op_result = data.get("operationResult")
                if isinstance(op_result, dict) and op_result.get("successful") is True:
                    return True
            return False
        except Exception:
            return False

    def renew_token(self, expired_token: str, renewal_token: str | None = None) -> str | None:
        """Attempt to renew a token via POST /api/Authentication/RenewToken."""
        url = f"{self.config.api_url}Authentication/RenewToken"
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": f"Bearer {expired_token}",
        }
        payload = {
            "ExpiredToken": expired_token,
            "RenewalToken": renewal_token or "",
        }
        try:
            response = requests.post(url, json=payload, headers=headers, timeout=10)
            if response.status_code != 200:
                return None
            data = response.json()
            if isinstance(data, dict):
                new_token = data.get("token")
                if new_token and isinstance(new_token, str):
                    self.save_cache(new_token, renewal_token)
                    return new_token
            return None
        except Exception:
            return None

    def login(self) -> str:
        """Perform a fresh login call and cache the returned token."""
        url = f"{self.config.api_url}Authentication/Login"
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
        }
        payload = {
            "Username": self.config.username,
            "Password": self.config.password,
            "Culture": self.config.culture,
            "Language": self.config.language,
        }
        response = requests.post(url, json=payload, headers=headers, timeout=15)
        response.raise_for_status()

        data = response.json()
        if not isinstance(data, dict):
            raise RuntimeError(f"Unexpected response format from Login: {data}")

        op_result = data.get("operationResult") or {}
        if not op_result.get("successful", False):
            msg = op_result.get("detailedMessage") or op_result.get("shortMessage") or "Login failed"
            raise RuntimeError(f"Login failed: {msg}")

        user = data.get("user") or {}
        token = user.get("token")
        if not token:
            raise RuntimeError("Login succeeded but no token was returned in response.user.token")

        renewal_token = data.get("renewalToken")
        self.save_cache(token, renewal_token)
        return token

    def get_token(self, force_refresh: bool = False) -> str:
        """Obtain a valid access token.

        Uses cached token if valid; attempts renewal if invalid;
        otherwise performs a fresh login.
        """
        if force_refresh:
            return self.login()

        cache = self.load_cache()
        if cache:
            cached_url = cache.get("apiUrl")
            cached_user = cache.get("username")
            cached_token = cache.get("token")
            cached_renewal = cache.get("renewalToken")

            # Must match current config
            if cached_token and cached_url == self.config.api_url and cached_user == self.config.username:
                if self.validate_token(cached_token):
                    return cached_token

                # Try renewal
                renewed = self.renew_token(cached_token, cached_renewal)
                if renewed and self.validate_token(renewed):
                    return renewed

        return self.login()
