# GetCustomDefinitionValuesInfos

`GetCustomDefinitionValuesInfos` is intended to return the available values for one custom-field definition. It is not implemented by the current server and does not return value data.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/CustomDefinition/GetCustomDefinitionValuesInfos` |
| Body | JSON `GetCustomDefinitionValuesInfosParameter` object |
| Response | JSON `GetCustomDefinitionValuesInfosReturnParameter` object |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token. The localhost URL is suitable only for development.

## Request

Use the definition's internal ID and table type returned by [`GetCustomDefinitionsInfos`](GetCustomDefinitionsInfos.md). The request shape is valid, but the current implementation returns an unsuccessful operation.

```bash
curl --request POST "http://localhost:56540/api/CustomDefinition/GetCustomDefinitionValuesInfos" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{
		"CustomDefinitionTableType": 3,
		"CustomDefinitionId": "<custom-definition-id>",
		"Language": "en-GB"
	}'
```

Live validation used a structurally valid project request and returned HTTP `200`, but `operationResult.successful` was `false`. The server reported `The method or operation is not implemented.` No follow-up value lookup is available until this endpoint is implemented.

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- |
| `CustomDefinitionTableType` | `CustomDefinitionTableType` | Yes | Entity type that owns the definition. Raw JSON uses `Proposal` (`2`), `Project` (`3`), and the other numeric values listed in [GetCustomDefinitionsInfos](GetCustomDefinitionsInfos.md). |
| `CustomDefinitionId` | `GUID` | Yes | Internal ID of the configured custom-field definition. |
| `Language` | `string` | Yes | Language requested for localized value metadata, such as `en-GB`. |

## Response

The return contract exposes only `operationResult`; it has no property for custom value data. The response below is representative of the live failure. Exception details are redacted, preserving their JSON types and structure.

```json
{
	"operationResult": {
		"detailedMessage": "<redacted exception details>",
		"exception": {
			"typeName": "<redacted exception type>",
			"message": "<redacted exception message>",
			"stackTrace": "<redacted stack trace>",
			"innerException": null
		},
		"operationFailType": 30,
		"shortMessage": "The method or operation is not implemented.",
		"successful": false,
		"throwException": false,
		"translatorTerm": null
	}
}
```

The controller directly throws `NotImplementedException`. This is an API implementation gap, not an invalid-definition or language error. Do not use this route to validate or populate custom values until the server implements it.
