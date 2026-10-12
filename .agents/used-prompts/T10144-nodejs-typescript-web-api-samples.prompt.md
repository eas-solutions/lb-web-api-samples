## Task: T10144 Node.js / TypeScript sample code for the LeegooBuilder Web API

![Open Task T10144](https://esp.eas-cpq.de/TaskDetail?T10144)

## task Description
Create Node.js / TypeScript sample code in the repository https://github.com/eas-solutions/lb-web-api-samples for the LeegooBuilder Web API.

Scope:
- Login
- GetProjects and GetProject
- GetProposals and GetProposal
- LoadPersons and Init/SavePerson
- LoadCompanies and Init/SaveCompany
- Exclusively request and process JSON responses; do not use binary responses.

Authentication:
The sample code must contain a TokenManager that handles authentication as well as providing the token for authenticated API calls. The documentation must clearly state that the TokenManager is a usable reference example and that customers may implement or adapt it according to their own requirements.

## Suggested Solution

The examples should be created in the "Examples/TypeScript" For reference, look at the existing documentation in the "Docs" directory aswell as there is a running swagger documentation at http://localhost:56540/swagger/index.html. use your internal browser or curl or whatever you need to use to use that as a reference. For further reference, ths whole project running the api is available as a submodule in directory "lb-web". The running instance is an external instance, not build from that code files.

I want a directory for each Controller (logical section) containing example pythong scripts for each endpoint

Add a readme file as an entry point for the python examples in the TypeScript directory

The all created code samples need to be tested and confirmed working against the available demo-api. the demo credentials that work are Administrator // admin