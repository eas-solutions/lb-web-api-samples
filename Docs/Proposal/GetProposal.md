# GetProposal

`GetProposal` loads one proposal by its internal proposal ID. It can include related people, companies, and custom-definition values.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Proposal/GetProposal` |
| Body | JSON `GetProposalParameter` object |
| Response | Protocol Buffers (`application/x-protobuf`) |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token and replace `<internal-proposal-id>` with `InternalProposalID` returned by `NewProposal`, `SaveProposal`, or `GetProposals`. The localhost URL is suitable only for development.

## Minimum request

This returns the proposal without requesting custom values or related people and companies.

```bash
curl --request POST "http://localhost:56540/api/Proposal/GetProposal" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/x-protobuf" \
	--data '{
		"ProposalId": "<internal-proposal-id>",
		"IncludeCustomDefinitionValues": false,
		"IncludeCompaniesAndPersons": false
	}' \
	--output get-proposal-minimum.pb
```

Live validation returned HTTP `200` with a successful decoded operation and the same ID returned by `SaveProposal`.

## Common editor request

The proposal editor requests both optional data sets.

```bash
curl --request POST "http://localhost:56540/api/Proposal/GetProposal" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/x-protobuf" \
	--data '{
		"ProposalId": "<internal-proposal-id>",
		"IncludeCustomDefinitionValues": true,
		"IncludeCompaniesAndPersons": true
	}' \
	--output get-proposal-common.pb
```

Live validation returned HTTP `200` with a successful decoded operation and the saved proposal's internal ID.

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `ProposalId` | `GUID` | Yes | Internal proposal ID, not the human-readable `ProposalID`. |
| `IncludeCustomDefinitionValues` | `boolean` | Yes | Includes custom values in the separate `CustomDefinitionValues` dictionary. Send `false` when they are not needed. |
| `IncludeCompaniesAndPersons` | `boolean` | No | Includes related company and person data when `true`. Default: `false`. |

## Response

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `OperationResult` | `OperationResultWeb` | No | Result envelope for the proposal load operation. |
| `OperationResult.Successful` | `boolean` | No | `true` when the requested proposal was loaded. Derived from `OperationFailType`. |
| `OperationResult.ShortMessage` | `string` | Yes | Concise failure or status message. |
| `OperationResult.DetailedMessage` | `string` | Yes | Additional diagnostic detail when available. |
| `Proposal` | `Proposal` | Yes | Loaded proposal graph; `null` when the proposal cannot be loaded. Its fields are configuration- and installation-specific. |
| `Proposal.InternalProposalID` | `GUID` | Yes | Internal identifier of the loaded proposal. |
| `Proposal.ProposalID` | `string` | Yes | Human-readable proposal identifier. |
| `CustomDefinitionValues` | `Dictionary<string, SerializableObject>` | Yes | Custom values keyed by custom-property name. Populated only when `IncludeCustomDefinitionValues` is `true`; otherwise `null`. |

Requesting `application/json` returned HTTP `500` with a JSON-serialization error on the tested server. Use protobuf and decode `GetProposalReturnParameter`.

The following is an abbreviated decoded live response. IDs, related data, custom-property names, and values are redacted.

```json
{
	"OperationResult": {
		"DetailedMessage": null,
		"OperationFailType": 0,
		"ShortMessage": null,
		"Successful": true
	},
	"Proposal": {
		"InternalProposalID": "<redacted internal proposal ID>",
		"ProposalID": "<redacted generated proposal ID>"
	},
	"CustomDefinitionValues": {}
}
```

Custom values are `SerializableObject` values rather than plain JSON values. Preserve them unchanged when submitting a later `SaveProposal` request. On a failed load, inspect `OperationResult.ShortMessage` before using `Proposal`.
