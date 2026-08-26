# NewProposal

`NewProposal` initializes a proposal for editing. Use `SaveProposal` to persist the complete returned proposal.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Proposal/NewProposal` |
| Body | JSON `NewProposalParameter` object |
| Response | Protocol Buffers (`application/x-protobuf`) |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token. The localhost URL is suitable only for development.

## New proposal without a reference

Load a construction-kit header through the API client and use its `MasterStructureID`. The implementation reloads that header by ID; the remaining header properties are not read by this endpoint.

```bash
curl --request POST "http://localhost:56540/api/Proposal/NewProposal" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/x-protobuf" \
	--data '{
		"CreationMode": 0,
		"DestinationProjectId": "<internal-project-id>",
		"ConstructionKitHeader": {
			"MasterStructureID": "<construction-kit-master-structure-id>"
		}
	}' \
	--output new-proposal.pb
```

Live validation returned HTTP `200` with content type `application/x-protobuf`. Decoding `NewProposalReturnParameter` reported success and returned a proposal with non-empty `InternalProposalID` and `ProposalID`. The complete returned proposal was then sent to `SaveProposal`, which returned HTTP `200` and persisted it.

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `CreationMode` | `ProposalCreationMode` | Yes | `NewProposalWithoutReference` (`0`), `NewAppendix` (`1`), or `NewProposalFromTemplate` (`2`). Raw JSON uses numeric values. |
| `DestinationProjectId` | `GUID` | Yes | Internal ID of the project that will own the proposal. |
| `ConstructionKitHeader` | `ConstructionKitHeaderWeb` | Required for mode `0` | Supply at least the selected header's `MasterStructureID`; the server loads the configured header and initializes the proposal configuration. |
| `SourceProposalId` | `GUID` or `null` | Required for modes `1` and `2` | Internal source proposal ID for an appendix or template-based proposal. |
| `ProposalId` | `string` | No | Full generated ID. When omitted, the server calls `GenerateProposalId`. |
| `ProposalIdMainPart` | `string` | No | Main part that corresponds to a supplied `ProposalId`. |
| `ProposalIdAppendix` | `string` | No | Appendix part that corresponds to a supplied `ProposalId`. |
| `UserId` | `GUID` | No | Present in the contract but ignored by the current implementation; ownership comes from the authenticated user. |

## Response

This endpoint's entity graph cannot currently be serialized as JSON on the tested server: requesting `application/json` returned HTTP `500` with a JSON-serialization error. Request protobuf as shown above and decode `NewProposalReturnParameter` with `EAS.LeegooBuilder.Web.WebApiClient` or the deployed protobuf contract.

The abbreviated object below is a decoded live response, not the raw HTTP body. Generated identifiers and installation-specific fields are redacted.

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

Do not construct a partial `Proposal` to save. Preserve the complete decoded result and send it to `SaveProposal`.
