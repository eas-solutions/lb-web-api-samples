"""Modify an existing person via SavePerson (Update mode)."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

# Bootstrap lbapi package from parent directory
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lbapi import LbApiClient, load_config, print_result


def main() -> None:
    parser = argparse.ArgumentParser(description="Modify an existing person.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--id", "--internal-person-id", dest="internal_person_id", help="Internal person GUID")
    group.add_argument("--json-file", help="Path to a JSON file containing the person item")
    parser.add_argument("--name", help="New name for the person")
    parser.add_argument("--api-url", help="Base URL of the Web API")
    args = parser.parse_args()

    config = load_config()
    if args.api_url:
        config.api_url = args.api_url

    client = LbApiClient(config)

    if args.json_file:
        with open(args.json_file, "r", encoding="utf-8") as f:
            data = json.load(f)
        person = data.get("person", data)
    else:
        load_res = client.post("CompaniesAndPersons/LoadPerson", {"internalPersonID": args.internal_person_id})
        if not load_res.get("operationResult", {}).get("successful", False):
            print_result(load_res)
            return
        person = load_res.get("person")
        if not person:
            raise RuntimeError(f"Person {args.internal_person_id} not found in response.")

    if args.name:
        person["name"] = args.name
    else:
        person["name"] = f"{person.get('name', '')} (Updated)"

    save_payload = {
        "person": person,
        "saveDataMode": 20,  # SaveDataMode.Update
    }
    save_res = client.post("CompaniesAndPersons/SavePerson", save_payload)
    print_result(save_res)


if __name__ == "__main__":
    main()
