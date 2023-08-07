set-location $PSScriptRoot

# Create client instance and login
$apiClient = & "..\ImportAndLogin.ps1"


# Create company object
$person = New-Object EAS.LeegooBuilder.Common.DataTransferObjects.Entity.PersonItem

# Set some properties
$person.Name = "Test Person at " + (Get-Date).ToString("ddHHmmss")
$person.PersonID = "Test" + (Get-Date).ToString("ddHHmmss")
$person.IsActive = 1 # 1 = true, 0 = false
$person.InternalCompanyID = "2b5de0b3-e566-ea11-82c1-f8344140dd36" # Change to your company id here (guid)

# Create parameter object
$paramter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.SavePersonParameter
$paramter.Person = $person
$paramter.SaveDataMode = [EAS.LeegooBuilder.Common.DataTransferObjects.Entity.Models.SaveDataMode]::Insert # Optional, default is auto detect

# Execute API function
$result = $apiClient.CompaniesAndPersonsClient.SavePersonAsync($paramter).GetAwaiter().GetResult()

# Show some output
if ($result.OperationResult.Successful) {
    write-host "Company Saved"
    write-host "Internal Person ID: " $result.Person.InternalPersonID
    write-host "Person ID: " $result.Person.PersonID
    write-host "External Person ID: " $result.Person.ExternalID
    write-host "Person name: " $result.Person.Name
    write-host "Person first name: " $result.Person.FirstName
} else {
    Write-Output $result.OperationResult.ShortMessage
}
