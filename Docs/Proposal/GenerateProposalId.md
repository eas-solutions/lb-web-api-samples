# GenerateProposalId

`GenerateProposalId` runs the configured proposal-ID generator for a project. It generates an ID without creating or saving a proposal.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Proposal/GenerateProposalId` |
| Body | JSON `GenerateProposalIdParameter` object |
| Response | JSON `GenerateProposalIdReturnParameter` object |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token and replace `<internal-project-id>` with a project's `InternalProjectID`. The localhost URL is suitable only for development.

## New proposal ID

Use `NewProposalWithoutReference` (`0`) to reserve the values that `NewProposal` would generate for a new proposal in the project.

```bash
curl --request POST "http://localhost:56540/api/Proposal/GenerateProposalId" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{
		"CreationMode": 0,
		"ProjectId": "<internal-project-id>"
	}'
```

Live validation returned HTTP `200` with `operationResult.successful: true` and non-empty `proposalId`, `proposalIdMain`, and `proposalIdAppendix`. A subsequent `NewProposal` request in the same project also completed successfully through its own ID-generation path.

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `CreationMode` | `ProposalCreationMode` | Yes | `NewProposalWithoutReference` (`0`), `NewAppendix` (`1`), or `NewProposalFromTemplate` (`2`). Raw JSON uses the numeric values. |
| `ProjectId` | `GUID` | Yes | Internal project ID for the proposal-ID script. |
| `OriginProposalId` | `GUID` or `null` | Required for `NewAppendix` | Source proposal's internal ID when creating an appendix. It is otherwise ignored by the ID generator. |

## Response

Check `operationResult.successful` before using the generated parts. The following is a redacted representative response from the live request; property names and null values are preserved.

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
	"proposalId": "<redacted generated proposal ID>",
	"proposalIdAppendix": "<redacted generated appendix part>",
	"proposalIdMain": "<redacted generated main part>"
}
```

The response is only an ID suggestion. It does not reserve the ID transactionally and does not persist a proposal.
