"""Retrieve proposals list from LeegooBuilder Web API."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

# Bootstrap lbapi package from parent directory
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lbapi import LbApiClient, load_config, print_result


def main() -> None:
    parser = argparse.ArgumentParser(description="Get proposals from LeegooBuilder Web API.")
    parser.add_argument("--project-id", help="Optional internal project GUID filter")
    parser.add_argument("--api-url", help="Base URL of the Web API")
    args = parser.parse_args()

    config = load_config()
    if args.api_url:
        config.api_url = args.api_url

    client = LbApiClient(config)

    payload: dict = {
        "Content": [20],  # GetProposalsContent.Proposals
        "LoadOptions": [10],  # ProposalLoadType.AllProposals
    }

    if args.project_id:
        payload["ProjectId"] = args.project_id
    else:
        payload["LoadAllProposals"] = True

    result = client.post("Proposal/GetProposals", payload)
    print_result(result)


if __name__ == "__main__":
    main()
