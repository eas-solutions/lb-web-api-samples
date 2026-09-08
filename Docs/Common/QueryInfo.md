# QueryInfo

`QueryInfo` is the response counterpart to [`QuerySettings`](QuerySettings.md). List endpoints use it to report the total number of matching records and, when requested, the position of a selected item.

Whether `QueryInfo` itself is present depends on the endpoint and requested response content. Its nullable properties can remain `null` when the corresponding query feature was not requested or could not be calculated.

## Properties

| Property | Type | Nullable / omitted | Description |
| --- | --- | --- | --- |
| `RecordsTotal` | `integer` | Yes | Number of records after filters, search, and `DistinctBy`, but before `Skip` and `Take`. Populated when a non-null `QuerySettings` reaches the shared paging stage. |
| `SelectedItemAtIndex` | `integer` | Yes | Zero-based position of the first item matching `QuerySettings.QueryIndex` before paging. `null` when no index was requested or calculation failed. |
| `SelectedItemAtPage` | `integer` | Yes | One-based page containing the selected item, calculated only when `QueryIndex` and `Take` are supplied. |

For a zero-based selected index $i$ and page size $t$, the page is:

$$
\operatorname{page}=\left\lceil\frac{i+1}{t}\right\rceil
$$

For example, index `2` with `Take: 1` is on page `3`.

## Example

This decoded protobuf response fragment came from a live `GetProjects` index request with three matching records:

```json
{
	"QueryInfo": {
		"RecordsTotal": 3,
		"SelectedItemAtIndex": 2,
		"SelectedItemAtPage": 3
	}
}
```

The live request returned HTTP `200` and a successful [`OperationResult`](OperationResult.md). The item index was calculated after sorting and before the `Take: 1` page was applied.

## Using the metadata

- Use `RecordsTotal` to calculate the number of pages and to populate a grid's total count.
- Use `SelectedItemAtPage` to navigate directly to the page containing a selected record.
- Do not use the number of returned list items as the total when paging is active.
- Treat `null` index fields as unavailable metadata rather than index `0`.
- The current index implementation can return `-1` when the value is not found; callers should treat negative indexes and nonpositive pages as not found.