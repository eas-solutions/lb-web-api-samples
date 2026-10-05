# Python Web API Samples

This directory contains Python examples for interacting with the LeegooBuilder Web API using JSON requests and responses. The script numbering mirrors the PowerShell samples in [Examples/Powershell/Readme.md](Examples/Powershell/Readme.md) so both sets remain comparable.

## Prerequisites

- Python 3.10 or higher
- Install dependencies:

```bash
pip install -r requirements.txt
```

## Configuration

Copy [Examples/Python/config.example.json](Examples/Python/config.example.json) to `config.json` in this directory:

```bash
cp config.example.json config.json
```

`config.json` is gitignored so credentials and local settings are never committed.

| Property | Default | Description |
| --- | --- | --- |
| `apiUrl` | `http://localhost:56540/api/` | Base URL of the LeegooBuilder Web API |
| `username` | `Administrator` | Login username |
| `password` | `admin` | Login password |
| `culture` | `de-DE` | Login culture |
| `language` | `de-DE` | Login language |
| `tokenCachePath` | `.token_cache.json` | Path to local cached token file |

All endpoint scripts also accept command-line arguments (such as `--api-url`) to override configuration settings.

## TokenManager

The shared `TokenManager` class in [Examples/Python/lbapi/token_manager.py](Examples/Python/lbapi/token_manager.py) manages authentication:

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
| [Examples/Python/Authentication/100.login.py](Examples/Python/Authentication/100.login.py) | `Authentication/Login` | `--api-url`, `--username`, `--password`, `--culture`, `--language` | Authenticates via `TokenManager`, prints user details and token expiration |
| [Examples/Python/Authentication/110.load_login_infos.py](Examples/Python/Authentication/110.load_login_infos.py) | `Authentication/LoadLoginInfos` | `--api-url` | Anonymous request returning available cultures and languages |

### Projects

| Script | Endpoint | Arguments | Description |
| --- | --- | --- | --- |
| [Examples/Python/Project/200.get_projects.py](Examples/Python/Project/200.get_projects.py) | `Project/GetProjects` | `--name`, `--api-url` | Retrieves project list; `--name` filters description via `QuerySettings.Where` `Contains` |
| [Examples/Python/Project/220.get_project.py](Examples/Python/Project/220.get_project.py) | `Project/GetProject` | `--project-id`, `--include-companies-and-persons`, `--include-custom-definition-values`, `--api-url` | Loads project by internal GUID; defaults to first project from `GetProjects` |

### Proposals

| Script | Endpoint | Arguments | Description |
| --- | --- | --- | --- |
| [Examples/Python/Proposal/210.get_proposals.py](Examples/Python/Proposal/210.get_proposals.py) | `Proposal/GetProposals` | `--project-id`, `--api-url` | Retrieves proposals; filters by project ID or loads all proposals |
| [Examples/Python/Proposal/230.get_proposal.py](Examples/Python/Proposal/230.get_proposal.py) | `Proposal/GetProposal` | `--proposal-id`, `--include-custom-definition-values`, `--include-companies-and-persons`, `--api-url` | Loads proposal by internal GUID; defaults to first proposal from `GetProposals` |

### Companies & Persons

| Script | Endpoint | Arguments | Description |
| --- | --- | --- | --- |
| [Examples/Python/CompaniesAndPersons/300.load_company.py](Examples/Python/CompaniesAndPersons/300.load_company.py) | `CompaniesAndPersons/LoadCompany` | `--id` (required), `--api-url` | Loads a single company by internal company GUID |
| [Examples/Python/CompaniesAndPersons/310.load_companies.py](Examples/Python/CompaniesAndPersons/310.load_companies.py) | `CompaniesAndPersons/LoadCompanies` | `--name` (default: `gmbh`), `--api-url` | Searches companies by name |
| [Examples/Python/CompaniesAndPersons/350.create_company.py](Examples/Python/CompaniesAndPersons/350.create_company.py) | `InitCompany`, `SaveCompany` | `--name`, `--company-id`, `--api-url` | Initializes empty company model and saves with `SaveDataMode = 10` (Insert) |
| [Examples/Python/CompaniesAndPersons/360.modify_company.py](Examples/Python/CompaniesAndPersons/360.modify_company.py) | `LoadCompany`, `SaveCompany` | `--id` or `--json-file` (required), `--name`, `--api-url` | Loads company, updates fields, and saves with `SaveDataMode = 20` (Update) |
| [Examples/Python/CompaniesAndPersons/400.load_person.py](Examples/Python/CompaniesAndPersons/400.load_person.py) | `CompaniesAndPersons/LoadPerson` | `--id` (required), `--api-url` | Loads a single person by internal person GUID |
| [Examples/Python/CompaniesAndPersons/410.load_persons.py](Examples/Python/CompaniesAndPersons/410.load_persons.py) | `CompaniesAndPersons/LoadPersons` | `--company-id` (required), `--api-url` | Loads all persons belonging to a company |
| [Examples/Python/CompaniesAndPersons/450.create_person.py](Examples/Python/CompaniesAndPersons/450.create_person.py) | `InitPerson`, `SavePerson` | `--company-id` (required), `--name`, `--person-id`, `--api-url` | Initializes person for company and saves with `SaveDataMode = 10` (Insert) |
| [Examples/Python/CompaniesAndPersons/460.modify_person.py](Examples/Python/CompaniesAndPersons/460.modify_person.py) | `LoadPerson`, `SavePerson` | `--id` or `--json-file` (required), `--name`, `--api-url` | Loads person, updates fields, and saves with `SaveDataMode = 20` (Update) |

## Chaining Examples

### Create Company and Add a Contact Person

```bash
# 1. Create a company
python Examples/Python/CompaniesAndPersons/350.create_company.py --name "Acme Corp" --company-id "ACME001"

# 2. Use the returned internalCompanyID to create a person
python Examples/Python/CompaniesAndPersons/450.create_person.py --company-id "<internalCompanyID>" --name "John Doe"

# 3. Verify the person is listed under the company
python Examples/Python/CompaniesAndPersons/410.load_persons.py --company-id "<internalCompanyID>"
```

### Load and Modify an Existing Company

```bash
# 1. Search for a company
python Examples/Python/CompaniesAndPersons/310.load_companies.py --name "Acme"

# 2. Modify company name
python Examples/Python/CompaniesAndPersons/360.modify_company.py --id "<internalCompanyID>" --name "Acme Corporation International"

# 3. Reload company to verify changes
python Examples/Python/CompaniesAndPersons/300.load_company.py --id "<internalCompanyID>"
```

## Projects Viewer UI

An interactive desktop application built with `tkinter` is located in [Examples/Python/UI/projects_viewer.py](Examples/Python/UI/projects_viewer.py).

To start the viewer:

```bash
python Examples/Python/UI/projects_viewer.py
```

Features:
- "Load Projects" button to fetch projects using `TokenManager` and `LbApiClient`.
- Asynchronous background request to keep the UI responsive.
- Displays `ProjectID`, `Description`, `InternalProjectID`, and `IsFavorite` in a `ttk.Treeview`.
- Displays API errors in error dialogs.

## API Documentation

For full details on API endpoints, parameter structures, and response shapes, refer to:
- [Docs/README.md](Docs/README.md)
- [Docs/Authentication/Login.md](Docs/Authentication/Login.md)
- [Docs/Project/GetProjects.md](Docs/Project/GetProjects.md)
- [Docs/Project/GetProject.md](Docs/Project/GetProject.md)
- [Docs/Proposal/GetProposals.md](Docs/Proposal/GetProposals.md)
- [Docs/Proposal/GetProposal.md](Docs/Proposal/GetProposal.md)
- [Docs/Common/QuerySettings.md](Docs/Common/QuerySettings.md)
- [Docs/Common/OperationResult.md](Docs/Common/OperationResult.md)
