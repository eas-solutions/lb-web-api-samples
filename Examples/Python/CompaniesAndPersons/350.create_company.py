"""Create a new company via InitCompany and SaveCompany."""

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
    parser = argparse.ArgumentParser(description="Create a new company in LeegooBuilder.")
    parser.add_argument("--name", default="Test Company", help="Company Name1 (default: Test Company)")
    parser.add_argument("--company-id", default=f"TestCompany{timestamp}", help="Unique CompanyID string")
    parser.add_argument("--api-url", help="Base URL of the Web API")
    args = parser.parse_args()

    config = load_config()
    if args.api_url:
        config.api_url = args.api_url

    client = LbApiClient(config)

    # 1. Initialize empty company model
    init_res = client.post("CompaniesAndPersons/InitCompany", {})
    if not init_res.get("operationResult", {}).get("successful", False):
        print_result(init_res)
        return

    company = init_res.get("company") or {}
    company["name1"] = args.name
    company["companyID"] = args.company_id

    # 2. Save company with SaveDataMode = 10 (Insert)
    save_payload = {
        "company": company,
        "saveDataMode": 10,
    }
    save_res = client.post("CompaniesAndPersons/SaveCompany", save_payload)
    print_result(save_res)


if __name__ == "__main__":
    main()
