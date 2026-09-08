# QuerySettings

`QuerySettings` is the common request model for filtering, searching, sorting, selecting, and paging list endpoints. Endpoints can support only part of the contract, so consult the endpoint guide as well as this reference.

The shared query engine applies operations in this order:

1. `Where` filters.
2. `Search` terms.
3. `Sorts`.
4. `DistinctBy`.
5. `QueryIndex` calculation.
6. `Skip` and `Take` paging.

The corresponding response metadata is described in [`QueryInfo`](QueryInfo.md).

## Properties

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `Skip` | `integer` | Yes | Number of matching records to skip. Applied after filtering, search, sorting, and distinct selection. |
| `Take` | `integer` | Yes | Maximum number of matching records to return. |
| `Sorts` | `QuerySort[]` | Yes | Ordered sort definitions. The first item is the primary sort; later items are secondary sorts. |
| `Where` | `QueryWhere[]` | Yes | Field predicates. Top-level entries are applied successively and therefore combine as `AND`. |
| `Search` | `QuerySearch[]` | Yes | Free-text searches across string fields. Matching fields are combined with `OR`. |
| `QueryIndex` | `QueryIndex` | Yes | Finds a record's position after filtering/search/sort/distinct and before paging. |
| `DistinctBy` | `string` | Yes | Property path used to group equal values and retain the first record in each group. |
| `PropertySelection` | `PropertySelection` | Yes | Property names an endpoint can use to limit database projection. It does not change query order and support is endpoint-specific. |
| `Includes` | `QueryIncludeBase[]` | Yes | Framework-level related-data post-processing metadata. The shared query operator does not apply it directly; do not send it unless the endpoint explicitly documents support. |

## Paging and sorting

`QuerySort.Direction` uses `1` for `Ascending` and `2` for `Descending`. Property names and paths must exist on the endpoint's queried entity type.

This request fragment sorts projects by `ProjectID`, skips the first 20 matching records, and returns at most 20 records:

```json
{
	"QuerySettings": {
		"Skip": 20,
		"Take": 20,
		"Sorts": [
			{
				"PropertyName": "ProjectID",
				"Direction": 1
			}
		]
	}
}
```

Live validation against `POST /api/Project/GetProjects` returned HTTP `200`, a successful operation, and `QueryInfo.RecordsTotal` equal to the number of matches before paging.

## Field filters

Each `QueryWhere` has the following properties:

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `Field` | `string` | Required for a simple predicate | Property name or nested property path to filter. |
| `Operator` | `PredicateOperator` | No | Comparison operator. Defaults to `Equals` (`3`). |
| `Value` | `SerializableObject` | Required for a simple predicate | Typed comparison value represented by `StringValue`, `TypeCode`, `TypeName`, and `IsEnum`. |
| `Condition` | `PredicateCondition` | No | `And` (`1`) or `Or` (`2`). For complex predicates, controls how nested `Predicate` entries combine. |
| `IgnoreCase` | `boolean` | No | Declared case-sensitivity preference. The current shared `Where` implementation invokes string operations with their case-insensitive default and does not pass this value through. |
| `IsComplex` | `boolean` | No | When `true`, combine the nested `Predicate` entries instead of evaluating `Field` and `Value` directly. |
| `Predicate` | `QueryWhere[]` | Yes | Nested predicates for a complex `AND` or `OR` group. |

Raw JSON operator values are:

| Value | Operator | Typical field types |
| --- | --- | --- |
| `1` | `LessThan` | Number, date, enum |
| `2` | `LessThanOrEqual` | Number, date, enum |
| `3` | `Equals` | String, GUID, number, date, enum, boolean |
| `4` | `NotEquals` | String, number, date, enum, boolean |
| `5` | `GreaterThanOrEqual` | Number, date, enum |
| `6` | `GreaterThan` | Number, date, enum |
| `7` | `StartsWith` | String |
| `8` | `EndsWith` | String |
| `9` | `Contains` | String |
| `10` | `Undefined` | No comparison; do not use in requests |
| `20` | `Between` | Declared by the contract but not implemented by the current shared query engine |

This tested filter returns projects whose `ProjectID` contains `Demo`:

```json
{
	"QuerySettings": {
		"Take": 50,
		"Where": [
			{
				"Condition": 1,
				"Field": "ProjectID",
				"IgnoreCase": true,
				"IsComplex": false,
				"Operator": 9,
				"Value": {
					"StringValue": "Demo",
					"TypeCode": 18,
					"TypeName": "System.String",
					"IsEnum": false
				}
			}
		]
	}
}
```

Live validation against `POST /api/Project/GetProjects` returned HTTP `200`, a successful operation, and two matching records on the tested installation.

## Free-text search

Each `QuerySearch` supplies a `Key`, a list of string `Fields`, and `IgnoreCase`. The current shared engine performs a `Contains` search and combines valid fields with `OR`. The contract's `QuerySearch.Operator` property is currently not read.

```json
{
	"QuerySettings": {
		"Search": [
			{
				"Fields": ["ProjectID", "Description"],
				"IgnoreCase": true,
				"Key": "Demo"
			}
		]
	}
}
```

## Locating an item

`QueryIndex` identifies one record by `Field` and a typed `Value`. The result is returned through `QueryInfo.SelectedItemAtIndex`; when `Take` is supplied, `SelectedItemAtPage` is calculated as well.

```json
{
	"QuerySettings": {
		"Take": 20,
		"Sorts": [
			{
				"PropertyName": "ProjectID",
				"Direction": 1
			}
		],
		"QueryIndex": {
			"Field": "InternalProjectID",
			"Value": {
				"StringValue": "<internal-project-id>",
				"TypeCode": 1,
				"TypeName": "System.Guid",
				"IsEnum": false
			}
		}
	}
}
```

Live validation used a real project ID returned by the API. With three sorted matches and `Take: 1`, the last project produced `SelectedItemAtIndex: 2` and `SelectedItemAtPage: 3`.

## Practical guidance

- Always provide a stable `Sorts` order when paging; otherwise page membership can change between requests.
- Treat property names as contract names. Unknown or unsupported property paths can fail query translation or be ignored, depending on the operation.
- Keep `Take` bounded for interactive lists.
- Prefer simple top-level `Where` entries unless an `OR` group is required.
- Verify `PropertySelection`, `DistinctBy`, custom-property paths, and `Includes` against the specific endpoint before relying on them.