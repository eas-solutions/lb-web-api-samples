param(
    [string]$DllPath,
    [string]$ApiUrl,
    [string]$Username,
    [string]$Password,
    [string]$Culture,
    [string]$Language,
    [Parameter(Mandatory = $true)]
    [string]$ProposalFile
)

$__lbStartLocation = Get-Location
try {
    . (Join-Path $PSScriptRoot '..\Helpers\Lb-Session.ps1')
    . (Join-Path $PSScriptRoot '..\Helpers\Write-LbApiResult.ps1')

    $connectionSplat = Get-LbConnectionSplat -BoundParameters $PSBoundParameters

    $resolvedProposalFile = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'ProposalFile' -VariableName 'LbProposalFile' -NoFallback

    try {
        $proposalBytes = [System.IO.File]::ReadAllBytes($resolvedProposalFile)
    }
    catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
        return
    }

    $apiClient = & (Join-Path $PSScriptRoot '..\ImportAndLogin.ps1') @connectionSplat

    $importParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ImportExport.ImportProposalsParameter
    $importParameter.ProposalFile = $proposalBytes

    $result = $apiClient.ImportExportClient.ImportProposalsAsync($importParameter).GetAwaiter().GetResult()
    Write-LbApiResult -ApiResult $result
}
finally {
    if ((Get-Location).Path -ne $__lbStartLocation.Path) {
        Set-Location $__lbStartLocation
    }
}
