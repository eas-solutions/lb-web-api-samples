param(
    [string]$DllPath,
    [string]$ApiUrl,
    [string]$Username,
    [string]$Password,
    [string]$Culture,
    [string]$Language,
    [Parameter(Mandatory = $true)]
    [string]$InternalCompanyID,
    [string]$PersonName,
    [string]$PersonID
)

$__lbStartLocation = Get-Location
try {
    . (Join-Path $PSScriptRoot '..\Helpers\Lb-Session.ps1')
    . (Join-Path $PSScriptRoot '..\Helpers\Write-LbApiResult.ps1')

    $connectionSplat = Get-LbConnectionSplat -BoundParameters $PSBoundParameters

    $resolvedPersonName = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'PersonName' -VariableName 'LbPersonName' -Fallback ('Test Person at ' + (Get-Date).ToString('ddHHmmss'))
    $resolvedPersonId = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'PersonID' -VariableName 'LbPersonID' -Fallback ('Test' + (Get-Date).ToString('ddHHmmss'))

    $apiClient = & (Join-Path $PSScriptRoot '..\ImportAndLogin.ps1') @connectionSplat
    
    $initResult = $apiClient.CompaniesAndPersonsClient.InitPersonAsync((New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.InitPersonParameter)).GetAwaiter().GetResult()
    if (-not $initResult.OperationResult.Successful) {
        Write-LbApiResult -ApiResult $initResult
        return
    }

    $initResult.Person.Name = $resolvedPersonName
    $initResult.Person.PersonID = $resolvedPersonId
    $initResult.Person.IsActive = 1
    $initResult.Person.InternalCompanyID = $InternalCompanyID

    $saveParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.SavePersonParameter
    $saveParameter.Person = $initResult.Person
    $saveParameter.SaveDataMode = [EAS.LeegooBuilder.Common.DataTransferObjects.Entity.Models.SaveDataMode]::Insert

    $saveResult = $apiClient.CompaniesAndPersonsClient.SavePersonAsync($saveParameter).GetAwaiter().GetResult()
    Write-LbApiResult -ApiResult $saveResult
}
finally {
    if ((Get-Location).Path -ne $__lbStartLocation.Path) {
        Set-Location $__lbStartLocation
    }
}
