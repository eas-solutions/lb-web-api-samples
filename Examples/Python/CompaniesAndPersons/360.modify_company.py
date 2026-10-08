"""Modify an existing company via SaveCompany (Update mode)."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

# Bootstrap lbapi package from parent directory
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lbapi import LbApiClient, load_config, print_result


def main() -> None:
    parser = argparse.ArgumentParser(description="Modify an existing company.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--id", "--internal-company-id", dest="internal_company_id", help="Internal company GUID")
    group.add_argument("--json-file", help="Path to a JSON file containing the company item")
    parser.add_argument("--name", help="New Name1 for the company")
    parser.add_argument("--api-url", help="Base URL of the Web API")
    args = parser.parse_args()

    config = load_config()
    if args.api_url:
        config.api_url = args.api_url

    client = LbApiClient(config)

    if args.json_file:
        with open(args.json_file, "r", encoding="utf-8") as f:
            data = json.load(f)
        company = data.get("company", data)
    else:
        load_res = client.post("CompaniesAndPersons/LoadCompany", {"internalCompanyID": args.internal_company_id})
        if not load_res.get("operationResult", {}).get("successful", False):
            print_result(load_res)
            return
        company = load_res.get("company")
        if not company:
            raise RuntimeError(f"Company {args.internal_company_id} not found in response.")

    if args.name:
        company["name1"] = args.name
    else:
        company["name1"] = f"{company.get('name1', '')} (Updated)"

    save_payload = {
        "company": company,
        "saveDataMode": 20,  # SaveDataMode.Update
    }
    save_res = client.post("CompaniesAndPersons/SaveCompany", save_payload)
    print_result(save_res)


if __name__ == "__main__":
    main()
