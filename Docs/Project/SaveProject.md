# SaveProject

`SaveProject` creates a project or updates an existing one. It can also persist custom definition values supplied separately from the project object.

For a new project, start with [`CreateNewProject`](CreateNewProject.md). For an update, start with [`GetProject`](GetProject.md), modify the returned object, and send the complete project back. Sending a partial object during an update can clear values that were not included.

## Endpoint

| Item           | Value                                  |
| -------------- | -------------------------------------- |
| Method         | `POST`                                 |
| URL            | `/api/Project/SaveProject`             |
| Body           | Protocol Buffers `SaveProjectParameter` object      |
| Response       | Protocol Buffers (`application/x-protobuf`) |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token before running the example. The localhost URL is suitable only for development.

## Create requests

Do not create a project from a partial object containing only `ProjectID`. Live validation showed that this can persist a malformed project with an empty `InternalProjectID`. The validation record was removed after the test.

For a create workflow, call `CreateNewProject`, retain the complete initialized project, assign the required business values, set `Type` to `CreateNew`, and serialize the complete `SaveProjectParameter` with the API client. A minimal create curl example is intentionally not provided because the partial request is unsafe.

## Common update request

This follows the editor's load-edit-save flow without dropping fields. Load the project with both GetProject include flags set to `true`, change only the desired values, and serialize this object with the deployed contracts:

```json
{
	"Type": "UpdateExisting",
	"SkipDataValidation": true,
	"Project": {
		"InternalProjectID": "<redacted internal project ID>",
		"ProjectID": "Aktuellste Demo",
		"<remaining project fields>": "<preserved>"
	},
	"CustomDefinitionValues": {
		"<custom property name>": "<preserved SerializableObject>"
	}
}
```

This JSON is an abbreviated representation of the object to serialize, not an HTTP JSON body. Save the protobuf-serialized request as `save-project-request.pb`, then send the exact tested curl request:

```bash
curl --request POST "http://localhost:56540/api/Project/SaveProject" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/x-protobuf" \
	--header "Accept: application/x-protobuf" \
	--data-binary @save-project-request.pb \
	--output save-project-response.pb
```

The live test changed the project with ProjectID `Aktuelle Demo` to `Aktuellste Demo`. SaveProject returned HTTP `200` with a successful operation. A follow-up GetProject returned HTTP `200`, confirmed the new ProjectID, and confirmed that the one custom-definition entry was preserved.

The first live attempt used `SkipDataValidation: false` and reached the endpoint, but failed because this server could not map `SystemViewSchema` to `SystemViewSchemaWebDto`. The retry used the frontend's current workaround, `SkipDataValidation: true`. Use `false` when validation is correctly configured; use `true` only when this known server configuration defect applies and the caller performs equivalent validation.

## Saving custom values

Custom values require an existing project custom-field definition. First use [`GetCustomDefinitionsInfos`](../CustomDefinition/GetCustomDefinitionsInfos.md) with `CustomDefinitionTableType: 3`, then load the project with `IncludeCustomDefinitionValues: true`. Use a returned definition's `CustomPropertyName` as the dictionary key and create a type-correct `SerializableObject` value.

```csharp
var values = project.CustomDefinitionsPropertyNameAndValueDictionary;
values["<custom-property-name>"] = new SerializableObject("API documentation validation");

var save = new SaveProjectParameter
{
	Type = SaveProjectType.UpdateExisting,
	Project = project,
	CustomDefinitionValues = values,
	SkipDataValidation = true
};
```

Serialize the complete `save` object as protobuf and send it with the curl request above. `SaveProject` loads all existing project custom values and treats dictionary entries that are absent or supplied as `null` as deletions. Preserve every unchanged entry in `CustomDefinitionValues`; arbitrary keys do not create definitions or values.

The live test installation currently has no configured project custom definitions, so this workflow could not add a project custom value there.

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `Type` | `SaveProjectType` | Yes | `CreateNew` inserts a project; `UpdateExisting` updates the project identified by `Project.InternalProjectID`. |
| `Project` | `Project` | Yes | Project to save. `ProjectID` must not be empty. Send the complete loaded/initialized object to preserve its values. |
| `SkipDataValidation` | `boolean` | No | Skips update validation when `true`. Default: `false`. The tested server currently requires `true` because its update validator fails during system-view mapping. |
| `CustomDefinitionValues` | `Dictionary<string, SerializableObject>` | No | Custom values keyed by custom property name. During an update, existing values missing from this dictionary are marked for deletion. Preserve and return the complete dictionary loaded for the project. |
| `SchemaName` | `string` | No | Schema used to validate updates instead of the authenticated user's default schema. |

`Type` accepts `CreateNew` (`0`) and `UpdateExisting` (`1`). The protobuf serializer writes the enum value.

> [!WARNING]
> Omitting `CustomDefinitionValues` from an update can delete all existing custom definition values. Load them with `GetProject`, preserve every unchanged entry, and send the complete dictionary back.

## Response

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `OperationResult` | `OperationResultWeb` | No | Result envelope for the save operation. |
| `OperationResult.Successful` | `boolean` | No | `true` when the project was saved successfully. Derived from `OperationFailType`. |
| `OperationResult.ShortMessage` | `string` | Yes | Concise failure or status message. |
| `OperationResult.DetailedMessage` | `string` | Yes | Additional diagnostic detail when available. |
| `Project` | `Project` | Yes | Server-side representation of the saved project; `null` when saving fails. Its fields are schema- and installation-specific. |
| `Project.InternalProjectID` | `GUID` | Yes | Internal identifier of the saved project. |
| `Project.ProjectID` | `string` | Yes | Human-readable identifier after the save operation. |

SaveProject accepts and returns Protocol Buffers. Raw JSON requests currently return HTTP `500` because the server detects a JSON property-name collision while building metadata for the project entity graph. Use the official WebApiClient or the deployed contracts and `protobuf-net` to serialize `SaveProjectParameter` and deserialize `SaveProjectReturnParameter`.

Check `OperationResult.Successful` before using the returned `Project`. On success, `Project` contains the saved server-side representation. The abbreviated object below represents the decoded live response; it is not the raw protobuf HTTP body. All fields except the changed ProjectID are omitted or redacted.

```json
{
	"OperationResult": {
		"DetailedMessage": null,
		"OperationFailType": 0,
		"ShortMessage": null,
		"Successful": true
	},
	"Project": {
		"InternalProjectID": "<redacted internal project ID>",
		"ProjectID": "Aktuellste Demo"
	}
}
```

## Errors

| Situation | `OperationResult.ShortMessage` |
| --- | --- |
| `Project.ProjectID` is empty | `Project ID cannot be empty` |
| `CreateNew` uses an existing `ProjectID` | `Project with same project ID already existing.` |
| `UpdateExisting` cannot find `Project.InternalProjectID` | `Could not find source project in Database. (Deleted?)` |
| Update validation fails | Contains the validation error returned for the changed fields. |
| Custom definition persistence fails | Starts with `Error saving custom definitions, please check the input fields.` |
| Project persistence fails | Starts with `Error saving project, please check the input fields.` |

Project fields and custom definitions depend on the installation. Treat the objects returned by `CreateNewProject` or `GetProject` as the source of truth rather than building a project DTO from a fixed field list.
