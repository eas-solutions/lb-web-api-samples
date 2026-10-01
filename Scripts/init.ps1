$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$webRoot = Join-Path $repoRoot 'lb-web'

Write-Host 'Initializing workspace submodules...'
Push-Location $repoRoot
try {
    & git submodule update --init
    if ($LASTEXITCODE -ne 0) {
        throw "Root submodule initialization failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

Write-Host 'Initializing lb-web submodules...'
Push-Location $webRoot
try {
    & git submodule update --init
    if ($LASTEXITCODE -ne 0) {
        throw "lb-web submodule initialization failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

$settingsPath = Join-Path $webRoot 'EAS.LeegooBuilder.Web.WebApiHost\appsettings.local.json'
$settings = @{}
if (Test-Path $settingsPath) {
    $settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json -AsHashtable
}
if ($settings -isnot [System.Collections.IDictionary]) {
    throw "Settings file '$settingsPath' must contain a JSON object."
}

$connectionSettings = $settings['ConnectionStrings']
$existingConnectionString = $null
if ($connectionSettings -is [System.Collections.IDictionary]) {
    $existingConnectionString = $connectionSettings['default']
}

if ([string]::IsNullOrWhiteSpace($existingConnectionString)) {
    $connectionString = Read-Host 'Connection string for the Web API Host (leave blank to skip)'
    if (-not [string]::IsNullOrWhiteSpace($connectionString)) {
        if ($connectionSettings -isnot [System.Collections.IDictionary]) {
            $connectionSettings = @{}
            $settings['ConnectionStrings'] = $connectionSettings
        }
        $connectionSettings['default'] = $connectionString

        $settings | ConvertTo-Json -Depth 100 | Set-Content -Path $settingsPath -Encoding utf8
        Write-Host "Wrote local connection settings to $settingsPath"
    }
}
else {
    Write-Host 'Using the existing Web API Host connection string; skipping prompt.'
}


$buildScript = Join-Path $webRoot 'Scripts\build.ps1'
Write-Host 'Building API client...'
& $buildScript -Project Client -Configuration Debug
if ($LASTEXITCODE -ne 0) {
    throw "API client build failed with exit code $LASTEXITCODE."
}
