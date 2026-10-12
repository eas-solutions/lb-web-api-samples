param(
    [string]$DllPath,
    [string]$ApiUrl,
    [string]$Username,
    [string]$Password,
    [string]$Culture,
    [string]$Language,
    [string]$CompanyName,
    [string]$CompanyID
)

$__lbStartLocation = Get-Location
try {
    . (Join-Path $PSScriptRoot '..\Helpers\Lb-Session.ps1')
    . (Join-Path $PSScriptRoot '..\Helpers\Write-LbApiResult.ps1')

    $connectionSplat = Get-LbConnectionSplat -BoundParameters $PSBoundParameters

    $resolvedCompanyName = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'CompanyName' -VariableName 'LbCompanyName' -Fallback 'Test Company'
    $resolvedCompanyId = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'CompanyID' -VariableName 'LbCompanyID' -Fallback ('TestCompany' + (Get-Date).ToString('ddHHmmss'))

    $apiClient = & (Join-Path $PSScriptRoot '..\ImportAndLogin.ps1') @connectionSplat
    
    $initResult = $apiClient.CompaniesAndPersonsClient.InitCompanyAsync((New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.InitCompanyParameter)).GetAwaiter().GetResult()
    if (-not $initResult.OperationResult.Successful) {
        Write-LbApiResult -ApiResult $initResult
        return
    }

    $initResult.Company.Name1 = $resolvedCompanyName
    $initResult.Company.CompanyID = $resolvedCompanyId

    $saveParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.SaveCompanyParameter
    $saveParameter.Company = $initResult.Company
    $saveParameter.SaveDataMode = [EAS.LeegooBuilder.Common.DataTransferObjects.Entity.Models.SaveDataMode]::Insert

    $saveResult = $apiClient.CompaniesAndPersonsClient.SaveCompanyAsync($saveParameter).GetAwaiter().GetResult()
    Write-LbApiResult -ApiResult $saveResult
}
finally {
    if ((Get-Location).Path -ne $__lbStartLocation.Path) {
        Set-Location $__lbStartLocation
    }
}
