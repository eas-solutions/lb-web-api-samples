"""Create a new person record via InitPerson and SavePerson."""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path
import sys

# Bootstrap lbapi package from parent directory
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lbapi import LbApiClient, load_config, print_result


def main() -> None:
    timestamp = datetime.now().strftime("%d%H%M%S")
    parser = argparse.ArgumentParser(description="Create a new person for a company.")
    parser.add_argument("--company-id", required=True, help="Internal company GUID")
    parser.add_argument("--name", default=f"Test Person {timestamp}", help="Person full name")
    parser.add_argument("--person-id", default=f"TestPerson{timestamp}", help="Unique PersonID string")
    parser.add_argument("--api-url", help="Base URL of the Web API")
    args = parser.parse_args()

    config = load_config()
    if args.api_url:
        config.api_url = args.api_url

    client = LbApiClient(config)

    # 1. Initialize person with internal company ID
    init_res = client.post("CompaniesAndPersons/InitPerson", {"internalCompanyID": args.company_id})
    if not init_res.get("operationResult", {}).get("successful", False):
        print_result(init_res)
        return

    person = init_res.get("person") or {}
    person["name"] = args.name
    person["personID"] = args.person_id
    person["isActive"] = 1
    person["internalCompanyID"] = args.company_id

    # 2. Save person with SaveDataMode = 10 (Insert)
    save_payload = {
        "person": person,
        "saveDataMode": 10,
    }
    save_res = client.post("CompaniesAndPersons/SavePerson", save_payload)
    print_result(save_res)


if __name__ == "__main__":
    main()
