# GetProposal

`GetProposal` loads one proposal by its internal proposal ID. It can include related people, companies, and custom-definition values.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Proposal/GetProposal` |
| Body | JSON `GetProposalParameter` object |
| Response | JSON (`application/json`) |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token and replace `<internal-proposal-id>` with `InternalProposalID` returned by `NewProposal`, `SaveProposal`, or `GetProposals`. The localhost URL is suitable only for development.

## Minimum request

This returns the proposal without requesting custom values or related people and companies.

```bash
curl --request POST "http://localhost:56540/api/Proposal/GetProposal" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{
		"ProposalId": "<internal-proposal-id>",
		"IncludeCustomDefinitionValues": false,
		"IncludeCompaniesAndPersons": false
	}'
```

Live validation returned HTTP `200` with a successful JSON operation and the same ID returned by `SaveProposal`.

## Common editor request

The proposal editor requests both optional data sets.

```bash
curl --request POST "http://localhost:56540/api/Proposal/GetProposal" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{
		"ProposalId": "<internal-proposal-id>",
		"IncludeCustomDefinitionValues": true,
		"IncludeCompaniesAndPersons": true
	}'
```

Live validation returned HTTP `200` with a successful JSON operation and the saved proposal's internal ID.

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `ProposalId` | `GUID` | Yes | Internal proposal ID, not the human-readable `ProposalID`. |
| `IncludeCustomDefinitionValues` | `boolean` | Yes | Includes custom values in the separate `CustomDefinitionValues` dictionary. Send `false` when they are not needed. |
| `IncludeCompaniesAndPersons` | `boolean` | No | Includes related company and person data when `true`. Default: `false`. |

## Response

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `OperationResult` | [`OperationResultWeb`](../Common/OperationResult.md) | No | Common application-level result envelope for the proposal load operation. |
| `Proposal` | `Proposal` | Yes | Loaded proposal graph; `null` when the proposal cannot be loaded. Its fields are configuration- and installation-specific. |
| `Proposal.InternalProposalID` | `GUID` | Yes | Internal identifier of the loaded proposal. |
| `Proposal.ProposalID` | `string` | Yes | Human-readable proposal identifier. |
| `CustomDefinitionValues` | `Dictionary<string, SerializableObject>` | Yes | Custom values keyed by custom-property name. Populated only when `IncludeCustomDefinitionValues` is `true`; otherwise `null`. |

Set `Accept: application/json` to receive the response as JSON. JSON property names use camel case, while the C# contract property names in this guide use Pascal case.

The following is an abbreviated JSON live response. IDs, related data, custom-property names, and values are redacted.

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
	},
	"customDefinitionValues": {}
}
```

Custom values are `SerializableObject` values rather than plain JSON values. Preserve them unchanged when submitting a later `SaveProposal` request.
