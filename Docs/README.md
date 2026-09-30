# API Documentation

This directory contains practical documentation for the LEEGOO BUILDER Web API. Endpoint guides are grouped by their purpose.

## Common Concepts

- [OperationResult](Common/OperationResult.md): Interpret the common success and failure envelope returned by API operations.
- [QuerySettings](Common/QuerySettings.md): Filter, search, sort, select, and page list requests.
- [QueryInfo](Common/QueryInfo.md): Read total-count and selected-item metadata returned for dynamic queries.

## Authentication Endpoints

- [Login](Authentication/Login.md): Authenticate a user and obtain the access token required by other endpoints.

## Project Endpoints

- [CreateNewProject](Project/CreateNewProject.md): Initialize a project for editing or create and persist it immediately.
- [GetProject](Project/GetProject.md): Load one project by its internal ID, optionally with related and custom data.
- [GetProjects](Project/GetProjects.md): Retrieve projects visible to the authenticated user, with optional grid-related data and paging.
- [SaveProject](Project/SaveProject.md): Create a project or update an existing project and its custom values.

## Proposal Endpoints

- [GenerateProposalId](Proposal/GenerateProposalId.md): Generate proposal identifier parts for a project.
- [NewProposal](Proposal/NewProposal.md): Initialize a proposal from a construction kit, template, or source proposal.
- [SaveProposal](Proposal/SaveProposal.md): Persist an initialized or updated proposal.
- [GetProposals](Proposal/GetProposals.md): List proposals for a project or the authenticated user's visible projects.
- [GetProposal](Proposal/GetProposal.md): Load one proposal by its internal ID.

## Custom Definition Endpoints

- [GetCustomDefinitionsInfos](CustomDefinition/GetCustomDefinitionsInfos.md): List configured custom fields for an entity type.

## Using Examples in Windows PowerShell

Examples labelled `bash` use the Unix `curl` command and the `\` line-continuation character. In Windows PowerShell, `curl` is an alias for `Invoke-WebRequest`, so pasting those examples directly produces parameter and parsing errors. This is expected and does not indicate an API error.

To call the actual curl executable, use `curl.exe` and replace each Bash `\` continuation with a PowerShell backtick (`` ` ``):

```powershell
curl.exe --request POST "http://localhost:56540/api/Authentication/Login" `
	--header "Content-Type: application/json" `
	--data '{
		"Username": "Administrator",
		"UnencryptedPassword": "admin",
		"Language": "en-GB",
		"Culture": "en-GB"
	}'
```

Do not add spaces after a continuation backtick; PowerShell requires it to be the final character on its line.

If an error names `Invoke-WebRequest`, PowerShell received `curl` rather than `curl.exe`. Check that the first word of the command is exactly `curl.exe` and rerun the example.
