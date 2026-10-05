"""Authenticate against the LeegooBuilder Web API and display user details."""

from __future__ import annotations

import argparse
import base64
from datetime import datetime, timezone
import json
from pathlib import Path
import sys

# Bootstrap lbapi package from parent directory
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lbapi import TokenManager, load_config, print_result


def decode_jwt_payload(jwt_token: str) -> dict:
    """Safely decode the JSON payload from a JWT token."""
    try:
        parts = jwt_token.split(".")
        if len(parts) >= 2:
            payload_b64 = parts[1]
            payload_b64 += "=" * (-len(payload_b64) % 4)
            return json.loads(base64.urlsafe_b64decode(payload_b64).decode("utf-8"))
    except Exception:
        pass
    return {}


def main() -> None:
    parser = argparse.ArgumentParser(description="Log in to LeegooBuilder Web API via TokenManager.")
    parser.add_argument("--api-url", help="Base URL of the Web API")
    parser.add_argument("--username", help="Login username")
    parser.add_argument("--password", help="Login password")
    parser.add_argument("--culture", help="Login culture (e.g. de-DE)")
    parser.add_argument("--language", help="Login language (e.g. de-DE)")
    args = parser.parse_args()

    config = load_config()
    if args.api_url:
        config.api_url = args.api_url
    if args.username:
        config.username = args.username
    if args.password:
        config.password = args.password
    if args.culture:
        config.culture = args.culture
    if args.language:
        config.language = args.language

    token_manager = TokenManager(config)
    token = token_manager.get_token(force_refresh=True)

    payload = decode_jwt_payload(token)
    exp_ts = payload.get("exp")
    exp_iso = (
        datetime.fromtimestamp(exp_ts, tz=timezone.utc).isoformat()
        if exp_ts is not None
        else None
    )

    output = {
        "operationResult": {
            "successful": True,
            "shortMessage": "Login successful",
            "detailedMessage": None,
            "operationFailType": 0,
        },
        "user": {
            "username": config.username,
            "token": token,
            "tokenExpiration": exp_iso,
        },
    }
    print_result(output)


if __name__ == "__main__":
    main()
