## Plan: Python Web API Samples (T10143)

Add Python examples in `Examples/Python` that call the LeegooBuilder Web API using JSON only. There will be one folder per controller with one script per endpoint. The scripts share a small `lbapi` helper package that contains the `TokenManager`. A separate tkinter UI shows the GetProjects result. Script numbering follows the existing PowerShell set in [Examples/Powershell](Examples/Powershell) so the two languages stay comparable.

Local demo credentials for validation are `Administrator` // `admin`. They are development credentials only and must not be written to committed configuration files, logs, tests, or documentation beyond this local validation note.

**Steps**

*Phase 0 – Check JSON support against the running API (blocks the later phases)*
1. Check that `http://localhost:56540/api/` returns JSON for `Authentication/Login` and `Project/GetProjects` when `Accept: application/json` and `Content-Type: application/json` are sent.
   - The docs show camelCase JSON responses, but a source scan of [Program.cs](lb-web/EAS.LeegooBuilder.Web.WebApiHost/Program.cs) only found protobuf formatters registered.
   - Also confirm that `GET /api/Authentication/Validate` and `POST /api/Authentication/RenewToken` behave as documented.

*Phase 1 – Shared foundation in `Examples/Python/lbapi/`*
2. `config.py`: reads `config.json` from the Python root and falls back to the PowerShell defaults:
   - ApiUrl `http://localhost:56540/api/`
   - Username `Administrator`, Password `admin`
   - Culture and Language `de-DE`
   - Token cache path

   Create `config.example.json` and commit it. Add `config.json` to `.gitignore`.
3. `token_manager.py` (`TokenManager`):
   - `get_token()` returns a valid token, either from the cache or by calling `Login`.
   - Persists the access token and the renewal token in a local cache file, which is gitignored.
   - Validates a cached token with `Authentication/Validate`, then tries `RenewToken` (`RenewalToken`, `ExpiredToken`), then falls back to a fresh login.
   - Re-logs in when ApiUrl or Username differ from the cached values.
   - The docstring states that it is an example that customers may replace or adapt.
4. `client.py` (`LbApiClient`):
   - One `post(path, body)` and one `get(path)` method using a `requests.Session`.
   - Always sends `Accept: application/json` and an `Authorization: Bearer` header taken from `TokenManager`.
   - Raises on HTTP errors.
   - When `operationResult.operationFailType` is 10, 20 or 80 (not logged in, token invalid, token expired), it refreshes the token once and retries.
5. `output.py`:
   - `print_result(response)` pretty-prints the JSON.
   - Failures are shown in red, mirroring `Write-LbApiResult.ps1`.
   - Lists with more than 5 items are printed one compact line per item.
6. Add `requirements.txt` (just `requests`).
7. Each script finds the `lbapi` package with a one-line `sys.path` bootstrap and takes its optional inputs through `argparse`.

*Phase 2 – Endpoint scripts (depends on Phase 1; the folders can be written in parallel)*

8. `Authentication/`:
   - `100.login.py`: logs in through `TokenManager` and prints the user and token expiry.
   - `110.load_login_infos.py`: anonymous `LoadLoginInfos` call.
9. `Project/`:
   - `200.get_projects.py`: `ProjectsContent: [10]`. An optional `--name` adds a `QuerySettings.Where` filter on `Description` with `Contains` (operator 9).
   - `220.get_project.py`: `--project-id` is the internal GUID. Without it, the script takes the first result of GetProjects. The include flags are optional.
10. `Proposal/`:
    - `210.get_proposals.py`: `Content: [20]`, `LoadOptions: [10]`. Uses `--project-id` if given, otherwise `LoadAllProposals: true`.
    - `230.get_proposal.py`: `--proposal-id`, otherwise the first result of GetProposals. `IncludeCustomDefinitionValues` is always sent because the endpoint requires it.
11. `CompaniesAndPersons/` (internal IDs are mandatory, as in PowerShell):
    - `300.load_company.py`: `InternalCompanyID`.
    - `310.load_companies.py`: `Name` filter, default `gmbh`.
    - `350.create_company.py`: `InitCompany`, then set `Name1` and `CompanyID`, then `SaveCompany` with `SaveDataMode: 10` (Insert).
    - `360.modify_company.py`: takes `--id` or `--json-file`, loads the company, applies the changes, then `SaveCompany` with `SaveDataMode: 20` (Update).
    - `400.load_person.py`: `InternalPersonID`.
    - `410.load_persons.py`: `CompanyID`.
    - `450.create_person.py`: `InitPerson` with `InternalCompanyID`, then set `Name`, `PersonID` and `IsActive=1`, then `SavePerson` with mode 10.
    - `460.modify_person.py`: load the person, change it, then `SavePerson` with mode 20.
    - Responses are camelCase. Each script sends the entity it received back unchanged apart from the edited fields; Phase 0 must confirm the API accepts this, otherwise the scripts convert keys to PascalCase first.

*Phase 3 – UI (depends on Phase 1; can run in parallel with Phase 2)*

12. `UI/projects_viewer.py`: a tkinter window with a Load button and a `ttk.Treeview` showing ProjectID, Description, InternalProjectID and IsFavorite. It reuses `TokenManager` and the client, runs the request off the UI thread, and shows errors in a message box.

*Phase 4 – Documentation (depends on Phases 2 and 3)*

13. `Examples/Python/README.md` is the entry point. It covers:
    - Prerequisites (Python 3.10+, `pip install -r requirements.txt`).
    - Setting up `config.json`.
    - A section on the TokenManager: what it does, its cache file, a security note about plain-text credentials and the cached token, and an explicit statement that it is a usable example that customers may implement or adapt.
    - A note that only JSON is requested, so binary endpoints such as ImportExport are left out.
    - A per-folder script table with endpoint, arguments and defaults.
    - Chaining examples (load → modify).
    - How to start the UI.
    - Links to [Docs](Docs).
14. Root [README.md](README.md): add a link to `Examples/Python/README.md` next to the PowerShell link.

*Phase 5 – Testing and completion validation (required; depends on Phases 1–4)*

15. Add tests for every created task and sample. Shared components must have focused unit tests, every endpoint script must have a request/response smoke test, and the tkinter UI must have a launch/load validation. Tests must cover successful JSON responses, failed `OperationResult` responses, authentication, token reuse, token renewal or re-login, request payloads, JSON-only headers, and the create/modify flows.
16. Run the complete test suite against the local API using the demo credentials `Administrator` // `admin`. Validate every created script and UI task, not only the shared helper package. Do not mark the task complete until all created tests pass and all created samples have been validated working against the running API.

**Relevant files**
- `Examples/Python/**`: all new.
- `Examples/Python/tests/**`: tests for every created shared component, endpoint script, and UI task.
- [Examples/Powershell](Examples/Powershell): reference only, for numbering, defaults and the flow in `350`/`360`/`450`/`460`. [ImportAndLogin.ps1](Examples/Powershell/ImportAndLogin.ps1) for the token reuse logic, [Write-LbApiResult.ps1](Examples/Powershell/Helpers/Write-LbApiResult.ps1) for the output style.
- [Docs/Authentication/Login.md](Docs/Authentication/Login.md), [Docs/Project](Docs/Project), [Docs/Proposal](Docs/Proposal), [Docs/Common](Docs/Common): request and response shapes and enum values.
- [CompaniesAndPersonsParameters.cs](lb-web/EAS.LeegooBuilder.Web.Contracts/Models/ParameterClasses/CompaniesAndPersons/CompaniesAndPersonsParameters.cs), [AuthenticationParameters.cs](lb-web/EAS.LeegooBuilder.Web.Contracts/Models/ParameterClasses/Authentication/AuthenticationParameters.cs): property names. Read only; `lb-web` is not modified.
- [README.md](README.md): add the link.
- `.gitignore` (root or `Examples/Python`): add `config.json`, the token cache file and `__pycache__/`.
- `requirements-dev.txt` or the project test dependency configuration: add the test runner and any test-only dependencies.

**Verification**
1. `python -m py_compile` on every `.py` file under `Examples/Python` finishes without errors.
2. Run the complete automated test suite. Every test created for a shared component, endpoint script, and UI task must pass.
3. Run each script against `localhost:56540` with the local demo credentials `Administrator` // `admin`, in order:
   - `100`, then `200` → `220`, then `210` → `230`.
   - `310`, `350`, `300` with the new ID, `360`.
   - `410`, `450`, `400`, `460`.

   Each one must print `successful: true` and JSON output.
4. Token behaviour:
   - A second run reuses the cached token, so no Login call is made.
   - A corrupted token in the cache leads to a renew or a fresh login.
   - Changing the Username in `config.json` forces a fresh login.
5. Start `UI/projects_viewer.py` and check that the projects appear in the table.
6. Check that the response `Content-Type` is `application/json` for every call, and that no binary or ImportExport endpoint is used.
7. Do not declare the task done until all created tests are validated working and every created sample has passed its live validation.
8. `git status` shows only `Examples/Python/**`, the README, tests, and `.gitignore` changes. No `config.json`, token cache or `lb-web` changes appear.

**Decisions**
- HTTP library: `requests`. UI: tkinter.
- Configuration: `config.json`, with `config.example.json` committed.
- Token: cached in a local file and renewed through `RenewToken` where possible; the cache and demo credentials remain local-only.
- Scope: mirrors the PowerShell set, including single loads and modify scripts. ImportExport and Scripting are left out because they use binary payloads or are outside the task.
- Before implementation proceeds, commit the prompt and plan, push the task branch, and create a draft pull request. `lb-web` stays untouched.

**Further Considerations**
1. If Phase 0 shows the API does not serve JSON, the samples are blocked until JSON support is enabled on the host.
2. Script file names starting with digits (`200.get_projects.py`) can't be imported as Python modules, which is fine for standalone scripts. Recommendation: keep the numbering for consistency with PowerShell.
3. The local demo credentials are for the running development instance only; never reuse or expose them outside that environment.
