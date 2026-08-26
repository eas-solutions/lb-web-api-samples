# API Documentation

This directory contains practical documentation for the LEEGOO BUILDER Web API. Endpoint guides are grouped by their purpose.

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
- [GetCustomDefinitionValuesInfos](CustomDefinition/GetCustomDefinitionValuesInfos.md): Inspect the currently unimplemented custom-field value metadata endpoint.
