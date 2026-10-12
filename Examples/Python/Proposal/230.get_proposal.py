"""Retrieve a single proposal by its internal GUID."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

# Bootstrap lbapi package from parent directory
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lbapi import LbApiClient, load_config, print_result


def main() -> None:
    parser = argparse.ArgumentParser(description="Get a single proposal from LeegooBuilder Web API.")
    parser.add_argument("--proposal-id", help="Internal proposal GUID (defaults to first proposal from GetProposals)")
    parser.add_argument(
        "--include-custom-definition-values",
        action="store_true",
        default=False,
        help="Include custom definition values (default: False)",
    )
    parser.add_argument(
        "--include-companies-and-persons",
        action="store_true",
        default=False,
        help="Include related companies and persons (default: False)",
    )
    parser.add_argument("--api-url", help="Base URL of the Web API")
    args = parser.parse_args()

    config = load_config()
    if args.api_url:
        config.api_url = args.api_url

    client = LbApiClient(config)
    proposal_id = args.proposal_id

    if not proposal_id:
        proposals_result = client.post(
            "Proposal/GetProposals",
            {"Content": [20], "LoadOptions": [10], "LoadAllProposals": True},
        )
        proposals = proposals_result.get("proposals") or []
        if not proposals:
            raise RuntimeError("No proposals found to select default proposal ID.")
        proposal_id = proposals[0].get("internalProposalID")
        if not proposal_id:
            raise RuntimeError("First proposal has no internalProposalID.")

    payload = {
        "ProposalId": proposal_id,
        "IncludeCustomDefinitionValues": args.include_custom_definition_values,
        "IncludeCompaniesAndPersons": args.include_companies_and_persons,
    }

    result = client.post("Proposal/GetProposal", payload)
    print_result(result)


if __name__ == "__main__":
    main()
