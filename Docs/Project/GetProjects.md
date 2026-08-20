# GetProjects

`GetProjects` returns the projects the authenticated user is allowed to see. Use `ProjectsContent` to request only the response parts your application needs. The active system-view schema and project visibility come from the current user unless you explicitly provide `SchemaName`.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Project/GetProjects` |
| Body | JSON `GetProjectsParameter` object |
| Authentication | `Authorization: Bearer <access-token>` |

Set `BASE_URL` to your API address and `ACCESS_TOKEN` to a valid access token before running the examples.

## Minimum request

This returns project objects for all projects the current user can access.

```bash
curl --request POST "${BASE_URL}/api/Project/GetProjects" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--data '{
		"ProjectsContent": ["Projects"],
		"LoadOptions": ["AllProjects"]
	}'
```

`ProjectsContent` is required. `LoadOptions` is included here to make the intended scope explicit.

## Common grid request

The project grid in the frontend uses this shape. It requests the project list, custom field values, related person/company data, favorite status, and a page of results.

```bash
curl --request POST "${BASE_URL}/api/Project/GetProjects" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--data '{
		"ProjectsContent": [
			"Projects",
			"CustomDefinitionValues",
			"PersonsAndCompanies",
			"IsFavorite"
		],
		"LoadOptions": ["AllProjects"],
		"ReplaceCustomOverwriteColumns": true,
		"ReplaceSyscodesWithValues": true,
		"QuerySettings": {
			"Skip": 0,
			"Take": 50
		}
	}'
```

Use `Skip` and `Take` to page through the result set. `QuerySettings` also supports sorting and filtering; use the query model supplied by your API client when those are needed.

## Request properties

The properties used by the common grid request are listed first. Property names below match the API contract.

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `ProjectsContent` | `GetProjectsContent[]` | Yes | Selects which response data to populate. The examples request `Projects`, `CustomDefinitionValues`, `PersonsAndCompanies`, and `IsFavorite`. |
| `LoadOptions` | `ProjectLoadType[]` | No | Restricts the project scope. `AllProjects` is the usual choice for a complete accessible-project list. |
| `ReplaceCustomOverwriteColumns` | `boolean` | No | Replaces custom override columns with typed values when `true`. |
| `ReplaceSyscodesWithValues` | `boolean` | No | Replaces system-code identifiers with their values when `true`. |
| `QuerySettings` | `QuerySettings` | No | Controls paging (`Skip`, `Take`) and can also control sorting, filtering, selected properties, and distinct results. |
| `Language` | `string` | No | Language used for localized project-list data. |
| `SchemaName` | `string` | No | System-view schema to use instead of the authenticated user's active schema. |

### Content selection

Choose only the `ProjectsContent` values needed by the caller:

| Value | Use when you need |
| --- | --- |
| `Projects` | Project objects in `Projects`. |
| `CustomDefinitionValues` | Custom field values, returned in `CustomDefinitionValues` and keyed by internal project ID. Request this together with `Projects`. |
| `PersonsAndCompanies` | Related person and company data for project fields. |
| `IsFavorite` | Favorite status for the returned projects. |
| `UserSettings` | The current user's saved grid layout in `Layout`. |
| `SystemViews` | Full project-grid column metadata in `ViewData`. |
| `BasicColumDefinitions` | Lightweight column metadata in `BasicColumDefinitions`. The API contract uses this spelling. |
| `TableData` | DevExpress grid table JSON in `Data`. |
| `SysCodes` | Localized system-code values in `SysCodes`. |
| `All` | Every content type. Prefer an explicit, smaller list for normal application requests. |

`LoadOptions` accepts `AllProjects`, `OwnProjects`, `OwnBusifieldProjects`, `OwnSupplierProjects`, `OwnUserGroupProjects`, and `OwnUserGroupProjectsRegardingOwner`.

## Response and errors

Every response contains `OperationResult`. Check `OperationResult.Successful` before using the requested data. On failure, use `OperationResult.ShortMessage` to show or log the reason.

The response shape varies with `ProjectsContent`. A successful common-grid response is abbreviated below; project fields depend on the installation's project schema.

```json
{
	"OperationResult": {
		"Successful": true
	},
	"Projects": [
		{
			"ProjectID": "P-1001"
		}
	],
	"CustomDefinitionValues": {
		"project-internal-id": {
			"CustomFieldName": "Value"
		}
	},
	"QueryInfo": {
		"RecordsTotal": 125
	}
}
```

| Situation | Response behavior |
| --- | --- |
| `ProjectsContent` is missing or `null` | `OperationResult.Successful` is `false` and `ShortMessage` is `Project content is null, please select a response content`. |
| `SchemaName` does not exist | `OperationResult.Successful` is `false` and `ShortMessage` is `Schema does not exist`. |
| Request validation or processing fails | `OperationResult.Successful` is `false`; inspect `ShortMessage` for the available error detail. |

For paged requests, read `QueryInfo.RecordsTotal` to determine the total number of matching projects.
