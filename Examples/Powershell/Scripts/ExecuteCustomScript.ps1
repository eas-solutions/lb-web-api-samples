param(
    [string]$DllPath,
    [string]$ApiUrl,
    [string]$Username,
    [string]$Password,
    [string]$Culture,
    [string]$Language,
    [string]$ScriptName
)

$__lbStartLocation = Get-Location
try {
    . (Join-Path $PSScriptRoot '..\Helpers\Lb-Session.ps1')
    . (Join-Path $PSScriptRoot '..\Helpers\Write-LbApiResult.ps1')

    $connectionSplat = Get-LbConnectionSplat -BoundParameters $PSBoundParameters

    $resolvedScriptName = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'ScriptName' -VariableName 'LbScriptName' -Fallback 'CustomerImport'

    $apiClient = & (Join-Path $PSScriptRoot '..\ImportAndLogin.ps1') @connectionSplat
    
    $loadParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Scripting.LoadScriptListParameter
    $scriptTypes = New-Object 'Collections.Generic.List[EAS.LeegooBuilder.Web.Contracts.CustomScriptTypeWeb]'
    $scriptTypes.Add([EAS.LeegooBuilder.Web.Contracts.CustomScriptTypeWeb]::UserScript)
    $loadParameter.ScriptTypes = $scriptTypes

    $loadResult = $apiClient.ScriptingClient.LoadScriptListAsync($loadParameter).GetAwaiter().GetResult()
    if (-not $loadResult.OperationResult.Successful) {
        Write-LbApiResult -ApiResult $loadResult
        return
    }

    $matchedScript = $null
    if ($null -ne $loadResult.ScriptInfos) {
        foreach ($scriptList in $loadResult.ScriptInfos.Values) {
            foreach ($scriptInfo in $scriptList) {
                if ($scriptInfo.Description -eq $resolvedScriptName) {
                    $matchedScript = $scriptInfo
                    break
                }
            }

            if ($null -ne $matchedScript) {
                break
            }
        }
    }

    if ($null -eq $matchedScript) {
        Write-Host $resolvedScriptName -ForegroundColor Red
        return
    }

    $scriptArguments = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Scripting.CustomScriptArgumentsWeb
    $scriptArguments.ScriptId = $matchedScript.ScriptId

    $executeParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Scripting.ExecuteCustomScriptParameter
    $executeParameter.CustomScriptArguments = $scriptArguments

    $executeResult = $apiClient.ScriptingClient.ExecuteCustomScriptAsync($executeParameter).GetAwaiter().GetResult()
    Write-LbApiResult -ApiResult $executeResult
}
finally {
    if ((Get-Location).Path -ne $__lbStartLocation.Path) {
        Set-Location $__lbStartLocation
    }
}
