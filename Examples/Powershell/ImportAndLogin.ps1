param(
    [string]$DllPath,
    [string]$ApiUrl,
    [string]$Username,
    [string]$Password,
    [string]$Culture,
    [string]$Language
)

$__lbStartLocation = Get-Location
try {
    . (Join-Path $PSScriptRoot 'Helpers\Lb-Session.ps1')
    . (Join-Path $PSScriptRoot 'Helpers\Write-LbApiResult.ps1')

    $previousApiUrl = if (Get-Variable -Scope Global -Name LbApiUrl -ErrorAction SilentlyContinue) { $global:LbApiUrl } else { $null }
    $previousUsername = if (Get-Variable -Scope Global -Name LbUsername -ErrorAction SilentlyContinue) { $global:LbUsername } else { $null }
    $previousPassword = if (Get-Variable -Scope Global -Name LbPassword -ErrorAction SilentlyContinue) { $global:LbPassword } else { $null }

    $resolvedDllPath = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'DllPath' -VariableName 'LbDllPath' -Fallback (Join-Path $PSScriptRoot '..\..\lb-web\Bin\Client')
    $resolvedApiUrl = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'ApiUrl' -VariableName 'LbApiUrl' -Fallback 'http://localhost:56540/api/'
    $resolvedUsername = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'Username' -VariableName 'LbUsername' -Fallback 'Administrator'
    $resolvedPassword = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'Password' -VariableName 'LbPassword' -Fallback 'admin'
    $resolvedCulture = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'Culture' -VariableName 'LbCulture' -Fallback 'de-DE'
    $resolvedLanguage = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'Language' -VariableName 'LbLanguage' -Fallback 'de-DE'

    if ($PSBoundParameters.ContainsKey('ApiUrl') -and $null -ne $previousApiUrl -and $PSBoundParameters['ApiUrl'] -ne $previousApiUrl) {
        $global:LbAccessToken = $null
    }
    if ($PSBoundParameters.ContainsKey('Username') -and $null -ne $previousUsername -and $PSBoundParameters['Username'] -ne $previousUsername) {
        $global:LbAccessToken = $null
    }
    if ($PSBoundParameters.ContainsKey('Password') -and $null -ne $previousPassword -and $PSBoundParameters['Password'] -ne $previousPassword) {
        $global:LbAccessToken = $null
    }

    Import-LbClientDlls -DllPath $resolvedDllPath

    $uri = [Uri]$resolvedApiUrl
    $apiClient = $null
    $loginResult = $null
    $usedExistingToken = $false

    if (Get-Variable -Scope Global -Name 'LbAccessToken' -ErrorAction SilentlyContinue) {
        $existingToken = $global:LbAccessToken
        if (-not [string]::IsNullOrWhiteSpace($existingToken)) {
            $apiClient = New-Object EAS.LeegooBuilder.Web.WebApiClient.WebApiClient -ArgumentList $uri, $existingToken
            if ($apiClient.IsAccessValid()) {
                $usedExistingToken = $true
            }
        }
    }

    if (-not $usedExistingToken) {
        $apiClient = New-Object EAS.LeegooBuilder.Web.WebApiClient.WebApiClient -ArgumentList $uri

        $loginParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Authentication.LoginParameter
        $loginParameter.Username = $resolvedUsername
        $loginParameter.Password = $resolvedPassword
        $loginParameter.Culture = $resolvedCulture
        $loginParameter.Language = $resolvedLanguage

        $loginResult = $apiClient.AuthenticationClient.LoginAsync($loginParameter).GetAwaiter().GetResult()

        if ($loginResult.OperationResult.Successful) {
            $global:LbAccessToken = $loginResult.User.Token
        }
        else {
            $global:LbAccessToken = $null
        }
    }

    $isDirectRun = [string]::IsNullOrWhiteSpace($MyInvocation.ScriptName)

    if ($usedExistingToken) {
        if (-not $isDirectRun) {
            Write-Output $apiClient
        }
        return
    }

    if (-not $loginResult.OperationResult.Successful) {
        Write-LbApiResult -ApiResult $loginResult
        throw $loginResult.OperationResult.ShortMessage
    }

    if ($isDirectRun) {
        Write-LbApiResult -ApiResult $loginResult
        return
    }

    Write-Output $apiClient
}
finally {
    if ((Get-Location).Path -ne $__lbStartLocation.Path) {
        Set-Location $__lbStartLocation
    }
}
