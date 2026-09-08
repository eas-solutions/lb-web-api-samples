# GetProposals

`GetProposals` returns proposals for one project or, when requested, across the projects visible to the authenticated user. `Content` selects the response sections to load.

## Endpoint

| Item | Value |
| --- | --- |
| Method | `POST` |
| URL | `/api/Proposal/GetProposals` |
| Body | JSON `GetProposalsParameter` object |
| Response | Protocol Buffers (`application/x-protobuf`) |
| Authentication | `Authorization: Bearer <access-token>` |

Set `ACCESS_TOKEN` to a valid access token and replace `<internal-project-id>` with a project's `InternalProjectID`. The localhost URL is suitable only for development.

## Minimum request

This loads proposal objects for one project.

```bash
curl --request POST "http://localhost:56540/api/Proposal/GetProposals" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/x-protobuf" \
	--data '{
		"ProjectId": "<internal-project-id>",
		"Content": [20],
		"LoadOptions": [10]
	}' \
	--output get-proposals-minimum.pb
```

Live validation returned HTTP `200` with a successful decoded operation. The response included the validation proposals saved in the selected project.

## Common grid request

The frontend proposal grid requests proposals, custom values, related people and companies, project data, and a result page.

```bash
curl --request POST "http://localhost:56540/api/Proposal/GetProposals" \
	--header "Authorization: Bearer ${ACCESS_TOKEN}" \
	--header "Content-Type: application/json" \
	--header "Accept: application/x-protobuf" \
	--data '{
		"ProjectId": "<internal-project-id>",
		"Content": [20, 40, 70, 80],
		"LoadOptions": [10],
		"QuerySettings": {
			"Take": 50
		}
	}' \
	--output get-proposals-common.pb
```

Live validation returned HTTP `200` with a successful decoded operation and listed the saved test proposal. `QueryInfo` supplies the total record count for paged calls.

## Request properties

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `Content` | `GetProposalsContent[]` | Yes | Selects response sections. Raw JSON uses the numeric values below. |
| `LoadOptions` | `ProposalLoadType[]` | Yes | Required by the contract. The current controller does not read these values. |
| `ProjectId` | `GUID` or `null` | Yes unless `LoadAllProposals` or `OnlyFavorites` is `true` | Limits results to one project. |
| `LoadAllProposals` | `boolean` | No | Searches all projects visible to the authenticated user when `true`. Default: `false`. |
| `OnlyFavorites` | `boolean` | No | Searches only the current user's favorite proposals. Default: `false`. |
| `QuerySettings` | [`QuerySettings`](../Common/QuerySettings.md) | No | Common filtering, searching, sorting, selection, index, and paging settings. |
| `SelectedView` | `string` | No | System-view identifier used for grid metadata and layout loading. |
| `Language` | `string` | No | Present in the contract but not read by the current implementation. |

| Content | JSON value | Response effect |
| --- | --- | --- |
| `All` | `10` | Expands to every content value. Prefer an explicit list. |
| `Proposals` | `20` | Proposal objects in `Proposals`. |
| `UserSettings` | `30` | Saved grid layout in `Layout`. |
| `CustomDefinitionValues` | `40` | Custom values keyed by internal proposal ID. |
| `SystemViews` | `50` | Proposal-grid metadata in `SystemViewWeb`. |
| `TableData` | `60` | Legacy grid table JSON in `Data`. |
| `PersonsAndCompanies` | `70` | Related values on the returned proposal objects. |
| `Project` | `80` | Project data on the returned proposal objects. |

`LoadOptions` accepts `AllProposals` (`10`), `OwnProposal` (`20`), `OwnBusifieldProposals` (`30`), `OwnSupplierProposals` (`40`), and the four `OwnUserGroupProposals...` variants (`50` through `80`). The controller currently ignores this property.

## Response

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `OperationResult` | [`OperationResultWeb`](../Common/OperationResult.md) | No | Common application-level result envelope for the proposal-list operation. |
| `Proposals` | `Proposal[]` | Yes | Proposal graphs selected by `Content: Proposals` (`20`). |
| `QueryInfo` | [`QueryInfo`](../Common/QueryInfo.md) | Yes | Total-count and selected-item metadata for `QuerySettings`; omitted when no proposal list is loaded. |
| `CustomDefinitionValues` | `Dictionary<GUID, Dictionary<string, SerializableObject>>` | Yes | Custom values by proposal ID and custom-property name, selected by `Content: CustomDefinitionValues` (`40`). |
| `Layout` | `GridLayoutWeb` | Yes | Saved grid layout, selected by `Content: UserSettings` (`30`). |
| `SystemViewWeb` | `SystemViewWebDto[]` | Yes | Proposal-grid metadata, selected by `Content: SystemViews` (`50`). |
| `Data` | `string` | Yes | Legacy DevExpress grid JSON, selected by `Content: TableData` (`60`). |

Requesting `application/json` returned HTTP `500` with a JSON-serialization error on the tested server. Use protobuf and decode `GetProposalsReturnParameter`.

The following is an abbreviated decoded live response. IDs, project data, people, companies, and custom values are redacted.

```json
{
	"OperationResult": {
		"DetailedMessage": null,
		"OperationFailType": 0,
		"ShortMessage": null,
		"Successful": true
	},
	"Proposals": [
		{
			"InternalProposalID": "<redacted internal proposal ID>",
			"ProposalID": "<redacted generated proposal ID>"
		}
	]
}
```

The `ProjectId` omission check runs before data loading. Without `ProjectId`, `LoadAllProposals`, or `OnlyFavorites`, the operation fails with `No project ID was given`.
