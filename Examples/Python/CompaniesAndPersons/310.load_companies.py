"""Load companies matching a name filter."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

# Bootstrap lbapi package from parent directory
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lbapi import LbApiClient, load_config, print_result


def main() -> None:
    parser = argparse.ArgumentParser(description="Load companies by name filter.")
    parser.add_argument("--name", default="gmbh", help="Company name filter string (default: gmbh)")
    parser.add_argument("--api-url", help="Base URL of the Web API")
    args = parser.parse_args()

    config = load_config()
    if args.api_url:
        config.api_url = args.api_url

    client = LbApiClient(config)
    result = client.post("CompaniesAndPersons/LoadCompanies", {"name": args.name})
    print_result(result)


if __name__ == "__main__":
    main()
