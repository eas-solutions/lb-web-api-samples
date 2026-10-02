param(
    [string]$ApiUrl
)

$__lbStartLocation = Get-Location
try {
    . (Join-Path $PSScriptRoot '..\Helpers\Lb-Session.ps1')
    . (Join-Path $PSScriptRoot '..\Helpers\Write-LbApiResult.ps1')

    $dllPath = Join-Path $PSScriptRoot '..\..\lb-web\Bin\Client'
    $resolvedApiUrl = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'ApiUrl' -VariableName 'LbApiUrl' -Fallback 'http://localhost:56540/api/'

    Import-LbClientDlls -DllPath $dllPath

    $apiClient = New-Object EAS.LeegooBuilder.Web.WebApiClient.WebApiClient -ArgumentList ([Uri]$resolvedApiUrl)

    $parameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Authentication.LoadLoginInfosParameter
    $result = $apiClient.AuthenticationClient.LoadLoginInfosAsync($parameter).GetAwaiter().GetResult()

    Write-LbApiResult -ApiResult $result
}
finally {
    if ((Get-Location).Path -ne $__lbStartLocation.Path) {
        Set-Location $__lbStartLocation
    }
}
