# Python Web API Samples

This directory contains Python examples for interacting with the LeegooBuilder Web API using JSON requests and responses. The script numbering mirrors the PowerShell samples in [Powershell/Readme.md](../Powershell/Readme.md) so both sets remain comparable.

All commands in this document are run from this directory (`Examples/Python`).

## Prerequisites

- Python 3.10 or higher
- Install dependencies:

```bash
pip install -r requirements.txt
```

## Configuration

Copy [config.example.json](config.example.json) to `config.json` in this directory:

```bash
cp config.example.json config.json
```

`config.json` is gitignored so credentials and local settings are never committed.

| Property | Default | Description |
| --- | --- | --- |
| `apiUrl` | `http://localhost:56540/api/` | Base URL of the LeegooBuilder Web API |
| `username` | `YourUsername` | Login username |
| `password` | `YourPassword` | Login password |
| `culture` | `de-DE` | Login culture |
| `language` | `de-DE` | Login language |
| `tokenCachePath` | `.token_cache.json` | Path to local cached token file |

If `config.json` does not exist, the built-in fallbacks in `lbapi/config.py` are used instead; they match the placeholder values above.

All endpoint scripts also accept command-line arguments (such as `--api-url`) to override configuration settings.

## TokenManager

The shared `TokenManager` class in [lbapi/token_manager.py](lbapi/token_manager.py) manages authentication:

1. **Cache lookup**: Checks `.token_cache.json` for a previously saved access token matching the target API URL and username.
2. **Token validation**: Validates the cached token against `GET /api/Authentication/Validate`.
3. **Token renewal**: If validation fails, attempts renewal via `POST /api/Authentication/RenewToken`.
4. **Fallback login**: If renewal is unavailable or fails, performs a full `POST /api/Authentication/Login` and caches the new token.
5. **Auto-refresh**: When the API returns error code 10 (`NotLoggedIn`), 20 (`TokenInvalid`), or 80 (`TokenExpired`), the client automatically refreshes the token and retries the request once.

> **Security Notice**: Storing credentials in plain-text configuration files and access tokens in local cache files is intended for development and demonstration purposes only. In production environments, replace credentials with environment variables, secrets managers, or credential vaults.

> **Note for Customers**: This `TokenManager` is an example implementation. Customers may replace or adapt it to integrate with their identity provider, OAuth2/OIDC infrastructure, or enterprise credential storage.

## JSON Endpoints Only

All scripts exclusively use JSON:
- `Accept: application/json`
- `Content-Type: application/json`

Endpoints requiring binary payloads or protobuf formats (such as ImportExport) are not included in this Python suite.

## Script Overview

### Authentication

| Script | Endpoint | Arguments | Description |
| --- | --- | --- | --- |
| [Authentication/100.login.py](Authentication/100.login.py) | `Authentication/Login` | `--api-url`, `--username`, `--password`, `--culture`, `--language` | Authenticates via `TokenManager`, prints user details and token expiration |
| [Authentication/110.load_login_infos.py](Authentication/110.load_login_infos.py) | `Authentication/LoadLoginInfos` | `--api-url` | Anonymous request returning available cultures and languages |

### Projects

| Script | Endpoint | Arguments | Description |
| --- | --- | --- | --- |
| [Project/200.get_projects.py](Project/200.get_projects.py) | `Project/GetProjects` | `--name`, `--api-url` | Retrieves project list; `--name` filters description via `QuerySettings.Where` `Contains` |
| [Project/220.get_project.py](Project/220.get_project.py) | `Project/GetProject` | `--project-id`, `--include-companies-and-persons`, `--include-custom-definition-values`, `--api-url` | Loads project by internal GUID; defaults to first project from `GetProjects` |

### Proposals

| Script | Endpoint | Arguments | Description |
| --- | --- | --- | --- |
| [Proposal/210.get_proposals.py](Proposal/210.get_proposals.py) | `Proposal/GetProposals` | `--project-id`, `--api-url` | Retrieves proposals; filters by internal project GUID (`InternalProjectID`) or loads all proposals |
| [Proposal/230.get_proposal.py](Proposal/230.get_proposal.py) | `Proposal/GetProposal` | `--proposal-id`, `--include-custom-definition-values`, `--include-companies-and-persons`, `--api-url` | Loads proposal by internal GUID; defaults to first proposal from `GetProposals` |

### Companies & Persons

| Script | Endpoint | Arguments | Description |
| --- | --- | --- | --- |
| [CompaniesAndPersons/300.load_company.py](CompaniesAndPersons/300.load_company.py) | `CompaniesAndPersons/LoadCompany` | `--id` (required), `--api-url` | Loads a single company by internal company GUID |
| [CompaniesAndPersons/310.load_companies.py](CompaniesAndPersons/310.load_companies.py) | `CompaniesAndPersons/LoadCompanies` | `--name` (default: `gmbh`), `--api-url` | Searches companies by name |
| [CompaniesAndPersons/350.create_company.py](CompaniesAndPersons/350.create_company.py) | `InitCompany`, `SaveCompany` | `--name`, `--company-id`, `--api-url` | Initializes empty company model and saves with `SaveDataMode = 10` (Insert) |
| [CompaniesAndPersons/360.modify_company.py](CompaniesAndPersons/360.modify_company.py) | `LoadCompany`, `SaveCompany` | `--id` or `--json-file` (required), `--name`, `--api-url` | Loads company, updates fields, and saves with `SaveDataMode = 20` (Update) |
| [CompaniesAndPersons/400.load_person.py](CompaniesAndPersons/400.load_person.py) | `CompaniesAndPersons/LoadPerson` | `--id` (required), `--api-url` | Loads a single person by internal person GUID |
| [CompaniesAndPersons/410.load_persons.py](CompaniesAndPersons/410.load_persons.py) | `CompaniesAndPersons/LoadPersons` | `--company-id` (required), `--api-url` | Loads all persons belonging to a company |
| [CompaniesAndPersons/450.create_person.py](CompaniesAndPersons/450.create_person.py) | `InitPerson`, `SavePerson` | `--company-id` (required), `--name`, `--person-id`, `--api-url` | Initializes person for company and saves with `SaveDataMode = 10` (Insert) |
| [CompaniesAndPersons/460.modify_person.py](CompaniesAndPersons/460.modify_person.py) | `LoadPerson`, `SavePerson` | `--id` or `--json-file` (required), `--name`, `--api-url` | Loads person, updates fields, and saves with `SaveDataMode = 20` (Update) |

## Chaining Examples

### Create Company and Add a Contact Person

```bash
# 1. Create a company
python CompaniesAndPersons/350.create_company.py --name "Acme Corp" --company-id "ACME001"

# 2. Use the returned internalCompanyID to create a person
python CompaniesAndPersons/450.create_person.py --company-id "<internalCompanyID>" --name "John Doe"

# 3. Verify the person is listed under the company
python CompaniesAndPersons/410.load_persons.py --company-id "<internalCompanyID>"
```

### Load and Modify an Existing Company

```bash
# 1. Search for a company
python CompaniesAndPersons/310.load_companies.py --name "Acme"

# 2. Modify company name
python CompaniesAndPersons/360.modify_company.py --id "<internalCompanyID>" --name "Acme Corporation International"

# 3. Reload company to verify changes
python CompaniesAndPersons/300.load_company.py --id "<internalCompanyID>"
```

## Projects Viewer UI

An interactive desktop application built with `tkinter` is located in [UI/projects_viewer.py](UI/projects_viewer.py).

To start the viewer:

```bash
python UI/projects_viewer.py
```

Features:
- "Load Projects" button to fetch projects using `TokenManager` and `LbApiClient`.
- Asynchronous background request to keep the UI responsive.
- Displays `ProjectID`, `Description`, `InternalProjectID`, and `IsFavorite` in a `ttk.Treeview`.
- Displays API errors in error dialogs.

## API Documentation

For full details on API endpoints, parameter structures, and response shapes, refer to:
- [Docs/README.md](../../Docs/README.md)
- [Docs/Authentication/Login.md](../../Docs/Authentication/Login.md)
- [Docs/Project/GetProjects.md](../../Docs/Project/GetProjects.md)
- [Docs/Project/GetProject.md](../../Docs/Project/GetProject.md)
- [Docs/Proposal/GetProposals.md](../../Docs/Proposal/GetProposals.md)
- [Docs/Proposal/GetProposal.md](../../Docs/Proposal/GetProposal.md)
- [Docs/Common/QuerySettings.md](../../Docs/Common/QuerySettings.md)
- [Docs/Common/OperationResult.md](../../Docs/Common/OperationResult.md)
