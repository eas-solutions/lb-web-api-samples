param(
    [string]$DllPath,
    [string]$ApiUrl,
    [string]$Username,
    [string]$Password,
    [string]$Culture,
    [string]$Language,
    [Parameter(Mandatory = $true)]
    [string]$InternalCompanyID
)

$__lbStartLocation = Get-Location
try {
    . (Join-Path $PSScriptRoot '..\Helpers\Lb-Session.ps1')
    . (Join-Path $PSScriptRoot '..\Helpers\Write-LbApiResult.ps1')

    $connectionSplat = Get-LbConnectionSplat -BoundParameters $PSBoundParameters

    $apiClient = & (Join-Path $PSScriptRoot '..\ImportAndLogin.ps1') @connectionSplat

    $parameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.LoadPersonsParameter
    $parameter.CompanyID = $InternalCompanyID

    $result = $apiClient.CompaniesAndPersonsClient.LoadPersonsAsync($parameter).GetAwaiter().GetResult()
    Write-LbApiResult -ApiResult $result
}
finally {
    if ((Get-Location).Path -ne $__lbStartLocation.Path) {
        Set-Location $__lbStartLocation
    }
}
