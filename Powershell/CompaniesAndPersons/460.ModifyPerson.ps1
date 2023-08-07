set-location $PSScriptRoot

# Create client instance and login
$apiClient = & "..\ImportAndLogin.ps1"

$paramter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.LoadPersonParameter
$paramter.InternalPersonID = "181b11af-2735-ee11-850b-010101010000" # Must be a valid internal person id (guid)

# Execute API function (LoadPerson)
$result = $apiClient.CompaniesAndPersonsClient.LoadPersonAsync($paramter).GetAwaiter().GetResult()


# exit if not successful
if (!$result.OperationResult.Successful) {
    Write-Output $result.OperationResult.ShortMessage
    exit    
}

# modify person
$result.Person.Name = "Modified Person Name at ({0})" -f (Get-Date).ToString("ddHHmmss")

# Create save parameter object
$paramter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.SavePersonParameter
$paramter.Person = $result.Person
$paramter.SaveDataMode = [EAS.LeegooBuilder.Common.DataTransferObjects.Entity.Models.SaveDataMode]::Update # Optional, default is auto detect

# Execute API function
$result = $apiClient.CompaniesAndPersonsClient.SavePersonAsync($paramter).GetAwaiter().GetResult()

# Show some output
if ($result.OperationResult.Successful) {
    write-host "Person Saved"
    write-host "Internal Person ID: " $result.Person.InternalPersonID
    write-host "Person ID: " $result.Person.PersonID
    write-host "External Person ID: " $result.Person.ExternalID
    write-host "Person name: " $result.Person.Name
    write-host "Person first name: " $result.Person.FirstName
} else {
    Write-Output $result.OperationResult.ShortMessage
}
