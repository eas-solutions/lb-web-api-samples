##  Task: T10145 PowerShell sample code for the LeegooBuilder Web API

![Open Task T10145](https://esp.eas-cpq.de/TaskDetail?2d583801-f0d0-4418-bdbd-bd02a750d3d2)

## task Description
Add PowerShell samples to the lb-web-api-samples repository for the LeegooBuilder Web API. Cover login, GetProjects and GetProject, GetProposals and GetProposal, LoadPersons with Init/SavePerson, and LoadCompanies with Init/SaveCompany. Use the existing API client. The client keeps using protobuf. Each sample serializes the returned object to JSON and prints that JSON.

## Suggested Solution

Move every file under `Powershell` to `Examples/Powershell` with `git mv`, including `Basics`, `ProjectsProposals`, `CompaniesAndPersons`, `ImportExport`, and `Scripts`. Update every moved script to the shared behavior below. Do not leave a script behind because it is outside the task list.

### Shared script behavior

Apply this to every script, including `ImportAndLogin.ps1`, the import/export scripts, and `ExecuteCustomScript.ps1`.

**Working directory.** At the start, store the current location. At the end, return to that location when the script changed it. `Set-Location` affects the whole session, including when a script is called with `&`.

**Result output.** Print the API result through the shared JSON writer described under JSON output. On a failed operation, a thrown login failure, or a file write failure, print the result in red. Leave successful output in the default console color. Do not keep the old `Write-Host` field dumps.

**Optional parameters and session values.** Accept the script's inputs as optional parameters. Store each resolved value in a global session variable so later scripts in the same PowerShell session reuse it.

Resolve each value in this order:

1. If the parameter was provided, assign that value to the session variable, including when the variable already has a value.
2. If the parameter was omitted and the session variable is set, use the variable.
3. If the variable is not set, use the value currently hardcoded in that script and assign it to the variable.

Use `$PSBoundParameters` to detect an omitted parameter. An explicit empty string is a provided value and replaces the session variable.

`ImportAndLogin.ps1` owns the shared connection parameters. Other scripts accept the same parameters and pass through only the ones the caller provided.

| Parameter | Session variable | Fallback already in the scripts |
| --- | --- | --- |
| `DllPath` | `$LbDllPath` | Repository `bin` folder (`$PSScriptRoot\..\..\bin` from `ImportAndLogin.ps1`). One directory that contains all three DLLs. |
| `ApiUrl` | `$LbApiUrl` | `http://localhost:56540/api/` |
| `Username` | `$LbUsername` | `Administrator` |
| `Password` | `$LbPassword` | `admin` |
| `Culture` | `$LbCulture` | `de-DE` |
| `Language` | `$LbLanguage` | `de-DE` |

`DllPath` is the single base path. Load `EAS.DataTransfer.dll`, `EAS.LeegooBuilder.Web.WebApiClient.dll`, and `EAS.LeegooBuilder.Common.DataTransferObjects.dll` from that directory. Remove the hardcoded `C:\Quelltexte\...` and `D:\WebAPI\Client` paths.

Add these optional parameters where the script currently hardcodes the value:

| Script | Parameters | Fallback |
| --- | --- | --- |
| `310.LoadCompanies.ps1` | `CompanyName` | `gmbh` |
| `300.LoadCompany.ps1` | `InternalCompanyID` | the GUID already in that script |
| `360.ModifyCompany.ps1` | `Company`, `InternalCompanyID` | the GUID already in that script only when both `Company` and `InternalCompanyID` are omitted |
| `350.CreateCompany.ps1` | `CompanyName`, `CompanyID` | `Test Company` and `TestCompany` plus the current timestamp |
| `410.LoadPersons.ps1`, `450.CreatePerson.ps1` | `InternalCompanyID` | `2b5de0b3-e566-ea11-82c1-f8344140dd36` |
| `400.LoadPerson.ps1` | `InternalPersonID` | the GUID already in that script |
| `460.ModifyPerson.ps1` | `Person`, `InternalPersonID` | the GUID already in that script only when both `Person` and `InternalPersonID` are omitted |
| `450.CreatePerson.ps1` | `PersonName`, `PersonID` | `Test Person at ...` and `Test` plus the current timestamp |
| `200.LoadProjects.ps1` | `Name` | no name filter when omitted |
| `220.LoadProject.ps1` | `InternalProjectID` | first project returned by `GetProjects` when omitted |
| `230.LoadProposal.ps1` | `InternalProposalID` | first proposal returned by `GetProposals` when omitted |
| `410.ImportProposal.ps1` | `ProposalFile` | `C:\Temp\ExportedProposal.leegoo` |
| `420.ExportProposal.ps1` | `InternalProposalID`, `OutputFile` | empty GUID and `C:\Temp\ExportedProposal.leegoo` |
| `430.ExportProject.ps1` | `InternalProjectID`, `OutputFile` | empty GUID and `C:\Temp\ExportedProposalById.leegoo` |
| `ExecuteCustomScript.ps1` | `ScriptName` | `CustomerImport` |

### JWT reuse

Keep login in `ImportAndLogin.ps1`. Store the access token in the session variable `$LbAccessToken`.

- When `$LbAccessToken` is set, create `WebApiClient` with that token and call `IsAccessValid()`. Return the client without calling `LoginAsync` when the token is still valid.
- When the variable is missing or the token is not valid, call `AuthenticationClient.LoginAsync`, then store `User.Token` in `$LbAccessToken`.
- Clear `$LbAccessToken` when login fails.
- Changing `ApiUrl`, `Username`, or `Password` through a parameter invalidates `$LbAccessToken` so the next call logs in again.

Other scripts keep calling `ImportAndLogin.ps1` and do not log in themselves.

When `ImportAndLogin.ps1` is the script the user started, store and print the login result like any other sample. When another script calls it, do not store the login result in `$LbApiOutput` or `$LbApiOutputJSON` and do not print it. A failed login is the exception: store that failed result and print it in red, including when the login script was called by another script. Detect a direct run with an empty `$MyInvocation.ScriptName`.

### Already implemented

These scripts already call the current client and stay after the move:

- Login: `ImportAndLogin.ps1` calls `AuthenticationClient.LoginAsync`.
- `GetProjects`: `ProjectsProposals/200.LoadProjects.ps1`.
- `GetProposals`: `ProjectsProposals/210.LoadProposals.ps1`.
- `LoadCompanies`: `CompaniesAndPersons/310.LoadCompanies.ps1`.
- `SaveCompany`: `CompaniesAndPersons/350.CreateCompany.ps1` and `360.ModifyCompany.ps1`.
- `LoadPersons`: `CompaniesAndPersons/410.LoadPersons.ps1`.
- `SavePerson`: `CompaniesAndPersons/450.CreatePerson.ps1` and `460.ModifyPerson.ps1`.

Also move and update `300.LoadCompany.ps1`, `400.LoadPerson.ps1`, `Basics/100.LoadLoginInfos.ps1`, `ImportExport`, and `Scripts/ExecuteCustomScript.ps1`.

### Needs to be added

Add two scripts under `Examples/Powershell/ProjectsProposals`:

- `GetProject`: call `GetProjects` as `200.LoadProjects.ps1` does, or use `InternalProjectID` when that parameter or session variable is set. Call `ProjectClient.GetProjectAsync` with `GetProjectParameter.ProjectId`. `ProjectId` is the internal GUID, not the human-readable `ProjectID`.
- `GetProposal`: call `GetProposals`, or use `InternalProposalID` when provided. Call `ProposalClient.GetProposalAsync` with `GetProposalParameter.ProposalId`. Set `IncludeCustomDefinitionValues` and `IncludeCompaniesAndPersons` to `$false` for the minimum request.

### Needs to be updated

- `350.CreateCompany.ps1` saves a hand-built `CompanyItem` and never calls `InitCompany`. Call `CompaniesAndPersonsClient.InitCompanyAsync` first, set `Name1` and `CompanyID` on the returned company, then call `SaveCompanyAsync` with `SaveDataMode.Insert`.
- `450.CreatePerson.ps1` has the same gap for persons. Call `InitPersonAsync` first, set `Name`, `PersonID`, `IsActive`, and `InternalCompanyID` on the returned person, then call `SavePersonAsync`.
- `200.LoadProjects.ps1` sets `LoadOptions`. `GetProjects` does not read that property. Keep `ProjectsContent = Projects`, and drop `LoadOptions`. Add an optional `Name` parameter. When it is set, filter with `QuerySettings.Where` on `Description` using the named `Contains` operator. `Description` is the project name the current sample prints. When `Name` is omitted, do not add that filter.
- `210.LoadProposals.ps1` filters on the fixed `ProposalID` `2404` and assigns raw integers to `QueryWhere.Operator` and `Condition`. Remove that fixed filter so the sample lists proposals. Use named enum values if a query remains.
- `ExecuteCustomScript.ps1` still calls removed members (`UserServiceWeb.LoginParameter`, `LogIn`, `ScriptingService`). Point it at `ImportAndLogin.ps1` and call `ScriptingClient.LoadScriptListAsync` and `ScriptingClient.ExecuteCustomScriptAsync`.
- `360.ModifyCompany.ps1` and `460.ModifyPerson.ps1` must accept the entity to save, so a caller can load an object, change a property, and pass it back. See Object input for updates.

### Object input for updates

`360.ModifyCompany.ps1` takes optional `Company`. `460.ModifyPerson.ps1` takes optional `Person`. Each parameter accepts either the client object or a JSON string.

- A PowerShell or .NET object is used as the company or person to save.
- A JSON string is deserialized. When the JSON is a full API response, read `company` or `person`. When it is the entity itself, use that object. Map the JSON onto `CompanyItem` or `PersonItem` before calling save. `ConvertFrom-Json` alone produces a `PSCustomObject`, which the client will not accept.
- When the object or JSON is provided, do not load by id and do not overwrite the caller's property changes. Call `SaveCompanyAsync` or `SavePersonAsync` with `SaveDataMode.Update`.
- When the object is omitted and `InternalCompanyID` or `InternalPersonID` is provided, load that id, change the sample name, then save.
- Use the hardcoded GUID only when both the entity parameter and the id parameter are omitted. Then load that id, change the sample name, and save.

This is the intended chain: load a person, change one property on that object, then pass the same object to the modify script.

Relative calls such as `..\ImportAndLogin.ps1` stay valid because only the `Powershell` folder moves.

### Readme

Create `Examples/Powershell/Readme.md`. Move the PowerShell recommendation, preparation, DLL list, and `ImportAndLogin.ps1` description out of the repository `README.md`, and replace that section with a link to `Examples/Powershell/Readme.md`.

Extend the new readme so it explains how to run the samples:

- Copy the three client DLLs into one folder and pass that folder as `DllPath`, or rely on the repository `bin` fallback.
- Optional parameters, session variables, and the fallback values.
- A value passed on the command line replaces the session variable. A later script reuses the variable when the parameter is omitted.
- `$LbAccessToken` is reused until it is invalid or the connection settings change.
- Each directly run script stores the last API object in `$LbApiOutput` and its JSON in `$LbApiOutputJSON`. The console result is that JSON, pretty-printed, with list items over five written as one JSON object per line. Failed results are printed in red. Login output is hidden when another script called `ImportAndLogin.ps1`, unless that login failed.
- For every script, add a short summary and a usage section that lists every parameter, what it accepts, and the fallback when it is omitted. Include the shared connection parameters on `ImportAndLogin.ps1`, and state that the other scripts forward only the connection parameters the caller passed. Cover `ImportAndLogin.ps1`, `Write-LbApiResult.ps1`, `Basics/100.LoadLoginInfos.ps1`, `200.LoadProjects.ps1`, `210.LoadProposals.ps1`, `220.LoadProject.ps1`, `230.LoadProposal.ps1`, `300.LoadCompany.ps1`, `310.LoadCompanies.ps1`, `350.CreateCompany.ps1`, `360.ModifyCompany.ps1`, `400.LoadPerson.ps1`, `410.LoadPersons.ps1`, `450.CreatePerson.ps1`, `460.ModifyPerson.ps1`, `410.ImportProposal.ps1`, `420.ExportProposal.ps1`, `430.ExportProject.ps1`, and `ExecuteCustomScript.ps1`.
- Add chaining examples that use the session output of one script as the input of the next. Include a person update, a company update, and a project lookup. Use the .NET object for the person update and JSON for the company update:

```powershell
& .\CompaniesAndPersons\400.LoadPerson.ps1 -InternalPersonID "<guid>"
$LbApiOutput.Person.Name = "Updated name"
& .\CompaniesAndPersons\460.ModifyPerson.ps1 -Person $LbApiOutput.Person
```

```powershell
& .\CompaniesAndPersons\300.LoadCompany.ps1 -InternalCompanyID "<guid>"
$companyJson = $LbApiOutput.Company | ConvertTo-Json -Depth 8
# Change Name1 in $companyJson, then:
& .\CompaniesAndPersons\360.ModifyCompany.ps1 -Company $companyJson
```

```powershell
& .\ProjectsProposals\200.LoadProjects.ps1 -Name "Demo"
$projectId = $LbApiOutput.Projects[0].InternalProjectID
& .\ProjectsProposals\220.LoadProject.ps1 -InternalProjectID $projectId
```

The project example filters `GetProjects` by name, takes the first returned project, reads its internal id, and loads that project with `GetProject`. Use `InternalProjectID`, not the human-readable `ProjectID`.

### JSON output

Keep the client DLLs on protobuf. Do not change `WebApiClient` to send or accept JSON, and do not replace the client calls with `Invoke-RestMethod`. Meet the JSON requirement in PowerShell by serializing the object the client already returned.

Add one shared script, `Examples/Powershell/Write-LbApiResult.ps1`. Do not copy the formatting into each script. Call it for the last API call in a script. If an earlier API call fails and the script exits, call it for that failed response instead and do not continue. Do not call it for an intermediate success, such as `InitCompany` or `InitPerson` before the matching save. `ImportAndLogin.ps1` calls it only when the user started that script directly, or when login failed. A login call made by another script does not call it unless that login failed.

The shared script:

- Stores the response object in the session variable `$LbApiOutput`.
- Serializes that object to JSON and stores the text in `$LbApiOutputJSON`. Use `ConvertTo-Json` with a depth high enough for the client graphs (at least 8).
- Prints `$LbApiOutputJSON` pretty-printed in the default console color when `OperationResult.Successful` is true.
- Prints the same output in red when the operation failed.
- When the response contains a list with more than 5 items, pretty-print the response without that list, then print each item as one compact JSON line. Use the same red or default color for those lines. Lists of 5 or fewer stay inside the pretty-printed response.
- For import/export responses, replace byte-array properties such as `ProposalFile` with the byte length before serializing, so the printed JSON stays readable. `$LbApiOutput` still holds the original response object.

`$LbApiOutput` and `$LbApiOutputJSON` hold the response passed to the shared script: the last API call, or the earlier failed call that made the script exit.
