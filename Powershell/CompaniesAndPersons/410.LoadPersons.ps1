set-location $PSScriptRoot

# Create client instance and login
$apiClient = & "..\ImportAndLogin.ps1"

$paramter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.LoadPersonsParameter
$paramter.CompanyID = "2b5de0b3-e566-ea11-82c1-f8344140dd36" # Change to your company id here (guid)

# Execute API function
$result = $apiClient.CompaniesAndPersonsClient.LoadPersonsAsync($paramter).GetAwaiter().GetResult()

# Show some output
if ($result.OperationResult.Successful) {
    write-host "Companies loaded"
    foreach ($person in $result.Persons.Value) {
        write-host "Internal Person ID: " $person.InternalPersonID
        write-host "Person ID: " $person.PersonID
        write-host "External Person ID: " $person.ExternalID
        write-host "Person name: " $person.Name
        write-host "Person first name: " $person.FirstName
    }
} else {
    Write-Output $result.OperationResult.ShortMessage
}
