"""Unit tests for lbapi.config."""

from __future__ import annotations

import json
from pathlib import Path
import tempfile
import pytest

from lbapi.config import Config, load_config, DEFAULT_API_URL, DEFAULT_USERNAME


def test_default_config() -> None:
    cfg = Config()
    assert cfg.api_url == DEFAULT_API_URL
    assert cfg.username == DEFAULT_USERNAME
    assert cfg.api_url.endswith("/")
    assert cfg.resolved_cache_path.name == ".token_cache.json"


def test_custom_config_trailing_slash() -> None:
    cfg = Config(api_url="http://custom-host:1234/api")
    assert cfg.api_url == "http://custom-host:1234/api/"


def test_load_config_from_file() -> None:
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
        json.dump(
            {
                "apiUrl": "http://testserver:5000/api",
                "username": "TestUser",
                "password": "secret",
                "culture": "en-US",
                "language": "en-US",
                "tokenCachePath": "custom_token.json",
            },
            f,
        )
        temp_path = Path(f.name)

    try:
        cfg = load_config(temp_path)
        assert cfg.api_url == "http://testserver:5000/api/"
        assert cfg.username == "TestUser"
        assert cfg.password == "secret"
        assert cfg.culture == "en-US"
        assert cfg.language == "en-US"
        assert cfg.token_cache_path == "custom_token.json"
    finally:
        temp_path.unlink()


def test_load_config_nonexistent_file() -> None:
    cfg = load_config("nonexistent_config_file_12345.json")
    assert cfg.api_url == DEFAULT_API_URL
    assert cfg.username == DEFAULT_USERNAME
