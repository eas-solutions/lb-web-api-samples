# CreateNewProject

`CreateNewProject` builds and initializes a new project, assigns a new internal ID, and runs the configured project-ID generation script. It can return the initialized project as a draft or save it immediately.

For the usual create-and-edit workflow, request an unsaved draft, let the user edit it, and persist it with [`SaveProject`](SaveProject.md).

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Project/CreateNewProject` |
| Body | JSON `CreateNewProjectParameter` object |
| Authentication | `Authorization: Bearer <access-token>` |

Set `BASE_URL` to your API address and `ACCESS_TOKEN` to a valid access token before running the examples.

## Minimum request

This initializes a project without saving it. All request properties have usable defaults, so an empty JSON object is sufficient.

```bash
curl --request POST "${BASE_URL}/api/Project/CreateNewProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--data '{}'
```

## Common editor request

The frontend starts with an unsaved project and requests related company and person data for its editor. It relies on the default `false` value of `SaveCreatedProjectInDatabase`.

```bash
curl --request POST "${BASE_URL}/api/Project/CreateNewProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--data '{
		"IncludeCompaniesAndPersons": true
	}'
```

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `IncludeCompaniesAndPersons` | `boolean` | No | Includes related company and person data in the returned project when `true`. Default: `false`. |
| `SaveCreatedProjectInDatabase` | `boolean` | No | Saves immediately when `true`. When omitted, it defaults to `false` and returns an unsaved project. |
| `ProjectName` | `string` | No | Initial project description. It can be changed before saving an unsaved project. |
| `ProjectId` | `string` | No | Initial human-readable project ID. The configured generation script subsequently replaces it, so callers should normally omit it. |

## Response and errors

Always check `OperationResult.Successful`. On success, `Project` contains the initialized project, its generated `ProjectID`, its new `InternalProjectID`, and loaded custom definitions.

```json
{
	"OperationResult": {
		"Successful": true
	},
	"Project": {
		"InternalProjectID": "3f2504e0-4f89-41d3-9a0c-0305e82c3301",
		"ProjectID": "P-1001"
	}
}
```

| Situation | Response behavior |
| --- | --- |
| Immediate database save fails | `OperationResult.Successful` is `false`; `ShortMessage` starts with `Error saving new project to database:`. |
| Related company/person loading fails | `OperationResult.Successful` is `false`; inspect `ShortMessage`. |
| Custom definition loading fails | `OperationResult.Successful` is `false`; inspect `ShortMessage`. |

When `SaveCreatedProjectInDatabase` is `false`, the returned project is not persisted. Send the returned project to `SaveProject` with `Type: "CreateNew"` after editing.