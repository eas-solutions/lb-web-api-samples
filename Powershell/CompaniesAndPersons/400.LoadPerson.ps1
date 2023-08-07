set-location $PSScriptRoot

# Create client instance and login
$apiClient = & "..\ImportAndLogin.ps1"

$paramter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.LoadPersonParameter
$paramter.InternalPersonID = "b3367f69-5372-ea11-b54b-00155d010302" # Change to your internal person id here (guid)

# Execute API function
$result = $apiClient.CompaniesAndPersonsClient.LoadPersonAsync($paramter).GetAwaiter().GetResult()

# Show some output
if ($result.OperationResult.Successful) {
    write-host "Person loaded"
    write-host "Internal Person ID: " $result.Person.InternalPersonID
    write-host "Person ID: " $result.Person.PersonID
    write-host "External Person ID: " $result.Person.ExternalID
    write-host "Person name: " $result.Person.Name
    write-host "Person first name: " $result.Person.FirstName
} else {
    Write-Output $result.OperationResult.ShortMessage
}
