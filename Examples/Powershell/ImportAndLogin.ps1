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

    $defaultDllPath = Join-Path $PSScriptRoot '..\..\lb-web\Bin\Client'
    $defaultApiUrl = 'http://localhost:56540/api/'
    $defaultUsername = 'Administrator'
    $defaultPassword = 'admin'
    $defaultCulture = 'de-DE'
    $defaultLanguage = 'de-DE'

    $previousApiUrl = if (Get-Variable -Scope Global -Name LbApiUrl -ErrorAction SilentlyContinue) { $global:LbApiUrl } else { $defaultApiUrl }
    $previousUsername = if (Get-Variable -Scope Global -Name LbUsername -ErrorAction SilentlyContinue) { $global:LbUsername } else { $defaultUsername }
    $previousPassword = if (Get-Variable -Scope Global -Name LbPassword -ErrorAction SilentlyContinue) { $global:LbPassword } else { $defaultPassword }

    $resolvedDllPath = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'DllPath' -VariableName 'LbDllPath' -Fallback $defaultDllPath
    $resolvedApiUrl = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'ApiUrl' -VariableName 'LbApiUrl' -Fallback $defaultApiUrl
    $resolvedUsername = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'Username' -VariableName 'LbUsername' -Fallback $defaultUsername
    $resolvedPassword = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'Password' -VariableName 'LbPassword' -Fallback $defaultPassword
    $resolvedCulture = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'Culture' -VariableName 'LbCulture' -Fallback $defaultCulture
    $resolvedLanguage = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'Language' -VariableName 'LbLanguage' -Fallback $defaultLanguage

    if ($resolvedApiUrl -ne $previousApiUrl -or $resolvedUsername -ne $previousUsername -or $resolvedPassword -ne $previousPassword) {
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
