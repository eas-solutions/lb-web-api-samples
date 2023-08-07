set-location $PSScriptRoot

# Create client instance and login
$apiClient = & "..\ImportAndLogin.ps1"

$paramter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.LoadCompanyParameter
$paramter.InternalCompanyID = "48d3a755-3a10-ea11-b54f-00155d010303"

# Execute API function
$result = $apiClient.CompaniesAndPersonsClient.LoadCompanyAsync($paramter).GetAwaiter().GetResult()

# Show some output
if ($result.OperationResult.Successful) {
    write-host "Company loaded"
    write-host "Internal Company ID: " $result.Company.InternalCompanyID
    write-host "Company ID: " $result.Company.CompanyID
    write-host "External Company ID: " $result.Company.ExternalCompanyID
    write-host "Company name1: " $result.Company.Name1
    write-host "Company name2: " $result.Company.Name2
    write-host "Company name3: " $result.Company.Name3
} else {
    Write-Output $result.OperationResult.ShortMessage
}
