function Get-LbConnectionParameterNames {
    return @('DllPath', 'ApiUrl', 'Username', 'Password', 'Culture', 'Language')
}

function Get-LbConnectionSplat {
    param(
        [hashtable]$BoundParameters
    )

    $splat = @{}
    if ($null -eq $BoundParameters) {
        return $splat
    }

    foreach ($connectionParameter in Get-LbConnectionParameterNames) {
        if ($BoundParameters.ContainsKey($connectionParameter)) {
            $splat[$connectionParameter] = $BoundParameters[$connectionParameter]
        }
    }

    return $splat
}

function Resolve-LbSessionValue {
    param(
        [hashtable]$BoundParameters,
        [Parameter(Mandatory = $true)]
        [string]$ParameterName,
        [Parameter(Mandatory = $true)]
        [string]$VariableName,
        [AllowNull()]
        [string]$Fallback,
        [switch]$NoFallback
    )

    if ($null -ne $BoundParameters -and $BoundParameters.ContainsKey($ParameterName)) {
        $value = $BoundParameters[$ParameterName]
        Set-Variable -Name $VariableName -Value $value -Scope Global
        return $value
    }

    if (Get-Variable -Scope Global -Name $VariableName -ErrorAction SilentlyContinue) {
        return (Get-Variable -Scope Global -Name $VariableName).Value
    }

    if ($NoFallback) {
        return $null
    }

    Set-Variable -Name $VariableName -Value $Fallback -Scope Global
    return $Fallback
}

function Import-LbClientDlls {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DllPath
    )

    function Import-LbClientAssembly {
        param(
            [string]$Path,
            [switch]$IgnoreWarnings
        )

        $assemblyName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        $alreadyLoaded = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq $assemblyName }
        if ($alreadyLoaded) {
            return
        }

        if ($IgnoreWarnings) {
            Add-Type -Path $Path -IgnoreWarnings
        }
        else {
            Add-Type -Path $Path
        }
    }

    Import-LbClientAssembly -Path (Join-Path $DllPath 'EAS.DataTransfer.dll')
    Import-LbClientAssembly -Path (Join-Path $DllPath 'EAS.LeegooBuilder.Web.WebApiClient.dll') -IgnoreWarnings
    Import-LbClientAssembly -Path (Join-Path $DllPath 'EAS.LeegooBuilder.Common.DataTransferObjects.dll') -IgnoreWarnings
}
