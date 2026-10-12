"""Retrieve available login cultures and languages anonymously."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys
import requests

# Bootstrap lbapi package from parent directory
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lbapi import load_config, print_result


def main() -> None:
    parser = argparse.ArgumentParser(description="Call LoadLoginInfos anonymously.")
    parser.add_argument("--api-url", help="Base URL of the Web API")
    args = parser.parse_args()

    config = load_config()
    if args.api_url:
        config.api_url = args.api_url

    url = f"{config.api_url}Authentication/LoadLoginInfos"
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    response = requests.post(url, json={}, headers=headers, timeout=15)
    response.raise_for_status()
    data = response.json()
    print_result(data)


if __name__ == "__main__":
    main()
