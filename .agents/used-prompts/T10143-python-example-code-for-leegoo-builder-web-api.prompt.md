## Task: T10143 Python Example Code for the LeegooBuilder Web API

![Open Task T10143](https://esp.eas-cpq.de/TaskDetail?tasknumber=10143)

## Task Description
Create Python examples for the LeegooBuilder Web API in this repository. Cover login, project and proposal retrieval, and person and company load and init/save operations. Request and process JSON responses exclusively; do not use binary responses.

Include a reusable TokenManager example that handles login and supplies tokens for authenticated API calls. The documentation must explain that the TokenManager is a usable example and that customers may implement or adapt it to their own requirements.

Add a separate minimal UI example that calls GetProjects and displays the loaded projects.

## Suggested Solution

The examples should be created in the "Examples/Python"
For reference, look at the existing documentation in the "Docs" directory aswell as there is a running swagger documentation at http://localhost:56540/swagger/index.html. use your internal browser or curl or whatever you need to use to use that as a reference. For further reference, ths whole project running the api is available as a submodule in directory "lb-web". The running instance is an external instance, not build from that code files.









I want a directory for each Controller (logical section) containing example pythong scripts for each endpoint

Add a readme file as an entry point for the python examples in the Python directory