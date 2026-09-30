# SaveProposal

`SaveProposal` updates an existing proposal and can merge its custom-definition values. For a new proposal, start with `NewProposal` and preserve its complete returned object.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Proposal/SaveProposal` |
| Body | JSON `SaveProposalParameter` object |
| Response | JSON (`application/json`) |
| Authentication | `Authorization: Bearer <access-token>` |

The localhost URL is suitable only for development. JSON property names use camel case, while the C# contract property names in this guide use Pascal case.

## Save a returned proposal

Save the complete `proposal` returned by `NewProposal` in a `SaveProposalParameter`, set both include flags to `false`, and write it to `save-proposal-request.json`. Then send this tested curl request:

```bash
curl --request POST "http://localhost:56540/api/Proposal/SaveProposal" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data @save-proposal-request.json \
	--output save-proposal-response.json
```

Live validation returned HTTP `200` with content type `application/json`. The operation reported success and returned the saved proposal. A subsequent `GetProposal` returned HTTP `200` and the same internal proposal ID.

## Saving custom values

Custom values require an existing proposal custom-field definition. First use [`GetCustomDefinitionsInfos`](../CustomDefinition/GetCustomDefinitionsInfos.md) with `CustomDefinitionTableType: 2`, then load the proposal with `IncludeCustomDefinitionValues: true` and preserve the returned values.

```csharp
foreach (var value in getProposal.CustomDefinitionValues)
	getProposal.Proposal.CustomDefinitionsPropertyNameAndValueDictionary[value.Key] = value.Value;

var values = getProposal.Proposal.CustomDefinitionsPropertyNameAndValueDictionary;
values["<custom-property-name>"] = new SerializableObject("API documentation validation");

var save = new SaveProposalParameter(getProposal.Proposal)
{
	IncludeCustomDefinitionValues = true,
	CustomDefinitionValues = values
};
```

Save the complete `save` object as JSON and send it with the curl request above. With `IncludeCustomDefinitionValues: true`, entries from an existing dictionary that are not present in `CustomDefinitionValues` are deleted. Preserve unchanged entries. Arbitrary keys do not create definitions or values.

The live test installation currently has no configured proposal custom definitions, so this workflow could not add a proposal custom value there.

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `Proposal` | `Proposal` | Yes | Complete proposal to update. `InternalProposalID` must identify an existing proposal. Send the complete object returned by `NewProposal` or `GetProposal` to avoid clearing mapped fields. |
| `IncludeCustomDefinitionValues` | `boolean` | No | When `true`, applies `CustomDefinitionValues` and includes custom values in the reloaded proposal. Default: `false`. |
| `IncludeCompaniesAndPersons` | `boolean` | No | Includes related company and person data in the reloaded proposal. Default: `false`. |
| `CustomDefinitionValues` | `Dictionary<string, SerializableObject>` | Required when updating custom values | Values keyed by custom-property name. With custom values enabled, entries missing from this dictionary are deleted. Preserve all unchanged entries. |

## Response

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `OperationResult` | [`OperationResultWeb`](../Common/OperationResult.md) | No | Common application-level result envelope for the save operation. |
| `Proposal` | `Proposal` | Yes | Server-side representation of the saved proposal; `null` when saving fails. Its fields are configuration- and installation-specific. |
| `Proposal.InternalProposalID` | `GUID` | Yes | Internal identifier of the saved proposal. |
| `Proposal.ProposalID` | `string` | Yes | Human-readable identifier after the save operation. |

The abbreviated object below is a JSON response from the live test. IDs and installation-specific proposal fields are redacted.

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

The current implementation rejects a missing or empty proposal with `No valid proposal given` and returns `Error saving proposal, existing proposal not found` when the internal ID is not in the database.
