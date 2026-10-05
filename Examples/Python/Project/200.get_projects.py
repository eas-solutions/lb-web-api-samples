"""Retrieve projects list from LeegooBuilder Web API with optional name filter."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

# Bootstrap lbapi package from parent directory
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lbapi import LbApiClient, load_config, print_result


def main() -> None:
    parser = argparse.ArgumentParser(description="Get projects from LeegooBuilder Web API.")
    parser.add_argument("--name", help="Optional filter string on project Description (Contains)")
    parser.add_argument("--api-url", help="Base URL of the Web API")
    args = parser.parse_args()

    config = load_config()
    if args.api_url:
        config.api_url = args.api_url

    client = LbApiClient(config)

    payload: dict = {
        "ProjectsContent": [10],  # GetProjectsContent.Projects
    }

    if args.name:
        payload["QuerySettings"] = {
            "Where": [
                {
                    "Field": "Description",
                    "Operator": 9,  # PredicateOperator.Contains
                    "Condition": 1,  # PredicateCondition.And
                    "IgnoreCase": True,
                    "IsComplex": False,
                    "Value": {
                        "StringValue": args.name,
                        "TypeCode": 18,
                        "TypeName": "System.String",
                        "IsEnum": False,
                    },
                }
            ]
        }

    result = client.post("Project/GetProjects", payload)
    print_result(result)


if __name__ == "__main__":
    main()
