# LeegooBuilderWeb-API-Samples

This repository contains several excamples for the communication with the LEEGOO BUILDER G3 Web API.


# Powershell

## Recommendation
The easies way to try out the powershell excamples is [Visual Studio Code](https://code.visualstudio.com/). Here you can start the scripts easily, debug them and additionaly there is some intellisense.

## Preperations
The powershell examples are designed to look at the folder `bin` in the repository root for the LEEGOO BUILDER Api Client DLL´s. So you have to copy the client with all the dependencies in this folder before trying out the samples.

The following libraries are used in these examples:
- `EAS.LeegooBuilder.Web.WebApiClient.dll`
- `EAS.LeegooBuilder.Common.DataTransferObjects.dll`
- `EAS.DataTransfer.dll`

## Structure

### ImportAndLogin.ps1
This script loads the client Dll´s and connects to the api. Additionaly you need to specify the access data in this file. 


## Documentation

[LEEGOO BUILDER G3 Web Api](https://wiki.eas-cpq.de/de/leegooweb/public/web-api)