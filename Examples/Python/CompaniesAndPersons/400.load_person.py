"""Load a single person by internal person GUID."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

# Bootstrap lbapi package from parent directory
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lbapi import LbApiClient, load_config, print_result


def main() -> None:
    parser = argparse.ArgumentParser(description="Load a person by internal person ID.")
    parser.add_argument("--id", "--internal-person-id", required=True, dest="internal_person_id", help="Internal person GUID")
    parser.add_argument("--api-url", help="Base URL of the Web API")
    args = parser.parse_args()

    config = load_config()
    if args.api_url:
        config.api_url = args.api_url

    client = LbApiClient(config)
    result = client.post("CompaniesAndPersons/LoadPerson", {"internalPersonID": args.internal_person_id})
    print_result(result)


if __name__ == "__main__":
    main()
