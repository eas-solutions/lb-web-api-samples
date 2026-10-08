"""Configuration loader for LeegooBuilder Web API samples."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


DEFAULT_API_URL = "http://localhost:56540/api/"
DEFAULT_USERNAME = "YourUsername"
DEFAULT_PASSWORD = "YourPassword"
DEFAULT_CULTURE = "de-DE"
DEFAULT_LANGUAGE = "de-DE"
DEFAULT_TOKEN_CACHE_FILE = ".token_cache.json"


@dataclass
class Config:
    """Holds configuration for API communication."""

    api_url: str = DEFAULT_API_URL
    username: str = DEFAULT_USERNAME
    password: str = DEFAULT_PASSWORD
    culture: str = DEFAULT_CULTURE
    language: str = DEFAULT_LANGUAGE
    token_cache_path: str = DEFAULT_TOKEN_CACHE_FILE
    base_dir: Path = Path(__file__).resolve().parent.parent

    def __post_init__(self) -> None:
        if not self.api_url.endswith("/"):
            self.api_url += "/"

    @property
    def resolved_cache_path(self) -> Path:
        """Resolve token cache path relative to base_dir if relative."""
        p = Path(self.token_cache_path)
        if not p.is_absolute():
            return self.base_dir / p
        return p


def _get_key(data: dict[str, Any], *aliases: str, default: Any = None) -> Any:
    for alias in aliases:
        if alias in data:
            return data[alias]
    return default


def load_config(config_path: str | Path | None = None) -> Config:
    """Load configuration from a JSON file, falling back to default values.

    By default, searches for 'config.json' in the Examples/Python root folder.
    """
    base_dir = Path(__file__).resolve().parent.parent
    target_path = Path(config_path) if config_path else base_dir / "config.json"

    cfg = Config(base_dir=base_dir)

    if target_path.is_file():
        try:
            with open(target_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            if isinstance(data, dict):
                cfg.api_url = _get_key(data, "apiUrl", "ApiUrl", "api_url", default=cfg.api_url)
                cfg.username = _get_key(data, "username", "Username", default=cfg.username)
                cfg.password = _get_key(data, "password", "Password", default=cfg.password)
                cfg.culture = _get_key(data, "culture", "Culture", default=cfg.culture)
                cfg.language = _get_key(data, "language", "Language", default=cfg.language)
                cfg.token_cache_path = _get_key(
                    data,
                    "tokenCachePath",
                    "TokenCachePath",
                    "token_cache_path",
                    default=cfg.token_cache_path,
                )
        except Exception:
            # If reading or parsing fails, keep defaults
            pass

    if not cfg.api_url.endswith("/"):
        cfg.api_url += "/"

    return cfg
