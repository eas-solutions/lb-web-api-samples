# GetProjects

`GetProjects` returns the projects the authenticated user is allowed to see. Use `ProjectsContent` to request only the response parts your application needs. The active system-view schema and project visibility come from the current user unless you explicitly provide `SchemaName`.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Project/GetProjects` |
| Body | JSON `GetProjectsParameter` object |
| Response | JSON (`application/json`) |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token before running the examples. The localhost URL is suitable only for development.

## Minimum request

This returns project objects for all projects the current user can access.

### Receive the JSON response with curl

```bash
curl --request POST "http://localhost:56540/api/Project/GetProjects" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{
		"ProjectsContent": [10]
	}'
```

`ProjectsContent` is the only required request property. Raw JSON requests use numeric enum values; `10` means `Projects`.

The response is JSON and is written to standard output. It includes `operationResult` and, when requested, `projects` and `queryInfo`.

## Common grid request

The project grid in the frontend uses this shape. It requests the project list, custom field values, related person/company data, favorite status, and a page of results.

```bash
curl --request POST "http://localhost:56540/api/Project/GetProjects" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{
		"ProjectsContent": [
			10,
			30,
			60,
			80
		],
		"QuerySettings": {
			"Take": 50
		}
	}'
```

Use `Skip` and `Take` to page through the result set. `QuerySettings` also supports sorting and filtering; use the query model supplied by your API client when those are needed.

Live validation returned HTTP `200` with content type `application/json`. The response reported a successful operation, 6 returned projects, `queryInfo.recordsTotal` equal to `6`, and custom-definition entries for all 6 projects. Project identifiers, project data, related person/company data, and custom values were not included in this guide.

## Request properties

The properties used by the common grid request are listed first. Property names below match the API contract.

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `ProjectsContent` | `GetProjectsContent[]` | Yes | Selects which response data to populate. Raw JSON uses the numeric values shown below. |
| `QuerySettings` | [`QuerySettings`](../Common/QuerySettings.md) | No | Common filtering, searching, sorting, selection, index, and paging settings. |
| `SchemaName` | `string` | No | System-view schema to use instead of the authenticated user's active schema. |
| `Language` | `string` | No | Retained in the request contract, but the current `GetProjects` implementation does not read it. |
| `LoadOptions` | `ProjectLoadType[]` | No | Retained in the request contract, but the current `GetProjects` implementation does not read it. |
| `ReplaceCustomOverwriteColumns` | `boolean` | No | Retained in the request contract, but the current `GetProjects` implementation does not read it. |
| `ReplaceSyscodesWithValues` | `boolean` | No | Retained in the request contract, but the current `GetProjects` implementation does not read it. |

### Content selection

Choose only the `ProjectsContent` values needed by the caller:

| Value | JSON value | Use when you need |
| --- | --- | --- |
| `Projects` | `10` | Project objects in `Projects`. |
| `UserSettings` | `20` | The current user's saved grid layout in `Layout`. |
| `CustomDefinitionValues` | `30` | Custom field values, returned in `CustomDefinitionValues` and keyed by internal project ID. Request this together with `Projects`. |
| `SystemViews` | `40` | Full project-grid column metadata in `ViewData`. |
| `BasicColumDefinitions` | `45` | Lightweight column metadata in `BasicColumDefinitions`. The API contract uses this spelling. |
| `TableData` | `50` | DevExpress grid table JSON in `Data`. The current endpoint implementation does not populate this response property. |
| `PersonsAndCompanies` | `60` | Related person and company data for project fields. |
| `SysCodes` | `70` | Localized system-code values in `SysCodes`. |
| `IsFavorite` | `80` | Favorite status for the returned projects. |
| `All` | `0` | Every content type. Prefer an explicit, smaller list for normal application requests. |

`LoadOptions` accepts `AllProjects`, `OwnProjects`, `OwnBusifieldProjects`, `OwnSupplierProjects`, `OwnUserGroupProjects`, and `OwnUserGroupProjectsRegardingOwner`, but these values currently have no effect in this endpoint.

## Response

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `OperationResult` | [`OperationResultWeb`](../Common/OperationResult.md) | No | Common application-level result envelope for the project-list operation. |
| `Projects` | `Project[]` | Yes | Project graphs selected by `ProjectsContent: Projects` (`10`). |
| `QueryInfo` | [`QueryInfo`](../Common/QueryInfo.md) | Yes | Total-count and selected-item metadata for `QuerySettings`; omitted when no project list is loaded. |
| `CustomDefinitionValues` | `Dictionary<GUID, Dictionary<string, SerializableObject>>` | Yes | Custom values by project ID and custom-property name, selected by `CustomDefinitionValues` (`30`). |
| `Layout` | `GridLayoutWeb` | Yes | Saved grid layout, selected by `UserSettings` (`20`). |
| `ViewData` | `SystemViewWebDto[]` | Yes | Full project-grid metadata, selected by `SystemViews` (`40`). |
| `BasicColumDefinitions` | `BasicColumnDefinitionWeb[]` | Yes | Lightweight column metadata, selected by `BasicColumDefinitions` (`45`). The contract uses this spelling. |
| `Data` | `string` | Yes | Legacy DevExpress grid JSON, selected by `TableData` (`50`). The current implementation does not populate it. |
| `SysCodes` | `SysCodeItemWebDto[]` | Yes | Localized system-code values, selected by `SysCodes` (`70`). |

Set `Accept: application/json` to receive the response as JSON. JSON property names use camel case, while the C# contract property names in this guide use Pascal case.

The response shape varies with `ProjectsContent`; the common request populates `Projects`, `CustomDefinitionValues`, and `QueryInfo`. `PersonsAndCompanies` and `IsFavorite` add data to the returned project objects rather than separate top-level properties.

The abbreviated object below is the JSON response from the current one-record common request. The returned custom-property name and value are redacted; installation-specific project fields are omitted.

```json
{
	"operationResult": {
		"detailedMessage": null,
		"exception": null,
		"operationFailType": 0,
		"shortMessage": null,
		"successful": true,
		"throwException": false,
		"translatorTerm": null
	},
	"projects": [
		{
			"internalProjectID": "9897f980-1b7d-ed11-81d0-f2b3bff92a45",
			"projectID": "Aktuellste Demo",
			"description": "Aktuelle Demo",
			"isFavorite": true
		}
	],
	"queryInfo": {
		"recordsTotal": 3,
		"selectedItemAtIndex": null,
		"selectedItemAtPage": null
	},
	"customDefinitionValues": {
		"9897f980-1b7d-ed11-81d0-f2b3bff92a45": {
			"<redacted custom property name>": "<redacted SerializableObject>"
		}
	}
}
```

For paged requests, read `queryInfo.recordsTotal` to determine the total number of matching projects.

## Errors

| Situation | Response behavior |
| --- | --- |
| `ProjectsContent` is missing or `null` | `OperationResult.Successful` is `false` and `ShortMessage` is `Project content is null, please select a response content`. |
| `SchemaName` does not exist | `OperationResult.Successful` is `false` and `ShortMessage` is `Schema does not exist`. |
| Request validation or processing fails | `OperationResult.Successful` is `false`; inspect `ShortMessage` for the available error detail. |
