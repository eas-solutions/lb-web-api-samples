# NewProposal

`NewProposal` initializes a proposal for editing. Use `SaveProposal` to persist the complete returned proposal.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Proposal/NewProposal` |
| Body | JSON `NewProposalParameter` object |
| Response | JSON (`application/json`) |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token. The localhost URL is suitable only for development.

## New proposal without a reference

Load a construction-kit header through the API client and use its `MasterStructureID`. The implementation reloads that header by ID; the remaining header properties are not read by this endpoint.

```bash
curl --request POST "http://localhost:56540/api/Proposal/NewProposal" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{
		"CreationMode": 0,
		"DestinationProjectId": "<internal-project-id>",
		"ConstructionKitHeader": {
			"MasterStructureID": "<construction-kit-master-structure-id>"
		}
	}'
```

Live validation returned HTTP `200` with content type `application/json`. The operation reported success and returned a proposal with non-empty `internalProposalID` and `proposalID`. The complete returned proposal was then sent to `SaveProposal`, which returned HTTP `200` and persisted it.

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

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `OperationResult` | [`OperationResultWeb`](../Common/OperationResult.md) | No | Common application-level result envelope for proposal initialization. |
| `Proposal` | `Proposal` | Yes | Initialized proposal graph; `null` when initialization fails. Its fields are configuration- and installation-specific. |
| `Proposal.InternalProposalID` | `GUID` | Yes | New internal proposal identifier, available on a successful response. |
| `Proposal.ProposalID` | `string` | Yes | Generated human-readable proposal identifier, available on a successful response. |

Set `Accept: application/json` to receive the response as JSON. JSON property names use camel case, while the C# contract property names in this guide use Pascal case.

The abbreviated object below is a JSON live response. Generated identifiers and installation-specific fields are redacted.

```json
{
	"operationResult": {
		"detailedMessage": null,
		"operationFailType": 0,
		"shortMessage": null,
		"successful": true
	},
	"proposal": {
		"internalProposalID": "<redacted internal proposal ID>",
		"proposalID": "<redacted generated proposal ID>"
	}
}
```

Do not construct a partial `Proposal` to save. Preserve the complete JSON result and send it to `SaveProposal`.
