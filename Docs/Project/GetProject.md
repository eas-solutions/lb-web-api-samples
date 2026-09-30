# GetProject

`GetProject` returns one project identified by its internal project ID. It always loads the project's favorite status and can also load related companies, persons, users, and custom definition values.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Project/GetProject` |
| Body | JSON `GetProjectParameter` object |
| Response | JSON (`application/json`) |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token and replace `<internal-project-id>` with an `InternalProjectID` returned by `GetProjects`. The localhost URL is suitable only for development.

## Minimum request

This returns the project without explicitly requesting related companies, persons, or custom definition values.

```bash
curl --request POST "http://localhost:56540/api/Project/GetProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{
		"ProjectId": "<internal-project-id>"
	}'
```

Both include flags default to `false` when omitted from JSON.

Live validation returned HTTP `200` with content type `application/json`. The operation was successful, the requested project was returned, and `customDefinitionValues` was `null`.

## Common editor request

The project editor loads related people and companies plus custom fields. Custom values are returned separately because they are not included in the normal serialized project object.

```bash
curl --request POST "http://localhost:56540/api/Project/GetProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{
		"ProjectId": "<internal-project-id>",
		"IncludeCompaniesAndPersons": true,
		"IncludeCustomDefinitionValues": true
	}'
```

Live validation returned HTTP `200` with content type `application/json`. The operation was successful and returned the requested project plus one custom-definition entry. The returned internal ID was then used in a successful `SaveProject` request, and a follow-up `GetProject` confirmed the saved ProjectID.

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `ProjectId` | `GUID` | Yes | Internal project ID. This is `InternalProjectID`, not the human-readable `ProjectID`. |
| `IncludeCompaniesAndPersons` | `boolean` | No | Loads related companies, persons, and users when `true`. The default JSON value is `false`. |
| `IncludeCustomDefinitionValues` | `boolean` | No | Loads custom field values and returns them in `CustomDefinitionValues` when `true`. The default is `false`. |

## Response

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `OperationResult` | [`OperationResultWeb`](../Common/OperationResult.md) | No | Common application-level result envelope for the project load operation. |
| `Project` | `Project` | Yes | Loaded project graph; `null` when the project cannot be loaded. Its fields are schema- and installation-specific. |
| `Project.InternalProjectID` | `GUID` | Yes | Internal identifier of the loaded project. |
| `Project.ProjectID` | `string` | Yes | Human-readable project identifier. |
| `CustomDefinitionValues` | `Dictionary<string, SerializableObject>` | Yes | Custom values keyed by custom-property name. Populated only when `IncludeCustomDefinitionValues` is `true`; otherwise `null`. |

Set `Accept: application/json` to receive the response as JSON. JSON property names use camel case, while the C# contract property names in this guide use Pascal case.

When custom values were requested, merge `CustomDefinitionValues` into your editing model by property name if needed.

The abbreviated object below represents the JSON common response from the live test. The internal ID, remaining project fields, related records, custom property name, and custom value are redacted.

```json
{
	"operationResult": {
		"detailedMessage": null,
		"operationFailType": 0,
		"shortMessage": null,
		"successful": true
	},
	"project": {
		"internalProjectID": "<redacted internal project ID>",
		"projectID": "Aktuellste Demo"
	},
	"customDefinitionValues": {
		"<redacted custom property name>": "<redacted SerializableObject>"
	}
}
```

Each populated `CustomDefinitionValues` entry is a `SerializableObject`, not a plain JSON value. Preserve these objects unchanged when a custom field is not edited. Project fields depend on the installation's project schema.

## Errors

A malformed GUID is rejected during request binding. If the project cannot be loaded, `OperationResult.Successful` is `false`; inspect `OperationResult.ShortMessage` for the reason.