# SaveProposal

`SaveProposal` updates an existing proposal and can merge its custom-definition values. For a new proposal, start with `NewProposal` and preserve its complete returned object.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Proposal/SaveProposal` |
| Body | Protocol Buffers `SaveProposalParameter` object |
| Response | Protocol Buffers (`application/x-protobuf`) |
| Authentication | `Authorization: Bearer <access-token>` |

The localhost URL is suitable only for development. JSON requests and responses cannot serialize the full proposal entity graph on the tested server; use the deployed contracts or `EAS.LeegooBuilder.Web.WebApiClient` to serialize and deserialize Protocol Buffers.

## Save a returned proposal

Deserialize `new-proposal.pb` from `NewProposal`, construct `SaveProposalParameter` with its complete `Proposal`, set both include flags to `false`, and serialize it as `save-proposal-request.pb`. Then send this tested curl request:

```bash
curl --request POST "http://localhost:56540/api/Proposal/SaveProposal" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/x-protobuf" \
	--header "Accept: application/x-protobuf" \
	--data-binary @save-proposal-request.pb \
	--output save-proposal-response.pb
```

Live validation returned HTTP `200` with content type `application/x-protobuf`. Decoding `SaveProposalReturnParameter` reported success and returned the saved proposal. A subsequent `GetProposal` returned HTTP `200` and the same internal proposal ID.

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `Proposal` | `Proposal` | Yes | Complete proposal to update. `InternalProposalID` must identify an existing proposal. Send the complete object returned by `NewProposal` or `GetProposal` to avoid clearing mapped fields. |
| `IncludeCustomDefinitionValues` | `boolean` | No | When `true`, applies `CustomDefinitionValues` and includes custom values in the reloaded proposal. Default: `false`. |
| `IncludeCompaniesAndPersons` | `boolean` | No | Includes related company and person data in the reloaded proposal. Default: `false`. |
| `CustomDefinitionValues` | `Dictionary<string, SerializableObject>` | Required when updating custom values | Values keyed by custom-property name. With custom values enabled, entries missing from this dictionary are deleted. Preserve all unchanged entries. |

## Response

The abbreviated object below is a decoded protobuf response from the live test, not raw JSON. IDs and installation-specific proposal fields are redacted.

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
	}
}
```

The current implementation rejects a missing or empty proposal with `No valid proposal given` and returns `Error saving proposal, existing proposal not found` when the internal ID is not in the database.
