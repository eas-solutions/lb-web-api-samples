## Plan: T10144 TypeScript samples for the LeegooBuilder Web API

Add a dependency-free TypeScript sample set under `Examples/TypeScript`. It uses Node 20+ native `fetch` and `tsx`, and sends JSON only. A reference `TokenManager` handles login and supplies the bearer token. There is one folder per controller and one runnable script per endpoint.

**Decisions**
- The target folder is `Examples/TypeScript`.
- Scripts run with `npx tsx <file>.ts`.
- Verification is a manual run of every script against `http://localhost:56540`, with `Administrator` / `admin`. The results go into the README. There is no test suite.
- The empty `Examples/Python` placeholder folders are removed. They contain no tracked code, only `__pycache__`.
- The "Suggested Solution" in the prompt mentions Python scripts and `Examples/Python`. I treat that as a leftover and ignore it.
- `LoadCompany`, `LoadPerson` and the delete endpoints are out of scope.
- Token reuse is in-memory only, with no token file on disk. The server never fills `renewalToken`, so a fresh login replaces `RenewToken`.

**Steps**

*Phase 1 – Project scaffold*
1. Remove the empty `Examples/Python` tree.
2. Create `Examples/TypeScript/package.json` (ESM, devDependencies `typescript`, `tsx`, `@types/node`, engines `node >=20`, plus a `typecheck` script) and `tsconfig.json` (strict, `NodeNext`, `noEmit`). Add `node_modules/` to the root `.gitignore`.

*Phase 2 – Shared library `lbapi/`* (*depends on 1*)
3. `config.ts` resolves settings from env vars with fallbacks: `LB_API_URL` (default `http://localhost:56540/api`), `LB_USERNAME`, `LB_PASSWORD`, `LB_LANGUAGE`, `LB_CULTURE`. The defaults are `Administrator`, `admin`, `en-GB` and `en-GB`.
4. `types.ts` holds minimal interfaces: `OperationResult`, `QueryInfo`, `QuerySettings` (with `Field`/`Operator`/`Value` as in `Docs/Common/QuerySettings.md`), the numeric enums (`SaveDataMode`, `GetProjectsContent`, and the proposal content and load options) and the response types.
5. `tokenManager.ts` has a clearly commented class, `TokenManager`, saying that it is a reference example. It exposes `getToken()`, which logs in lazily, shares one in-flight login between concurrent calls, and re-logs in when the JWT `exp` is within about 60 s. `invalidate()` clears the cached token.
6. `client.ts` provides `postJson<TReq, TRes>(path, body)`. It sends `Content-Type` and `Accept: application/json` and the `Authorization: Bearer` header from the `TokenManager`. It retries once after `invalidate()` on HTTP 401 or on an operationResult `NotLoggedIn` (10) or `TokenInvalid` (20). It throws an `ApiError` on non-2xx and on `operationResult.successful === false`.
7. `output.ts` and `args.ts` print pretty JSON (compact lines for long lists, as the PowerShell `Write-LbApiResult.ps1` does) and parse CLI options with `node:util` `parseArgs`. `index.ts` re-exports the library.

*Phase 3 – Endpoint scripts, one folder per controller* (*depends on Phase 2; scripts are parallel to each other*)
8. `Authentication/Login.ts` calls `POST /api/Authentication/Login` through the `TokenManager` and prints the user info with the token masked.
9. `Project/GetProjects.ts` (optional `--name` filter on `Description` with `Contains`, plus `--take`/`--skip`) and `Project/GetProject.ts` (required `--internal-project-id`).
10. `Proposal/GetProposals.ts` (required `--internal-project-id`) and `Proposal/GetProposal.ts` (required `--internal-proposal-id`).
11. `CompaniesAndPersons/LoadCompanies.ts` (`--name`, paging) and `LoadPersons.ts` (`--internal-company-id`, `--name`, `--only-active`). Both read the list from `.value` of the `ApplyQueryResult`.
12. `CompaniesAndPersons/SaveCompany.ts` and `SavePerson.ts` run Init, then set the fields, then Save with `SaveDataMode.Insert` (10). The generated IDs use a timestamp, as in the PowerShell samples. `SavePerson` takes `--internal-company-id`, passes it to `InitPerson` and sets `IsActive` as in `450.CreatePerson.ps1`.
    - Both scripts also support updating an existing entity (`SaveDataMode.Update`, 20) if the Insert/Update contract is confirmed live.
13. Every script uses a `main()` with a catch that prints the `ApiError` and sets `process.exitCode = 1`. It never uses `process.exit` inside the library.

*Phase 4 – Documentation* (*depends on Phase 3*)
14. `Examples/TypeScript/README.md` is the entry point. It covers the prerequisites (Node 20+, `npm install`), the env vars, the folder layout and a table of scripts with example commands. It states clearly that the `TokenManager` is a usable reference and that customers may adapt it. It also notes that the API is called with JSON only, with no protobuf or binary endpoints. A "Verified against" section lists each script and its result.
15. Add a link to the new README in the root `README.md`, as was done for PowerShell.

*Phase 5 – Verification* (*depends on 1–4*)
16. Run `npm install` and `npm run typecheck` with no errors.
17. Run every script against the demo API. Check that the token is reused within one process and refreshed after `invalidate()`. Check that the failure paths (wrong password, bad GUID) exit with 1 and a clear message.
18. Confirm the saved company and person via `LoadCompanies` and `LoadPersons`. The created demo data stays in place because there is no delete script.

**Relevant files**
- `.agents/used-prompts/T10144-nodejs-typescript-web-api-samples.prompt.md` – task source.
- `Docs/Authentication/Login.md`, `Docs/Common/QuerySettings.md`, `Docs/Project/*`, `Docs/Proposal/*` – request and response shapes.
- `Examples/Powershell/CompaniesAndPersons/350.CreateCompany.ps1` and `450.CreatePerson.ps1` – the Init and Save flow. `Examples/Powershell/Readme.md` – the layout and documentation style.
- `lb-web/EAS.LeegooBuilder.Web.Contracts/Models/ParameterClasses/CompaniesAndPersons/CompaniesAndPersonsParameters.cs` – the company and person contract. The `Docs/` folder does not cover them.
- `README.md` and `.gitignore` – to be modified.

**Further considerations**
1. Company and person requests and responses are not covered in `Docs/`. The exact JSON must be confirmed live during implementation.
2. The `fetch_webpage` call to `swagger.json` failed during planning, so the schemas have to be checked with a real request.
3. The `Login` script must keep the token out of the output unless the user asks for it. I recommend masking it.
