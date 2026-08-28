# OperationResult

`OperationResultWeb` is the common application-level result envelope returned by LEEGOO BUILDER Web API endpoints. An HTTP request can return status `200` while the operation itself failed, so callers must inspect `Successful` before using endpoint-specific response data.

JSON responses use camelCase property names. The C# client and decoded Protocol Buffers examples use the PascalCase contract names shown below.

## Properties

| Property | JSON property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- | --- |
| `Successful` | `successful` | `boolean` | No | Computed as `OperationFailType == NoError`. This is not stored in the protobuf payload, but is available after deserialization. |
| `OperationFailType` | `operationFailType` | `OperationFailType` | No | Machine-readable outcome category. `0` means success; all other values mean failure. |
| `ShortMessage` | `shortMessage` | `string` | Yes | Concise status or error message suitable for logs or controlled user feedback. |
| `DetailedMessage` | `detailedMessage` | `string` | Yes | Additional diagnostic detail. It can contain implementation details and should not be shown to end users without review. |
| `TranslatorTerm` | `translatorTerm` | `string` | Yes | Translation key for a localized message when the endpoint supplies one. |
| `ThrowException` | `throwException` | `boolean` | No | Indicates that the originating result requested exception propagation. It is normally `false` in API responses. |
| `Exception` | `exception` | `ExceptionDto` | Yes | Structured exception detail in JSON responses. It is excluded from the protobuf payload and can expose sensitive implementation details. |

## Failure types

Raw JSON represents `OperationFailType` with the numeric values below.

| Value | Name | Meaning |
| --- | --- | --- |
| `0` | `NoError` | The operation completed successfully. |
| `10` | `NotLoggedIn` | No authenticated session is available. |
| `20` | `TokenInvalid` | The supplied authentication token is invalid. |
| `30` | `ExceptionOnServer` | An unhandled or converted server-side exception occurred. |
| `40` | `ManualFail` | The operation deliberately reported a domain or validation failure. |
| `50` | `SerializationError` | Request or response serialization failed. |
| `60` | `ModelInvalid` | Request model validation failed. |
| `70` | `RequiredParameterMissingOrNull` | A required parameter was missing or `null`. |
| `80` | `TokenExpired` | The authentication token has expired. |
| `90` | `ScriptError` | A configured script failed. |
| `100` | `SqlConnection` | A database connection failed. |

## Handling responses

1. Check the HTTP status for transport, authentication middleware, and protocol errors.
2. Deserialize the endpoint return type.
3. Check `OperationResult.Successful`.
4. Use endpoint-specific response properties only when the operation succeeded.
5. On failure, branch on `OperationFailType` when machine-readable handling is needed and use `ShortMessage` for the available summary.
6. Log `DetailedMessage` and `Exception` only through an appropriately protected diagnostic channel.

Successful JSON responses normally contain an envelope shaped like this:

```json
{
	"operationResult": {
		"detailedMessage": null,
		"exception": null,
		"operationFailType": 0,
		"shortMessage": null,
		"successful": true,
		"throwException": false,
		"translatorTerm": null
	}
}
```

In decoded protobuf responses, the same properties use PascalCase. `Successful` is recomputed from `OperationFailType`, while `Exception` is unavailable because both are excluded from the protobuf payload.