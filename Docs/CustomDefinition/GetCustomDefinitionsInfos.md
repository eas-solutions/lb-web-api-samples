# GetCustomDefinitionsInfos

`GetCustomDefinitionsInfos` lists the configured custom-field definitions for one entity type. Use the returned `CustomPropertyName` values when reading or saving custom values on projects and proposals.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/CustomDefinition/GetCustomDefinitionsInfos` |
| Body | JSON `GetCustomDefinitionsInfosParameter` object |
| Response | JSON `GetCustomDefinitionsInfosReturnParameter` object |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token. The localhost URL is suitable only for development.

## Project definitions

Use `Project` (`3`) to load the configured project custom fields.

```bash
curl --request POST "http://localhost:56540/api/CustomDefinition/GetCustomDefinitionsInfos" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{
		"CustomDefinitionTableType": 3
	}'
```

Live validation returned HTTP `200` with `operationResult.successful: true`. The test installation currently returned an empty `projectCustomDefinitionItems` array, so no project custom value could be added there.

## Proposal definitions

Use `Proposal` (`2`) before setting proposal custom values.

```bash
curl --request POST "http://localhost:56540/api/CustomDefinition/GetCustomDefinitionsInfos" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/json" \
	--data '{
		"CustomDefinitionTableType": 2
	}'
```

Live validation returned HTTP `200` with `operationResult.successful: true`. The test installation currently returned an empty `proposalCustomDefinitionItems` array, so no proposal custom value could be added there.

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- |
| `CustomDefinitionTableType` | `CustomDefinitionTableType` | Yes for useful output | Selects the entity type. Raw JSON uses `Component` (`1`), `Proposal` (`2`), `Project` (`3`), `Element` (`4`), `ConstructionKit` (`5`), or `Company` (`6`). |

## Response

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `operationResult` | [`OperationResultWeb`](../Common/OperationResult.md) | No | Common application-level result envelope for the lookup operation. |
| `componentCustomDefinitionItems` | `ComponentCustomDefinitionItemWebDto[]` | Yes | Definitions when `CustomDefinitionTableType` is `Component` (`1`); otherwise `null`. |
| `proposalCustomDefinitionItems` | `ProposalCustomDefinitionItemWebDto[]` | Yes | Definitions when the requested type is `Proposal` (`2`); otherwise `null`. |
| `projectCustomDefinitionItems` | `ProjectCustomDefinitionItemWebDto[]` | Yes | Definitions when the requested type is `Project` (`3`); otherwise `null`. |
| `elementCustomDefinitionItems` | `ElementCustomDefinitionItemWebDto[]` | Yes | Definitions when the requested type is `Element` (`4`); otherwise `null`. |
| `constructionKitCustomDefinitionItems` | `ConstructionKitCustomDefinitionItemWebDto[]` | Yes | Definitions when the requested type is `ConstructionKit` (`5`); otherwise `null`. |
| `companyCustomDefinitionItems` | `CompanyCustomDefinitionItemWebDto[]` | Yes | Definitions when the requested type is `Company` (`6`); otherwise `null`. |

Only the list for the requested table type is populated. Read each definition's `CustomPropertyName` and data-type metadata before creating a `SerializableObject` value for a save request.

The project request above returned this representative real response. Property casing, null values, and the empty configured-definition list are preserved.

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
	"componentCustomDefinitionItems": null,
	"proposalCustomDefinitionItems": null,
	"projectCustomDefinitionItems": [],
	"elementCustomDefinitionItems": null,
	"constructionKitCustomDefinitionItems": null,
	"companyCustomDefinitionItems": null
}
```

This endpoint is read-only. The exposed CustomDefinition API has no endpoint for creating a custom-field definition. An administrator must configure a definition before [`SaveProject`](../Project/SaveProject.md) or [`SaveProposal`](../Proposal/SaveProposal.md) can persist a value for it.
