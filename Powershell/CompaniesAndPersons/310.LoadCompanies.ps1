set-location $PSScriptRoot

# Create client instance and login
$apiClient = & "..\ImportAndLogin.ps1"

$paramter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.LoadCompaniesParameter
$paramter.Name = "gmbh"

# Execute API function
$result = $apiClient.CompaniesAndPersonsClient.LoadCompaniesAsync($paramter).GetAwaiter().GetResult()

# Show some output
if ($result.OperationResult.Successful) {
    write-host "Companies loaded"
    foreach ($company in $result.Companies.Value) {
        write-host "Internal Company ID: " $company.InternalCompanyID
        write-host "Company ID: " $company.CompanyID
        write-host "External Company ID: " $company.ExternalCompanyID
        write-host "Company name1: " $company.Name1
        write-host "Company name2: " $company.Name2
        write-host "Company name3: " $company.Name3
    }
} else {
    Write-Output $result.OperationResult.ShortMessage
}
