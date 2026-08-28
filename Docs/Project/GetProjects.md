# GetProjects

`GetProjects` returns the projects the authenticated user is allowed to see. Use `ProjectsContent` to request only the response parts your application needs. The active system-view schema and project visibility come from the current user unless you explicitly provide `SchemaName`.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Project/GetProjects` |
| Body | JSON `GetProjectsParameter` object |
| Response | Protocol Buffers (`application/x-protobuf`) |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token before running the examples. The localhost URL is suitable only for development.

## Minimum request

This returns project objects for all projects the current user can access.

```bash
curl --request POST "http://localhost:56540/api/Project/GetProjects" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/x-protobuf" \
	--data '{
		"ProjectsContent": [10]
	}' \
	--output get-projects-minimum.pb
```

`ProjectsContent` is the only required request property. Raw JSON requests must use the numeric enum values; `10` means `Projects`.

Live validation returned HTTP `200` with content type `application/x-protobuf`. Decoding the response with the API contract confirmed a successful operation and 3 project records. The response contained top-level `OperationResult`, `Projects`, and `QueryInfo` fields.

## Common grid request

The project grid in the frontend uses this shape. It requests the project list, custom field values, related person/company data, favorite status, and a page of results.

```bash
curl --request POST "http://localhost:56540/api/Project/GetProjects" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/x-protobuf" \
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
	}' \
	--output get-projects-common.pb
```

Use `Skip` and `Take` to page through the result set. `QuerySettings` also supports sorting and filtering; use the query model supplied by your API client when those are needed.

Live validation returned HTTP `200` with content type `application/x-protobuf`. The decoded response reported a successful operation, 3 returned projects, `QueryInfo.RecordsTotal` equal to `3`, and custom-definition entries for all 3 projects. Project identifiers, project data, related person/company data, and custom values were not included in this guide.

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

The supported response format for this endpoint is Protocol Buffers. Save curl's response to a `.pb` file as shown above, or use `EAS.LeegooBuilder.Web.WebApiClient`, which requests `application/x-protobuf` and deserializes `GetProjectsReturnParameter`.

The response shape varies with `ProjectsContent`; the common request populates `Projects`, `CustomDefinitionValues`, and `QueryInfo`. `PersonsAndCompanies` and `IsFavorite` add data to the returned project objects rather than separate top-level properties.

The abbreviated object below is the decoded response from the current one-record common request, not the raw protobuf HTTP body. The returned custom-property name and value are redacted; installation-specific project fields are omitted.

```json
{
	"OperationResult": {
		"DetailedMessage": null,
		"Exception": null,
		"OperationFailType": 0,
		"ShortMessage": null,
		"Successful": true,
		"ThrowException": false,
		"TranslatorTerm": null
	},
	"Projects": [
		{
			"InternalProjectID": "9897f980-1b7d-ed11-81d0-f2b3bff92a45",
			"ProjectID": "Aktuellste Demo",
			"Description": "Aktuelle Demo",
			"IsFavorite": true
		}
	],
	"QueryInfo": {
		"RecordsTotal": 3,
		"SelectedItemAtIndex": null,
		"SelectedItemAtPage": null
	},
	"CustomDefinitionValues": {
		"9897f980-1b7d-ed11-81d0-f2b3bff92a45": {
			"<redacted custom property name>": "<redacted SerializableObject>"
		}
	}
}
```

Requesting `application/json` currently returns HTTP `500` for both examples because the server detects a JSON property-name collision in the project entity graph. Do not omit the protobuf `Accept` header until that server-side serialization issue is fixed.

For paged requests, read `QueryInfo.RecordsTotal` after protobuf deserialization to determine the total number of matching projects.

## Errors

| Situation | Response behavior |
| --- | --- |
| `ProjectsContent` is missing or `null` | `OperationResult.Successful` is `false` and `ShortMessage` is `Project content is null, please select a response content`. |
| `SchemaName` does not exist | `OperationResult.Successful` is `false` and `ShortMessage` is `Schema does not exist`. |
| Request validation or processing fails | `OperationResult.Successful` is `false`; inspect `ShortMessage` for the available error detail. |
