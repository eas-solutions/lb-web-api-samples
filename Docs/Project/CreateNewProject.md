# CreateNewProject

`CreateNewProject` builds and initializes a new project, assigns a new internal ID, and runs the configured project-ID generation script. It can return the initialized project as a draft or save it immediately.

For the usual create-and-edit workflow, request an unsaved draft, let the user edit it, and persist it with [`SaveProject`](SaveProject.md).

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Project/CreateNewProject` |
| Body | JSON `CreateNewProjectParameter` object |
| Response | Protocol Buffers (`application/x-protobuf`) |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token before running the examples. The localhost URL is suitable only for development.

## Minimum request

This initializes a project without saving it. All request properties have usable defaults, so an empty JSON object is sufficient.

```bash
curl --request POST "http://localhost:56540/api/Project/CreateNewProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/x-protobuf" \
	--data '{}' \
	--output create-new-project-minimum.pb
```

Live validation returned HTTP `200` with content type `application/x-protobuf`. The decoded operation was successful and returned an initialized draft with non-empty generated `InternalProjectID` and `ProjectID` values. No custom-definition entries were configured in the test installation.

## Common editor request

The frontend starts with an unsaved project and requests related company and person data for its editor. It relies on the default `false` value of `SaveCreatedProjectInDatabase`.

```bash
curl --request POST "http://localhost:56540/api/Project/CreateNewProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/x-protobuf" \
	--data '{
		"IncludeCompaniesAndPersons": true
	}' \
	--output create-new-project-common.pb
```

Live validation returned HTTP `200` with content type `application/x-protobuf`. The decoded operation was successful and returned an initialized draft with non-empty generated identifiers. No custom-definition entries were configured in the test installation.

## Create and save immediately

Set `SaveCreatedProjectInDatabase` to `true` when the initialized project should be persisted by this endpoint instead of returned as an unsaved draft. `ProjectName` sets the initial description. The configured generation script still determines the returned `ProjectID`.

```bash
curl --request POST "http://localhost:56540/api/Project/CreateNewProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/x-protobuf" \
	--data '{
		"ProjectName": "API documentation validation",
		"SaveCreatedProjectInDatabase": true
	}' \
	--output create-new-project-saved.pb
```

Live validation returned HTTP `200` with content type `application/x-protobuf`. The decoded operation was successful and returned non-empty generated identifiers. A follow-up `GetProject` returned HTTP `200`, reported success, and returned the same internal ID, confirming that the project was persisted. The temporary validation project was then deleted; `GetProjects` returned HTTP `200` and confirmed that it was no longer listed.

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
| `OperationResult` | `OperationResultWeb` | No | Result envelope for the initialization or immediate-save operation. |
| `OperationResult.Successful` | `boolean` | No | `true` when the project was initialized successfully. Derived from `OperationFailType`. |
| `OperationResult.ShortMessage` | `string` | Yes | Concise failure or status message. |
| `OperationResult.DetailedMessage` | `string` | Yes | Additional diagnostic detail when available. |
| `Project` | `Project` | Yes | Initialized project graph; `null` when the operation fails. Its fields are schema- and installation-specific. |
| `Project.InternalProjectID` | `GUID` | Yes | New internal project identifier, available on a successful response. |
| `Project.ProjectID` | `string` | Yes | Generated human-readable project identifier, available on a successful response. |

The supported response format for this endpoint is Protocol Buffers. Save curl's response to a `.pb` file as shown above, or use `EAS.LeegooBuilder.Web.WebApiClient`, which deserializes `CreateNewProjectReturnParameter`.

After deserialization, check `OperationResult.Successful`. On success, `Project` contains the initialized project, its generated `ProjectID`, its new `InternalProjectID`, and loaded custom definitions.

The abbreviated object below represents the decoded common response from the live test. It is not the raw HTTP body; the raw body is protobuf. Generated identifiers, remaining project fields, and related data are redacted.

```json
{
	"OperationResult": {
		"DetailedMessage": null,
		"OperationFailType": 0,
		"ShortMessage": null,
		"Successful": true
	},
	"Project": {
		"InternalProjectID": "<redacted generated internal project ID>",
		"ProjectID": "<redacted generated project ID>"
	}
}
```

Requesting a JSON response currently returns HTTP `500` for these examples because the server detects a JSON property-name collision in the project entity graph. Do not omit the protobuf `Accept` header until that server-side serialization issue is fixed.

## Follow-up validation

The common response was initially confirmed to be unsaved: `GetProject` returned HTTP `200` with an unsuccessful operation for its generated internal ID. The complete initialized draft was then serialized as a protobuf `SaveProjectParameter` with `Type: CreateNew`; `SaveProject` returned HTTP `200` with a successful operation. A second `GetProject` returned HTTP `200`, reported success, and returned the same internal ID. The temporary project was deleted after validation, and a final `GetProject` confirmed that it no longer existed.

## Errors

| Situation | Response behavior |
| --- | --- |
| Immediate database save fails | `OperationResult.Successful` is `false`; `ShortMessage` starts with `Error saving new project to database:`. |
| Related company/person loading fails | `OperationResult.Successful` is `false`; inspect `ShortMessage`. |
| Custom definition loading fails | `OperationResult.Successful` is `false`; inspect `ShortMessage`. |

When `SaveCreatedProjectInDatabase` is `false`, the returned project is not persisted. Send the complete returned project and its complete custom-definition dictionary to `SaveProject` with `Type: CreateNew` after editing. Use protobuf for the SaveProject request; its project graph cannot currently be sent as raw JSON.
