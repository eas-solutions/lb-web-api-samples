# SaveProject

`SaveProject` creates a project or updates an existing one. It can also persist custom definition values supplied separately from the project object.

For a new project, start with [`CreateNewProject`](CreateNewProject.md). For an update, start with [`GetProject`](GetProject.md), modify the returned object, and send the complete project back. Sending a partial object during an update can clear values that were not included.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Project/SaveProject` |
| Body | JSON `SaveProjectParameter` object |
| Authentication | `Authorization: Bearer <access-token>` |

Set `BASE_URL` to your API address and `ACCESS_TOKEN` to a valid access token before running the examples.

## Minimum create request

This is the smallest explicit create request. In a real workflow, send the complete initialized project returned by `CreateNewProject` so configured defaults are retained.

```bash
curl --request POST "${BASE_URL}/api/Project/SaveProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--data '{
		"Type": "CreateNew",
		"Project": {
			"ProjectID": "P-1001"
		}
	}'
```

## Common update request

This follows the editor's load-edit-save flow without dropping fields. First save a `GetProject` response produced with `IncludeCustomDefinitionValues: true` as `get-project-response.json`. The `jq` command changes the description and builds a save request that preserves the complete project and custom-value dictionary.

```bash
jq '
	.Project.Description = "Updated project name"
	| {
		Type: "UpdateExisting",
		Project: .Project,
		CustomDefinitionValues: .CustomDefinitionValues
	}
' get-project-response.json > save-project-request.json

curl --request POST "${BASE_URL}/api/Project/SaveProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--data @save-project-request.json
```

Omitting `SkipDataValidation` keeps its default value of `false`, which is recommended for API integrations. The frontend currently bypasses server validation in one internal workflow because of a known dependency-injection issue; that is not a recommended integration pattern.

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `Type` | `SaveProjectType` | Yes | `CreateNew` inserts a project; `UpdateExisting` updates the project identified by `Project.InternalProjectID`. |
| `Project` | `Project` | Yes | Project to save. `ProjectID` must not be empty. Send the complete loaded/initialized object to preserve its values. |
| `SkipDataValidation` | `boolean` | No | Skips update validation when `true`. Default and recommended value: `false`. |
| `CustomDefinitionValues` | `Dictionary<string, SerializableObject>` | No | Custom values keyed by custom property name. During an update, existing values missing from this dictionary are marked for deletion. Preserve and return the complete dictionary loaded for the project. |
| `SchemaName` | `string` | No | Schema used to validate updates instead of the authenticated user's default schema. |

`Type` accepts `CreateNew` and `UpdateExisting`. Use the string names shown in the examples.

> [!WARNING]
> Omitting `CustomDefinitionValues` from an update can delete all existing custom definition values. Load them with `GetProject`, preserve every unchanged entry, and send the complete dictionary back.

## Response and errors

Check `OperationResult.Successful` before using the returned `Project`. On success, `Project` contains the saved server-side representation.

```json
{
	"OperationResult": {
		"Successful": true
	},
	"Project": {
		"InternalProjectID": "3f2504e0-4f89-41d3-9a0c-0305e82c3301",
		"ProjectID": "P-1001",
		"Description": "Updated project name"
	}
}
```

| Situation | `OperationResult.ShortMessage` |
| --- | --- |
| `Project.ProjectID` is empty | `Project ID cannot be empty` |
| `CreateNew` uses an existing `ProjectID` | `Project with same project ID already existing.` |
| `UpdateExisting` cannot find `Project.InternalProjectID` | `Could not find source project in Database. (Deleted?)` |
| Update validation fails | Contains the validation error returned for the changed fields. |
| Custom definition persistence fails | Starts with `Error saving custom definitions, please check the input fields.` |
| Project persistence fails | Starts with `Error saving project, please check the input fields.` |

Project fields and custom definitions depend on the installation. Treat the objects returned by `CreateNewProject` or `GetProject` as the source of truth rather than building a project DTO from a fixed field list.