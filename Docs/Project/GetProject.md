# GetProject

`GetProject` returns one project identified by its internal project ID. It always loads the project's favorite status and can also load related companies, persons, users, and custom definition values.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Project/GetProject` |
| Body | JSON `GetProjectParameter` object |
| Authentication | `Authorization: Bearer <access-token>` |

Set `BASE_URL` to your API address, `ACCESS_TOKEN` to a valid access token, and replace the example GUID with an `InternalProjectID` returned by `GetProjects`.

## Minimum request

This returns the project without explicitly requesting related companies, persons, or custom definition values.

```bash
curl --request POST "${BASE_URL}/api/Project/GetProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--data '{
		"ProjectId": "3f2504e0-4f89-41d3-9a0c-0305e82c3301"
	}'
```

Both include flags default to `false` when omitted from JSON.

## Common editor request

The project editor loads related people and companies plus custom fields. Custom values are returned separately because they are not included in the normal serialized project object.

```bash
curl --request POST "${BASE_URL}/api/Project/GetProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--data '{
		"ProjectId": "3f2504e0-4f89-41d3-9a0c-0305e82c3301",
		"IncludeCompaniesAndPersons": true,
		"IncludeCustomDefinitionValues": true
	}'
```

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `ProjectId` | `GUID` | Yes | Internal project ID. This is `InternalProjectID`, not the human-readable `ProjectID`. |
| `IncludeCompaniesAndPersons` | `boolean` | No | Loads related companies, persons, and users when `true`. The default JSON value is `false`. |
| `IncludeCustomDefinitionValues` | `boolean` | No | Loads custom field values and returns them in `CustomDefinitionValues` when `true`. The default is `false`. |

## Response and errors

Check `OperationResult.Successful` before using `Project`. When custom values were requested, merge `CustomDefinitionValues` into your editing model by property name if needed.

```json
{
	"OperationResult": {
		"Successful": true
	},
	"Project": {
		"InternalProjectID": "3f2504e0-4f89-41d3-9a0c-0305e82c3301",
		"ProjectID": "P-1001",
		"Description": "Sample project"
	},
	"CustomDefinitionValues": {}
}
```

Each populated `CustomDefinitionValues` entry is a `SerializableObject`, not a plain JSON value. Preserve these objects unchanged when a custom field is not edited. Project fields depend on the installation's project schema. A malformed GUID is rejected during request binding. If the project cannot be loaded, `OperationResult.Successful` is `false`; inspect `OperationResult.ShortMessage` for the reason.