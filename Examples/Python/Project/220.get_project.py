"""Retrieve a single project by its internal GUID."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

# Bootstrap lbapi package from parent directory
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lbapi import LbApiClient, load_config, print_result


def main() -> None:
    parser = argparse.ArgumentParser(description="Get a single project from LeegooBuilder Web API.")
    parser.add_argument("--project-id", help="Internal project GUID (defaults to first project from GetProjects)")
    parser.add_argument(
        "--include-companies-and-persons",
        action="store_true",
        default=False,
        help="Include related companies, persons, and users",
    )
    parser.add_argument(
        "--include-custom-definition-values",
        action="store_true",
        default=False,
        help="Include custom definition values",
    )
    parser.add_argument("--api-url", help="Base URL of the Web API")
    args = parser.parse_args()

    config = load_config()
    if args.api_url:
        config.api_url = args.api_url

    client = LbApiClient(config)
    project_id = args.project_id

    if not project_id:
        # Load first project from GetProjects
        projects_result = client.post("Project/GetProjects", {"ProjectsContent": [10]})
        projects = projects_result.get("projects") or []
        if not projects:
            raise RuntimeError("No projects found to select default project ID.")
        project_id = projects[0].get("internalProjectID")
        if not project_id:
            raise RuntimeError("First project has no internalProjectID.")

    payload = {
        "ProjectId": project_id,
        "IncludeCompaniesAndPersons": args.include_companies_and_persons,
        "IncludeCustomDefinitionValues": args.include_custom_definition_values,
    }

    result = client.post("Project/GetProject", payload)
    print_result(result)


if __name__ == "__main__":
    main()
