# CreateNewProject

`CreateNewProject` builds and initializes a new project, assigns a new internal ID, and runs the configured project-ID generation script. It can return the initialized project as a draft or save it immediately.

For the usual create-and-edit workflow, request an unsaved draft, let the user edit it, and persist it with [`SaveProject`](SaveProject.md).

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Project/CreateNewProject` |
| Body | JSON `CreateNewProjectParameter` object |
| Response | JSON (`application/json`) |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token before running the examples. The localhost URL is suitable only for development.

## Minimum request

This initializes a project without saving it. All request properties have usable defaults, so an empty JSON object is sufficient.

```bash
curl --request POST "http://localhost:56540/api/Project/CreateNewProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{}'
```

Live validation returned HTTP `200` with content type `application/json`. The operation was successful and returned an initialized draft with non-empty generated `internalProjectID` and `projectID` values. No custom-definition entries were configured in the test installation.

## Common editor request

The frontend starts with an unsaved project and requests related company and person data for its editor. It relies on the default `false` value of `SaveCreatedProjectInDatabase`.

```bash
curl --request POST "http://localhost:56540/api/Project/CreateNewProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{
		"IncludeCompaniesAndPersons": true
	}'
```

Live validation returned HTTP `200` with content type `application/json`. The operation was successful and returned an initialized draft with non-empty generated identifiers. No custom-definition entries were configured in the test installation.

## Create and save immediately

Set `SaveCreatedProjectInDatabase` to `true` when the initialized project should be persisted by this endpoint instead of returned as an unsaved draft. `ProjectName` sets the initial description. The configured generation script still determines the returned `ProjectID`.

```bash
curl --request POST "http://localhost:56540/api/Project/CreateNewProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{
		"ProjectName": "API documentation validation",
		"SaveCreatedProjectInDatabase": true
	}'
```

Live validation returned HTTP `200` with content type `application/json`. The operation was successful and returned non-empty generated identifiers. A follow-up `GetProject` returned HTTP `200`, reported success, and returned the same internal ID, confirming that the project was persisted. The temporary validation project was then deleted; `GetProjects` returned HTTP `200` and confirmed that it was no longer listed.

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `IncludeCompaniesAndPersons` | `boolean` | No | Includes related company and person data in the returned project when `true`. Default: `false`. |
| `SaveCreatedProjectInDatabase` | `boolean` | No | Saves immediately when `true`. When omitted, it defaults to `false` and returns an unsaved project. |
| `ProjectName` | `string` | No | Initial project description. It can be changed before saving an unsaved project. |
| `ProjectId` | `string` | No | Initial human-readable project ID. The configured generation script subsequently replaces it, so callers should normally omit it. |

## Response

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `OperationResult` | [`OperationResultWeb`](../Common/OperationResult.md) | No | Common application-level result envelope for the initialization or immediate-save operation. |
| `Project` | `Project` | Yes | Initialized project graph; `null` when the operation fails. Its fields are schema- and installation-specific. |
| `Project.InternalProjectID` | `GUID` | Yes | New internal project identifier, available on a successful response. |
| `Project.ProjectID` | `string` | Yes | Generated human-readable project identifier, available on a successful response. |

Set `Accept: application/json` to receive the response as JSON. JSON property names use camel case, while the C# contract property names in this guide use Pascal case.

On success, `Project` contains the initialized project, its generated `ProjectID`, its new `InternalProjectID`, and loaded custom definitions.

The abbreviated object below represents the JSON common response from the live test. Generated identifiers, remaining project fields, and related data are redacted.

```json
{
	"operationResult": {
		"detailedMessage": null,
		"operationFailType": 0,
		"shortMessage": null,
		"successful": true
	},
	"project": {
		"internalProjectID": "<redacted generated internal project ID>",
		"projectID": "<redacted generated project ID>"
	}
}
```

## Follow-up validation

The common response was initially confirmed to be unsaved: `GetProject` returned HTTP `200` with an unsuccessful operation for its generated internal ID. The complete initialized draft was then sent as a JSON `SaveProjectParameter` with `Type: CreateNew`; `SaveProject` returned HTTP `200` with a successful operation. A second `GetProject` returned HTTP `200`, reported success, and returned the same internal ID. The temporary project was deleted after validation, and a final `GetProject` confirmed that it no longer existed.

## Errors

| Situation | Response behavior |
| --- | --- |
| Immediate database save fails | `OperationResult.Successful` is `false`; `ShortMessage` starts with `Error saving new project to database:`. |
| Related company/person loading fails | `OperationResult.Successful` is `false`; inspect `ShortMessage`. |
| Custom definition loading fails | `OperationResult.Successful` is `false`; inspect `ShortMessage`. |

When `SaveCreatedProjectInDatabase` is `false`, the returned project is not persisted. Send the complete returned project and its complete custom-definition dictionary to `SaveProject` with `Type: CreateNew` after editing.
