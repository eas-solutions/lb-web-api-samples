---
agent: agent
description: Test documented API curl examples against a running API and update the documentation with verified, redacted responses.
---

# Validate Documented API Endpoint

Validate the request examples in `<DOCUMENTATION_FILE>` against the already running API at `<BASE_URL>` using curl. Use the test credentials, IDs, and other values supplied with this task.

## Requirements

1. Read the current documentation file before editing it. Inspect the endpoint route, parameter and return contracts, execution logic, and real frontend or sample usage.
2. Identify every documented endpoint request example. Test the minimum request and the common request when both exist.
3. Compare the effective property sets of the minimum and common requests. If they are identical after removing values that merely restate wire defaults, keep only one example.
4. Execute the documented requests with `curl` against `<BASE_URL>`. Keep the method, route, headers, and JSON body aligned with the Markdown example.
5. Capture the HTTP status and parse the response as JSON. Confirm the operation reports success and that the expected response data is present.
6. When the response returns a token, download link, identifier, or other value intended for a follow-up operation, perform a cheap follow-up curl request when one is available to confirm that value works.
7. If an example fails, determine whether the documentation, test data, server configuration, or API implementation is responsible. Do not update the guide to claim success until the request succeeds.
8. After successful tests, update `<DOCUMENTATION_FILE>` with:
   - The exact working curl request, using the supplied non-production test values.
   - The observed HTTP status.
   - A representative real response preserving actual JSON property casing, null values, and structure.
   - A response-properties table with `Property`, `Type`, `Nullable / omitted`, and `Description` columns. Base it on the return contract and implementation; describe request-controlled fields as conditional and keep installation-specific entity graphs at their contract-object level.
   - A short statement describing any successful follow-up validation.
   - Clear environment-specific caveats, such as localhost HTTP being suitable only for development.
9. Redact access tokens, renewal tokens, passwords in responses, cookies, claim details, personal data, and other secrets. Never print raw secrets to chat or terminal output. Keep placeholders structurally faithful to the original JSON type.
10. Do not invent response fields or values. Explicitly identify contract properties that the current implementation ignores or leaves unpopulated.
11. Update the documentation index only when the endpoint guide is not already linked.

## Validation

Before finishing:

1. Parse every inline JSON request and response added or changed in the guide.
2. Confirm the documented route, request fields, defaults, and response paths against source.
3. Confirm each tested curl command has a successful live result.
4. Confirm the response-properties table covers the response envelope and every top-level return property, including whether each is nullable or omitted.
5. Check all relative Markdown links and run `git diff --check` for the documentation files.
6. Run editor diagnostics for every changed Markdown file.
7. Report which examples were tested, their HTTP status, whether follow-up validation passed, and exactly which sensitive values were redacted.