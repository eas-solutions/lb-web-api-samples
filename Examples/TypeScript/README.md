# TypeScript / Node.js examples for LeegooBuilder Web API

This directory contains dependency-light, idiomatic TypeScript sample code for interacting with the **LEEGOO BUILDER G3 Web API**.

All examples use native Node.js 20+ `fetch` and execute directly with `tsx` (`npx tsx <script>.ts`).

> **JSON-Only Communication:**  
> These examples exclusively request and process JSON payloads (`Content-Type: application/json` and `Accept: application/json`). No protobuf, binary, or custom serialization formats are required.

---

## Table of contents

- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Configuration and credentials](#configuration-and-credentials)
  - [1. JSON Configuration File (Recommended)](#1-json-configuration-file-recommended)
  - [2. Command-Line Arguments](#2-command-line-arguments)
  - [3. Environment Variables or .env](#3-environment-variables-or-env)
  - [Precedence Order](#precedence-order)
- [Authentication and TokenManager reference](#authentication-and-tokenmanager-reference)
- [Project structure](#project-structure)
- [Sample scripts](#sample-scripts)
  - [Authentication](#authentication)
  - [Project](#project)
  - [Proposal](#proposal)
  - [Companies and persons](#companies-and-persons)
- [Verified against demo API](#verified-against-demo-api)

---

## Prerequisites

- **Node.js** 20.0.0 or later (`node -v`)
- **npm** (`npm -v`)

---

## Quick start

1. Open a terminal in this directory (`Examples/TypeScript`).
2. Install dev dependencies:
   ```bash
   npm install
   ```
3. Run any script with `npx tsx`:
   ```bash
   npx tsx Authentication/Login.ts
   npx tsx Project/GetProjects.ts --take 5
   ```
4. Verify types:
   ```bash
   npm run typecheck
   ```

---

## Configuration and credentials

You can configure the API endpoint URL, login credentials, language, and culture using any of the following methods:

### 1. JSON Configuration File (Recommended)

Copy the provided `lb-config.example.json` to `lb-config.local.json` or `lb-config.json`:

```bash
# In Examples/TypeScript:
cp lb-config.example.json lb-config.local.json
```

Edit the file with your credentials and preferences:

```json
{
  "apiUrl": "http://localhost:56540/api",
  "username": "Administrator",
  "password": "admin",
  "language": "en-GB",
  "culture": "en-GB"
}
```

Both `lb-config.local.json` and `lb-config.json` (as well as `.env`) are ignored in Git so your credentials will not be committed.

You can also specify a custom config file path on any script:
```bash
npx tsx Authentication/Login.ts --config /path/to/custom-config.json
```

### 2. Command-Line Arguments

All scripts accept connection and authentication flags directly:

| Option | Description |
| --- | --- |
| `--config <path>` | Path to JSON config file |
| `--api-url <url>` | API base URL |
| `--username <string>` | Username for authentication |
| `--password <string>` | Password for authentication |
| `--language <string>` | Language code (e.g. `en-GB`, `de-DE`) |
| `--culture <string>` | Culture code (e.g. `en-GB`, `de-DE`) |

Example:
```bash
npx tsx Authentication/Login.ts --username Administrator --password admin --language de-DE --culture de-DE
```

### 3. Environment Variables or .env

You can set environment variables or place them in a `.env` file (loaded automatically by Node 20+):

| Variable | Default value | Description |
| --- | --- | --- |
| `LB_API_URL` | `http://localhost:56540/api` | Base URL of the LeegooBuilder Web API |
| `LB_USERNAME` | `Administrator` | Username for authentication |
| `LB_PASSWORD` | `admin` | Password for authentication |
| `LB_LANGUAGE` | `en-GB` | Interface language code (must match `SPRACHE_IF`) |
| `LB_CULTURE` | `en-GB` | Regional culture code |
| `LB_CONFIG_FILE` | *(none)* | Optional path to custom config JSON file |

PowerShell example:
```powershell
$env:LB_USERNAME = "Administrator"
$env:LB_PASSWORD = "admin"
npx tsx Project/GetProjects.ts
```

### Precedence Order

When multiple configuration sources exist, settings are resolved using this hierarchy (highest priority first):
1. **Command-line flags** (`--api-url`, `--username`, `--password`, etc.) or programmatic overrides
2. **Environment variables** (`LB_API_URL`, `LB_USERNAME`, `LB_PASSWORD`, etc.)
3. **Configuration file** (`lb-config.local.json`, `lb-config.json`, or `--config <path>`)
4. **Default fallbacks** (`http://localhost:56540/api`, `Administrator`, `admin`, `en-GB`, `en-GB`)

---

## Authentication and TokenManager reference

Authentication against the LeegooBuilder Web API is handled by the `TokenManager` class (`lbapi/tokenManager.ts`).

> **Reference implementation notice:**  
> `TokenManager` is provided as a **usable reference example**. Customers and integrating applications may implement or adapt it according to their own requirements (for example, storing tokens in distributed caches such as Redis, using secure secret vaults, or integrating with corporate single sign-on).

Key features of the reference `TokenManager`:
- **Lazy acquisition:** Obtains a Bearer token only when an authenticated API call is first made.
- **In-flight request deduplication:** Concurrent calls share the same in-flight login promise, avoiding duplicate login requests.
- **In-memory token caching with proactive refresh:** Decodes the JWT `exp` timestamp and proactively re-authenticates if fewer than 60 seconds remain.
- **Cache invalidation:** Exposes `invalidate()`, allowing the client (`LbClient`) to clear the cached token and retry automatically upon receiving an HTTP 401 or an application `OperationFailType` of `NotLoggedIn` (10), `TokenInvalid` (20), or `TokenExpired` (80).
- **Token masking:** Helper utility `maskToken()` masks tokens by default in console outputs to prevent accidental credential leakage in logs.

---

## Project structure

```
Examples/TypeScript/
├── package.json               # ESM module package definition and scripts
├── tsconfig.json              # Strict TypeScript configuration (NodeNext)
├── README.md                  # This documentation
├── lbapi/                     # Shared client and helper library
│   ├── index.ts               # Re-exports all shared utilities
│   ├── config.ts              # Environment variable configuration resolver
│   ├── types.ts               # TypeScript interfaces, contracts, and numeric enums
│   ├── errors.ts              # ApiError class with OperationResult details
│   ├── tokenManager.ts        # Reference TokenManager implementation
│   ├── client.ts              # JSON HTTP client with automatic auth & retry
│   ├── output.ts              # Pretty-printing JSON formatter with list compression
│   └── args.ts                # CLI argument parsing utilities
├── Authentication/
│   └── Login.ts               # Authenticates and displays user claims
├── Project/
│   ├── GetProjects.ts         # Retrieves and filters projects list
│   └── GetProject.ts          # Loads a single project by internal GUID
├── Proposal/
│   ├── GetProposals.ts        # Retrieves proposals for a project
│   └── GetProposal.ts         # Loads a single proposal by internal GUID
└── CompaniesAndPersons/
    ├── LoadCompanies.ts       # Queries companies with name/paging filters
    ├── LoadPersons.ts         # Queries persons with company/name/active filters
    ├── SaveCompany.ts         # Initializes and saves (Insert/Update) a company
    └── SavePerson.ts          # Initializes and saves (Insert/Update) a person
```

---

## Sample scripts

### Authentication

#### Login
Authenticates using the configured credentials and prints the user profile with the token masked.

```bash
# Masked token output (default):
npx tsx Authentication/Login.ts

# Display unmasked token:
npx tsx Authentication/Login.ts --show-token
```

---

### Project

#### GetProjects
Retrieves projects accessible to the authenticated user. Supports filtering by description and paging.

```bash
# Retrieve first 5 projects:
npx tsx Project/GetProjects.ts --take 5

# Filter projects by description (case-insensitive substring):
npx tsx Project/GetProjects.ts --name "Demo"

# Paging with skip and take:
npx tsx Project/GetProjects.ts --skip 5 --take 5
```

#### GetProject
Retrieves full details for a single project by its internal GUID.

```bash
npx tsx Project/GetProject.ts --internal-project-id 9897f980-1b7d-ed11-81d0-f2b3bff92a45

# Include related companies/persons and custom definition values:
npx tsx Project/GetProject.ts \
  --internal-project-id 9897f980-1b7d-ed11-81d0-f2b3bff92a45 \
  --include-companies-and-persons \
  --include-custom-definition-values
```

---

### Proposal

#### GetProposals
Retrieves proposals associated with a specific project.

```bash
npx tsx Proposal/GetProposals.ts --internal-project-id 9897f980-1b7d-ed11-81d0-f2b3bff92a45

# With paging:
npx tsx Proposal/GetProposals.ts \
  --internal-project-id 9897f980-1b7d-ed11-81d0-f2b3bff92a45 \
  --take 10
```

#### GetProposal
Retrieves a single proposal by its internal GUID.

```bash
npx tsx Proposal/GetProposal.ts --internal-proposal-id 68cac5d3-1c7d-ed11-81d0-f2b3bff92a45

# Include custom definitions and related parties:
npx tsx Proposal/GetProposal.ts \
  --internal-proposal-id 68cac5d3-1c7d-ed11-81d0-f2b3bff92a45 \
  --include-custom-definition-values \
  --include-companies-and-persons
```

---

### Companies and persons

#### LoadCompanies
Queries companies with optional filters for company name, company ID, and paging.

```bash
# Load up to 10 companies:
npx tsx CompaniesAndPersons/LoadCompanies.ts --take 10

# Filter companies by name:
npx tsx CompaniesAndPersons/LoadCompanies.ts --name "EAS"
```

#### LoadPersons
Queries persons with optional filters for internal company ID, person name, active-only flag, and paging.

```bash
# Load active persons only:
npx tsx CompaniesAndPersons/LoadPersons.ts --only-active --take 10

# Filter by parent company:
npx tsx CompaniesAndPersons/LoadPersons.ts --internal-company-id 8f5266be-8668-e711-849f-005056c00008
```

#### SaveCompany
Initializes default values via `POST /api/CompaniesAndPersons/InitCompany` and saves the company with `SaveDataMode.Insert` (10). Also supports `SaveDataMode.Update` (20) when `--internal-company-id` is provided.

```bash
# Create a new company (Insert mode):
npx tsx CompaniesAndPersons/SaveCompany.ts --name "ACME Industrial Corp"

# Update an existing company (Update mode):
npx tsx CompaniesAndPersons/SaveCompany.ts \
  --internal-company-id <GUID> \
  --name "ACME Industrial Corp (Europe)"
```

#### SavePerson
Initializes defaults for a company via `POST /api/CompaniesAndPersons/InitPerson`, populates person fields, sets `IsActive = 1`, and saves with `SaveDataMode.Insert` (10). Also supports `SaveDataMode.Update` (20) when `--internal-person-id` is provided.

```bash
# Create a person under an existing company (Insert mode):
npx tsx CompaniesAndPersons/SavePerson.ts \
  --internal-company-id <GUID> \
  --first-name "Jane" \
  --name "Doe"

# Update an existing person (Update mode):
npx tsx CompaniesAndPersons/SavePerson.ts \
  --internal-person-id <GUID> \
  --first-name "Janet"
```

---

## Verified against demo API

All sample scripts were verified against the local development instance at `http://localhost:56540` using the standard `Administrator` / `admin` account:

| Script | Command | Result |
| --- | --- | --- |
| `Authentication/Login.ts` | `npx tsx Authentication/Login.ts` | HTTP 200, `successful: true`, masked token returned |
| `Authentication/Login.ts` | `npx tsx Authentication/Login.ts --show-token` | HTTP 200, full unmasked JWT token displayed |
| `Project/GetProjects.ts` | `npx tsx Project/GetProjects.ts --take 2` | HTTP 200, returned 2 projects, total records reported |
| `Project/GetProjects.ts` | `npx tsx Project/GetProjects.ts --name "Demobelege"` | HTTP 200, filtered project returned |
| `Project/GetProject.ts` | `npx tsx Project/GetProject.ts --internal-project-id 9897f980-1b7d-ed11-81d0-f2b3bff92a45` | HTTP 200, returned project details |
| `Proposal/GetProposals.ts` | `npx tsx Proposal/GetProposals.ts --internal-project-id 9897f980-1b7d-ed11-81d0-f2b3bff92a45` | HTTP 200, returned proposal list |
| `Proposal/GetProposal.ts` | `npx tsx Proposal/GetProposal.ts --internal-proposal-id 68cac5d3-1c7d-ed11-81d0-f2b3bff92a45` | HTTP 200, returned proposal details |
| `CompaniesAndPersons/LoadCompanies.ts` | `npx tsx CompaniesAndPersons/LoadCompanies.ts --name "EAS North"` | HTTP 200, returned matched company item |
| `CompaniesAndPersons/LoadPersons.ts` | `npx tsx CompaniesAndPersons/LoadPersons.ts --only-active --take 2` | HTTP 200, returned 2 active persons |
| `CompaniesAndPersons/SaveCompany.ts` | `npx tsx CompaniesAndPersons/SaveCompany.ts --name "TS Sample Company"` | HTTP 200, initialized and saved new company (`Insert`) |
| `CompaniesAndPersons/SaveCompany.ts` | `npx tsx CompaniesAndPersons/SaveCompany.ts --internal-company-id <GUID> --name "TS Sample Company Updated"` | HTTP 200, updated existing company (`Update`) |
| `CompaniesAndPersons/SavePerson.ts` | `npx tsx CompaniesAndPersons/SavePerson.ts --internal-company-id <GUID> --first-name Alice --name Smith` | HTTP 200, initialized and saved person (`Insert`) |
| `CompaniesAndPersons/SavePerson.ts` | `npx tsx CompaniesAndPersons/SavePerson.ts --internal-person-id <GUID> --first-name "Alice Updated"` | HTTP 200, updated existing person (`Update`) |
| Validation / Error Handling | Missing required GUID arguments (`--internal-project-id`, `--internal-company-id`, etc.) | Process exits with code 1 and error message |
