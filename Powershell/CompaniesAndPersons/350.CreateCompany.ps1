set-location $PSScriptRoot

# Create client instance and login
$apiClient = & "..\ImportAndLogin.ps1"


# Create company object
$company = New-Object EAS.LeegooBuilder.Common.DataTransferObjects.Entity.CompanyItem

# Set some properties
$company.Name1 = "Test Company"
$company.CompanyID = "TestCompany"+ (Get-Date).ToString("ddHHmmss")

# Create parameter object
$paramter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.SaveCompanyParameter
$paramter.Company = $company
$paramter.SaveDataMode = [EAS.LeegooBuilder.Common.DataTransferObjects.Entity.Models.SaveDataMode]::Insert # Optional, default is auto detect

# Execute API function
$result = $apiClient.CompaniesAndPersonsClient.SaveCompanyAsync($paramter).GetAwaiter().GetResult()

# Show some output
if ($result.OperationResult.Successful) {
    write-host "Company Saved"
    write-host "Internal Company ID: " $result.Company.InternalCompanyID
    write-host "Company ID: " $result.Company.CompanyID
    write-host "External Company ID: " $result.Company.ExternalCompanyID
    write-host "Company name1: " $result.Company.Name1
} else {
    Write-Output $result.OperationResult.ShortMessage
}
