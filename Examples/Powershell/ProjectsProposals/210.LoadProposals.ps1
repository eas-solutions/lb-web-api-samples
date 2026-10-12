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
    . (Join-Path $PSScriptRoot '..\Helpers\Lb-Session.ps1')
    . (Join-Path $PSScriptRoot '..\Helpers\Write-LbApiResult.ps1')

    $connectionSplat = Get-LbConnectionSplat -BoundParameters $PSBoundParameters

    $apiClient = & (Join-Path $PSScriptRoot '..\ImportAndLogin.ps1') @connectionSplat

    $loadOptions = New-Object 'Collections.Generic.List[EAS.LeegooBuilder.Web.Contracts.Models.Enums.ProposalLoadType]'
    $loadOptions.Add([EAS.LeegooBuilder.Web.Contracts.Models.Enums.ProposalLoadType]::AllProposals)

    $content = New-Object 'Collections.Generic.List[EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Proposal.GetProposalsContent]'
    $content.Add([EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Proposal.GetProposalsContent]::Proposals)

    $parameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Proposal.GetProposalsParameter
    $parameter.LoadAllProposals = $true
    $parameter.Content = $content
    $parameter.LoadOptions = $loadOptions

    $result = $apiClient.ProposalClient.GetProposalsAsync($parameter).GetAwaiter().GetResult()
    Write-LbApiResult -ApiResult $result
}
finally {
    if ((Get-Location).Path -ne $__lbStartLocation.Path) {
        Set-Location $__lbStartLocation
    }
}
