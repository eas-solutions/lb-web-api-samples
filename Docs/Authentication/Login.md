# Login

`Login` authenticates a user and returns an access token for subsequent API requests. The endpoint itself is anonymous; do not send an existing bearer token.

This guide focuses on the normal LEEGOO username/password login used by the frontend. Other authentication methods depend on server configuration and EAS-specific credential encryption.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Authentication/Login` |
| Body | JSON `LoginParameter` object |
| Authentication | None |

Use HTTPS outside a local development environment because `UnencryptedPassword` contains the password as plain text in the JSON request. The endpoint does not enforce HTTPS itself.

## Username and password login

This is both the minimum effective request and the request shape used by the frontend. `LoginMethod` is omitted because it defaults to `LeegooUser`.

The following request was verified against the development API at `http://localhost:56540` using its default test account. Do not use these credentials in a production system.

```bash
curl --request POST "http://localhost:56540/api/Authentication/Login" \
	--header "Content-Type: application/json" \
	--data '{
		"Username": "Administrator",
		"UnencryptedPassword": "admin",
		"Language": "en-GB",
		"Culture": "en-GB"
	}'
```

`Language` must match an available `SPRACHE_IF` language and `Culture` must match a configured system profile. Applications can obtain the available values from `POST /api/Authentication/LoadLoginInfos`.

## Request properties

Properties used by the normal username/password request are listed first.

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `Username` | `string` | Yes for `LeegooUser` | Login name. It is also passed to custom authentication when that mode is enabled. |
| `UnencryptedPassword` | `string` | Yes for the example | Plain-text password used when `EncryptedPasswort` is not supplied. Send it only over HTTPS. |
| `Language` | `string` | Yes | Login language. The request fails when it is not found in the `SPRACHE_IF` system codes. |
| `Culture` | `string` | Yes | Regional culture, such as `en-GB` or `de-DE`. The request fails when no matching system profile exists. |
| `LoginMethod` | `LoginMethod` | No | Authentication mode. Defaults to `LeegooUser` (`10`). Other values are `Ssid` (`20`) and `Custom` (`30`). Server settings can force `Custom` regardless of this value. |
| `EncryptedPasswort` | `string` | No | EAS-encrypted password, or the encrypted SSID when `LoginMethod` is `Ssid`. This is an alternative to `UnencryptedPassword` and requires the EAS encryption library. The contract uses this spelling. |
| `TokenExpireTimeInMinutes` | `integer` or `null` | No | Retained in the request contract, but the current login implementation does not read it. Token lifetime comes from the API settings. |
| `UseSsidLogin` | `boolean` | No | Deprecated compatibility flag that changes the method to `Ssid` when `true`. Use `LoginMethod` instead. |
| `EncryptedSsid` | `string` | No | Deprecated and not read by the current SSID dispatch path. Use `EncryptedPasswort` with `LoginMethod: 20` through a compatible EAS client. |

`Password` and `Ssid` sometimes appear in C# examples, but they are client-side helper properties and are not serialized to JSON. The PowerShell sample sets `Password`; the client library encrypts it into `EncryptedPasswort` before sending the request.

## Response

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `operationResult` | `OperationResultWeb` | No | Result envelope for the authentication attempt. |
| `operationResult.successful` | `boolean` | No | `true` when authentication completed successfully. Derived from `operationFailType`. |
| `operationResult.shortMessage` | `string` | Yes | Concise failure or status message. |
| `operationResult.detailedMessage` | `string` | Yes | Additional diagnostic detail when available. |
| `renewalToken` | `string` | Yes | Token for renewing an expired access token. The current implementation returns `null`. |
| `user` | `UserWeb` | Yes | Authenticated user; absent or `null` when login fails. |
| `user.id` | `GUID` | Yes | Internal identifier of the authenticated user. |
| `user.name` | `string` | Yes | Login name of the authenticated user. |
| `user.token` | `string` | Yes | Bearer access token; present after a successful login. Treat it as a secret. |
| `user.loginCulture` | `string` | Yes | Culture selected for the authenticated session. |
| `user.loginLanguage` | `string` | Yes | Language selected for the authenticated session. |
| `user.claims` | `Dictionary<string, string[]>` | Yes | Authorization claims grouped by claim name. |

Check `operationResult.successful` before reading `user`. The access token is returned in `user.token` (`User.Token` in the C# client) and must be sent with later requests as `Authorization: Bearer <token>`.

The verified request returned HTTP `200` with the response below. The access token and claim details are redacted, but property casing, null values, and the remaining values match the real response.

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
	},
	"renewalToken": null,
	"user": {
		"id": "364cba76-dad4-e711-83ed-0028f84c637c",
		"name": "administrator",
		"password": null,
		"token": "<redacted access token>",
		"loginCulture": "en-GB",
		"loginLanguage": "en-GB",
		"claims": {
			"<redacted claim name>": [
				"<redacted claim value>"
			]
		}
	}
}
```

The live response contained four claim groups; their names and values are omitted from the example.

The returned token was also verified with `GET /api/Authentication/Validate`; that request returned HTTP `200`, `successful: true`, and `shortMessage: "Token validation successful"`.

The C# response contract declares `RenewalToken`, serialized as `renewalToken`, but the current login implementation does not populate it. Use `user.token` as the access token; do not assume a renewal token is available from this endpoint.

## Errors

Login failures are returned in the normal response envelope rather than requiring a bearer token. Inspect both `OperationResult.ShortMessage` and `OperationResult.DetailedMessage`.

| Situation | Response behavior |
| --- | --- |
| Unknown or missing `Language` | `OperationResult.Successful` is `false` and `ShortMessage` is `Language not found`. |
| Unknown or missing `Culture` | `OperationResult.Successful` is `false` and `ShortMessage` is `Profile not found`. |
| No login languages are configured | `ShortMessage` is `No login languages available`. |
| No culture profiles are configured | `ShortMessage` is `No profiles available`. |
| Username or password is rejected | `Successful` is `false`; the security service commonly returns `UserWithLoginNameNotFound` or `PasswordIsWrong`. |
| User is inactive | `Successful` is `false`; the security service commonly returns `UserIsPassive`. |
| Authentication succeeds but no matching LEEGOO user exists | `ShortMessage` starts with `Login failed, the user with the username`. |

Do not log request bodies or passwords. Store `user.token` as a secret and send it only over HTTPS.