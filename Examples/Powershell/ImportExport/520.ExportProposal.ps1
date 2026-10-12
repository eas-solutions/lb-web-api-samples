param(
    [string]$DllPath,
    [string]$ApiUrl,
    [string]$Username,
    [string]$Password,
    [string]$Culture,
    [string]$Language,
    [Parameter(Mandatory = $true)]
    [string]$InternalProposalID,
    [Parameter(Mandatory = $true)]
    [string]$OutputFile
)

$__lbStartLocation = Get-Location
try {
    . (Join-Path $PSScriptRoot '..\Helpers\Lb-Session.ps1')
    . (Join-Path $PSScriptRoot '..\Helpers\Write-LbApiResult.ps1')

    $connectionSplat = Get-LbConnectionSplat -BoundParameters $PSBoundParameters

    $resolvedOutputFile = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'OutputFile' -VariableName 'LbOutputFile' -NoFallback

    $apiClient = & (Join-Path $PSScriptRoot '..\ImportAndLogin.ps1') @connectionSplat
    
    $exportParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ImportExport.ExportProposalsParameter
    $proposalIds = New-Object 'Collections.Generic.List[System.Guid]'
    $proposalIds.Add([guid]$InternalProposalID)
    $exportParameter.ProposalIds = $proposalIds

    $exportResult = $apiClient.ImportExportClient.ExportProposalsAsync($exportParameter).GetAwaiter().GetResult()

    if (-not $exportResult.OperationResult.Successful) {
        Write-LbApiResult -ApiResult $exportResult
        return
    }

    if ($null -eq $exportResult.ProposalFile -or $exportResult.ProposalFile.Length -eq 0) {
        Write-Host 'No content to write to the file.' -ForegroundColor Red
        Write-LbApiResult -ApiResult $exportResult -AsFailure
        return
    }

    try {
        [System.IO.File]::WriteAllBytes($resolvedOutputFile, $exportResult.ProposalFile)
    }
    catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-LbApiResult -ApiResult $exportResult -AsFailure
        return
    }

    Write-LbApiResult -ApiResult $exportResult
}
finally {
    if ((Get-Location).Path -ne $__lbStartLocation.Path) {
        Set-Location $__lbStartLocation
    }
}
