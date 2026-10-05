# PowerShell examples

## Recommendation

The easiest way to try out the PowerShell examples is [Visual Studio Code](https://code.visualstudio.com/). Here you can start the scripts easily, debug them, and additionally there is some IntelliSense.

## Preparation

Copy the LeegooBuilder Web API client DLLs into one folder and pass that folder as `DllPath`, or rely on the default folder `lb-web\Bin\Client` relative to the repository root.

The following libraries are used in these examples:

- `EAS.LeegooBuilder.Web.WebApiClient.dll`
- `EAS.LeegooBuilder.Common.DataTransferObjects.dll`
- `EAS.DataTransfer.dll`

The client DLLs use protobuf on the wire. Each sample prints JSON by serializing the .NET response object in PowerShell.

## Session variables and parameters

Many parameters are optional. For those, `Resolve-LbSessionValue` (in `Helpers/Lb-Session.ps1`) applies this precedence:

1. If the parameter was provided on the command line with a non-empty value, that value is stored in the global session variable and returned. An explicit empty or whitespace-only string clears the session variable and resolution continues with rules 2–3 (for example `-Name ''` clears `$LbProjectName`; with no fallback, the result is `$null` and no name filter is applied).
2. If the parameter was omitted and the session variable already exists, the variable value is used.
3. If the variable does not exist, the script-specific default documented below is returned for this call. Fallback values are not written to the session variable (only values you provide explicitly are stored).

This rule applies to connection settings, filters such as `Name` / `CompanyName`, file paths, and similar optional inputs. It does **not** apply to mandatory parameters.

### Mandatory internal IDs

These parameters are **required** on the command line (`[Parameter(Mandatory = $true)]`). They are **not** resolved from session variables and have **no** hardcoded GUID fallbacks in the scripts:

| Parameter | Scripts |
| --- | --- |
| `InternalCompanyID` | `300.LoadCompany.ps1`, `410.LoadPersons.ps1`, `450.CreatePerson.ps1`; `360.ModifyCompany.ps1` when `-Company` is not used |
| `InternalPersonID` | `400.LoadPerson.ps1`; `460.ModifyPerson.ps1` when `-Person` is not used |
| `InternalProjectID` | `220.LoadProject.ps1`, `430.ExportProject.ps1` |
| `InternalProposalID` | `230.LoadProposal.ps1`, `420.ExportProposal.ps1` |

Pass the GUID explicitly (for example from a previous API response in `$LbApiOutput`, as in the [chaining examples](#chaining-examples)). Variables such as `$LbInternalCompanyID` are not used by these samples.

### Output
Each directly run sample stores the final API response in `$LbApiOutput` and its serialized JSON in `$LbApiOutputJSON`. Failed API results are printed in red.

## Authentication
`ImportAndLogin.ps1` owns the connection settings. Every other script accepts the same six connection parameters and forwards only the ones you passed to `ImportAndLogin.ps1`.

### Authentication parameters

| Parameter | Session variable | Default |
| --- | --- | --- |
| `DllPath` | `$LbDllPath` | `lb-web\Bin\Client` under the repository root |
| `ApiUrl` | `$LbApiUrl` | `http://localhost:56540/api/` |
| `Username` | `$LbUsername` | `Administrator` |
| `Password` | `$LbPassword` | `admin` |
| `Culture` | `$LbCulture` | `de-DE` |
| `Language` | `$LbLanguage` | `de-DE` |

Session variable `$LbAccessToken` stores the JWT. It is reused while `IsAccessValid()` returns true. When you pass `ApiUrl`, `Username`, or `Password` and the value differs from what is already stored in the session, the token is cleared so the next call logs in again.

Running `ImportAndLogin.ps1` directly prints the login API response. Other scripts call it in the background and only show output when login fails.

## Basics

### Load Login Infos

The script `Basics/100.LoadLoginInfos.ps1` loads the login infos, containing the options you can select at the login.

**Called API endpoint**: `api/Authentication/LoadLoginInfos`

**Called Method**:       `AuthenticationClient.LoadLoginInfosAsync`


#### Parameters
- `DllPath` (optional)
    - folder containing the Web API client DLLs
    - [Session variable](#session-variables-and-parameters): `$LbDllPath` (same as [authentication parameters](#authentication-parameters))
    - Default value: `lb-web\Bin\Client` under the repository root (resolved relative to this script)
- `ApiUrl` (optional)
    - base URL of the Web API (including the `api/` segment)
    - [Session variable](#session-variables-and-parameters): `$LbApiUrl` (same as [authentication parameters](#authentication-parameters))
    - Default value: `http://localhost:56540/api/`

> **Note**: This endpoint can be called without authentication.


## Projects and proposals

### Load Projects

The script `ProjectsProposals/200.LoadProjects.ps1` loads a list of projects. That list may be filtered by name.

**Called API endpoint**: `api/Project/GetProjects`

**Called Method**:       `ProjectClient.GetProjectsAsync`

#### Parameters
- `Name` (optional)
    - filters the projects by `Description` using `Contains`
    - [Session variable](#session-variables-and-parameters): `$LbProjectName`
    - Default value: none (no filter); pass an empty string to clear a previously stored name filter
- [Authentication parameters](#authentication-parameters).

### Load Proposals

The script `ProjectsProposals/210.LoadProposals.ps1` loads a list of proposals.

**Called API endpoint**: `api/Proposal/GetProposals`

**Called Method**:       `ProposalClient.GetProposalsAsync`

#### Parameters
- [Authentication parameters](#authentication-parameters).

### Load Project

The script `ProjectsProposals/220.LoadProject.ps1` loads one project by internal id.

**Called API endpoint**: `api/Project/GetProject`

**Called Method**:       `ProjectClient.GetProjectAsync`

#### Parameters
- `InternalProjectID` (required)
- [Authentication parameters](#authentication-parameters).

### Load Proposal

The script `ProjectsProposals/230.LoadProposal.ps1` loads one proposal by internal id. Custom definition values and companies/persons are not included in the request.

**Called API endpoint**: `api/Proposal/GetProposal`

**Called Method**:       `ProposalClient.GetProposalAsync`

#### Parameters
- `InternalProposalID` (required)
- [Authentication parameters](#authentication-parameters).

## Companies and persons

### Load Company

The script `CompaniesAndPersons/300.LoadCompany.ps1` loads one company.

**Called API endpoint**: `api/CompaniesAndPersons/LoadCompany`

**Called Method**:       `CompaniesAndPersonsClient.LoadCompanyAsync`

#### Parameters
- `InternalCompanyID` (required)
- [Authentication parameters](#authentication-parameters).

### Load Companies

The script `CompaniesAndPersons/310.LoadCompanies.ps1` loads companies matching a name filter.

**Called API endpoint**: `api/CompaniesAndPersons/LoadCompanies`

**Called Method**:       `CompaniesAndPersonsClient.LoadCompaniesAsync`

#### Parameters
- `CompanyName` (optional)
    - [Session variable](#session-variables-and-parameters): `$LbCompanyName`
    - Default value: `gmbh`
- [Authentication parameters](#authentication-parameters).

### Create Company

The script `CompaniesAndPersons/350.CreateCompany.ps1` initializes a new company template and saves it as a new record.

**Called API endpoint**: `api/CompaniesAndPersons/InitCompany`, then `api/CompaniesAndPersons/SaveCompany`

**Called Method**:       `CompaniesAndPersonsClient.InitCompanyAsync`, then `CompaniesAndPersonsClient.SaveCompanyAsync` (`SaveDataMode.Insert`)

#### Parameters
- `CompanyName` (optional)
    - [Session variable](#session-variables-and-parameters): `$LbCompanyName`
    - Default value: `Test Company`
- `CompanyID` (optional)
    - [Session variable](#session-variables-and-parameters): `$LbCompanyID`
    - Default value: `TestCompany` plus a timestamp
- [Authentication parameters](#authentication-parameters).

### Modify Company

The script `CompaniesAndPersons/360.ModifyCompany.ps1` updates an existing company. Pass a `Company` object from a previous load, or let the script load a company by id and change `Name1` before saving.

**Called API endpoint**: `api/CompaniesAndPersons/SaveCompany` (and optionally `api/CompaniesAndPersons/LoadCompany`)

**Called Method**:       `CompaniesAndPersonsClient.SaveCompanyAsync` (`SaveDataMode.Update`; optionally `LoadCompanyAsync` first)

#### Parameters
Pass either `Company` or `InternalCompanyID` (not both).
- `Company` (required with `-Company`)
    - a .NET `CompanyItem` or JSON string (for example from `$LbApiOutput.Company`)
- `InternalCompanyID` (required without `-Company`)
    - loads the company, changes `Name1`, then saves
- [Authentication parameters](#authentication-parameters).

### Load Person

The script `CompaniesAndPersons/400.LoadPerson.ps1` loads one person.

**Called API endpoint**: `api/CompaniesAndPersons/LoadPerson`

**Called Method**:       `CompaniesAndPersonsClient.LoadPersonAsync`

#### Parameters
- `InternalPersonID` (required)
- [Authentication parameters](#authentication-parameters).

### Load Persons

The script `CompaniesAndPersons/410.LoadPersons.ps1` loads persons for one company. The script parameter `InternalCompanyID` is assigned to `LoadPersonsParameter.CompanyID`.

**Called API endpoint**: `api/CompaniesAndPersons/LoadPersons`

**Called Method**:       `CompaniesAndPersonsClient.LoadPersonsAsync`

#### Parameters
- `InternalCompanyID` (required)
    - assigned to `LoadPersonsParameter.CompanyID`
- [Authentication parameters](#authentication-parameters).

### Create Person

The script `CompaniesAndPersons/450.CreatePerson.ps1` initializes a new person template and saves it as a new record.

**Called API endpoint**: `api/CompaniesAndPersons/InitPerson`, then `api/CompaniesAndPersons/SavePerson`

**Called Method**:       `CompaniesAndPersonsClient.InitPersonAsync`, then `CompaniesAndPersonsClient.SavePersonAsync` (`SaveDataMode.Insert`)

#### Parameters
- `InternalCompanyID` (required)
    - company the person belongs to
- `PersonName` (optional)
    - [Session variable](#session-variables-and-parameters): `$LbPersonName`
    - Default value: `Test Person at ` plus a timestamp
- `PersonID` (optional)
    - [Session variable](#session-variables-and-parameters): `$LbPersonID`
    - Default value: `Test` plus a timestamp
- [Authentication parameters](#authentication-parameters).

### Modify Person

The script `CompaniesAndPersons/460.ModifyPerson.ps1` updates an existing person. Pass a `Person` object from a previous load, or let the script load a person by id and change the name before saving.

**Called API endpoint**: `api/CompaniesAndPersons/SavePerson` (and optionally `api/CompaniesAndPersons/LoadPerson`)

**Called Method**:       `CompaniesAndPersonsClient.SavePersonAsync` (`SaveDataMode.Update`; optionally `LoadPersonAsync` first)

#### Parameters
Pass either `Person` or `InternalPersonID` (not both).
- `Person` (required with `-Person`)
    - a .NET `PersonItem` or JSON string (for example from `$LbApiOutput.Person`)
- `InternalPersonID` (required without `-Person`)
    - loads the person, changes the name, then saves
- [Authentication parameters](#authentication-parameters).

## Import and export

### Import Proposal

The script `ImportExport/410.ImportProposal.ps1` reads a `.leegoo` file from disk and imports it.

**Called API endpoint**: `api/ImportExport/ImportProposals`

**Called Method**:       `ImportExportClient.ImportProposalsAsync`

#### Parameters
- `ProposalFile` (optional)
    - path to the `.leegoo` file
    - [Session variable](#session-variables-and-parameters): `$LbProposalFile`
    - Default value: `C:\Temp\ExportedProposal.leegoo`
- [Authentication parameters](#authentication-parameters).

### Export Proposal

The script `ImportExport/420.ExportProposal.ps1` exports one proposal and writes the file bytes to disk.

**Called API endpoint**: `api/ImportExport/ExportProposals`

**Called Method**:       `ImportExportClient.ExportProposalsAsync`

#### Parameters
- `InternalProposalID` (required)
- `OutputFile` (optional)
    - [Session variable](#session-variables-and-parameters): `$LbOutputFile`
    - Default value: `C:\Temp\ExportedProposal.leegoo`
- [Authentication parameters](#authentication-parameters).

### Export Project

The script `ImportExport/430.ExportProject.ps1` exports proposals for a project (`AddBaseData = true`) and writes the file bytes to disk.

**Called API endpoint**: `api/ImportExport/ExportProposalsByProjectId`

**Called Method**:       `ImportExportClient.ExportProposalsByProjectIdAsync`

#### Parameters
- `InternalProjectID` (required)
- `OutputFile` (optional)
    - [Session variable](#session-variables-and-parameters): `$LbOutputFile`
    - Default value: `C:\Temp\ExportedProposalById.leegoo`
- [Authentication parameters](#authentication-parameters).

## Scripting

### Execute Custom Script

The script `Scripts/ExecuteCustomScript.ps1` lists user scripts and runs one script by its description.

**Called API endpoint**: `api/Scripting/ExecuteCustomScript` (after `api/Scripting/LoadScriptList` to resolve the script id)

**Called Method**:       `ScriptingClient.ExecuteCustomScriptAsync` (after `ScriptingClient.LoadScriptListAsync` with `UserScript` type)

#### Parameters
- `ScriptName` (optional)
    - matched against the script `Description`
    - [Session variable](#session-variables-and-parameters): `$LbScriptName`
    - Default value: `CustomerImport`
- [Authentication parameters](#authentication-parameters).

## Chaining examples

### Modify a person from a load result

Load a person, change a field on the returned entity, and save it with `SavePerson` by passing the in-memory object to the modify script.

```powershell
& .\CompaniesAndPersons\400.LoadPerson.ps1 -InternalPersonID "<guid>"
$LbApiOutput.Person.Name = "Updated name"
& .\CompaniesAndPersons\460.ModifyPerson.ps1 -Person $LbApiOutput.Person
```

### Modify a company via JSON

Load a company, serialize it to JSON, edit fields in the string, and pass that JSON to the modify script.

```powershell
& .\CompaniesAndPersons\300.LoadCompany.ps1 -InternalCompanyID "<guid>"
$companyJson = $LbApiOutput.Company | ConvertTo-Json -Depth 8
# Change Name1 in $companyJson, then:
& .\CompaniesAndPersons\360.ModifyCompany.ps1 -Company $companyJson
```

### Load a project after searching by name

List projects with a name filter, take `InternalProjectID` from the first match, and load the full project. Use `InternalProjectID`, not the human-readable `ProjectID`.

```powershell
& .\ProjectsProposals\200.LoadProjects.ps1 -Name "Demo"
$projectId = $LbApiOutput.Projects[0].InternalProjectID
& .\ProjectsProposals\220.LoadProject.ps1 -InternalProjectID $projectId
```
