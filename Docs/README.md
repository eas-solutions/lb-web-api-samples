# API Documentation

This directory contains practical documentation for the LEEGOO BUILDER Web API. Endpoint guides are organized by controller, so start with the controller that owns the endpoint you need.

## ProjectController

- [CreateNewProject](Project/CreateNewProject.md): Initialize a project for editing or create and persist it immediately.
- [GetProject](Project/GetProject.md): Load one project by its internal ID, optionally with related and custom data.
- [GetProjects](Project/GetProjects.md): Retrieve projects visible to the authenticated user, with optional grid-related data and paging.
- [SaveProject](Project/SaveProject.md): Create a project or update an existing project and its custom values.

Additional endpoint guides will be added to their controller directories as they become available.