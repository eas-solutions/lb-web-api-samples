param(
    [string]$DllPath,
    [string]$ApiUrl,
    [string]$Username,
    [string]$Password,
    [string]$Culture,
    [string]$Language,
    [Parameter(Mandatory = $true)]
    [string]$InternalProposalID
)

$__lbStartLocation = Get-Location
try {
    . (Join-Path $PSScriptRoot '..\Helpers\Lb-Session.ps1')
    . (Join-Path $PSScriptRoot '..\Helpers\Write-LbApiResult.ps1')

    $connectionSplat = Get-LbConnectionSplat -BoundParameters $PSBoundParameters
    $apiClient = & (Join-Path $PSScriptRoot '..\ImportAndLogin.ps1') @connectionSplat

    $getProposalParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Proposal.GetProposalParameter
    $getProposalParameter.ProposalId = [guid]$InternalProposalID
    $getProposalParameter.IncludeCustomDefinitionValues = $false
    $getProposalParameter.IncludeCompaniesAndPersons = $false

    $result = $apiClient.ProposalClient.GetProposalAsync($getProposalParameter).GetAwaiter().GetResult()
    Write-LbApiResult -ApiResult $result
}
finally {
    if ((Get-Location).Path -ne $__lbStartLocation.Path) {
        Set-Location $__lbStartLocation
    }
}
