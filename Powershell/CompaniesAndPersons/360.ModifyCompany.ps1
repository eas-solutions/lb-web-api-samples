set-location $PSScriptRoot

# Create client instance and login
$apiClient = & "..\ImportAndLogin.ps1"

$paramter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.LoadCompanyParameter
$paramter.InternalCompanyID = "0f965f43-1d35-ee11-850b-010101010000" # Must be a valid internal company id (guid)

# Execute API function (LoadCompany)
$result = $apiClient.CompaniesAndPersonsClient.LoadCompanyAsync($paramter).GetAwaiter().GetResult()


# exit if not successful
if (!$result.OperationResult.Successful) {
    Write-Output $result.OperationResult.ShortMessage
    exit    
}

# modify company
$result.Company.Name1 = "Modified Company Name at ({0})" -f (Get-Date).ToString("ddHHmmss")

# Create save parameter object
$paramter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.SaveCompanyParameter
$paramter.Company = $result.Company
$paramter.SaveDataMode = [EAS.LeegooBuilder.Common.DataTransferObjects.Entity.Models.SaveDataMode]::Update # Optional, default is auto detect

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
