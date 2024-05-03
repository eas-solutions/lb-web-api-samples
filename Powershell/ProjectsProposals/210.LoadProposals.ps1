set-location $PSScriptRoot

# Create client instance
$apiClient = & "..\ImportAndLogin.ps1"

# Write some output
Write-Output "Start loading proposals..."

$loadOptions = New-Object Collections.Generic.List[EAS.LeegooBuilder.Web.Contracts.Models.Enums.ProposalLoadType]
$loadOptions.Add([EAS.LeegooBuilder.Web.Contracts.Models.Enums.ProposalLoadType]::AllProposals)

$content = New-Object Collections.Generic.List[EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Proposal.GetProposalsContent]
$content.Add([EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Proposal.GetProposalsContent]::Proposals)

# Build Query Settings
$whereCondition = New-Object EAS.DataTransfer.DTO.DynamicQuery.QueryWhere
$whereCondition.Field = "ProposalID"
$whereCondition.Operator = 9; # Need to use human readable enum reference
$whereCondition.Value = "2404"
$whereCondition.Condition = 1; # Need to use human readable enum reference

$querySettings = New-Object EAS.DataTransfer.DTO.DynamicQuery.QuerySettings
$querySettings.Where = New-Object Collections.Generic.List[EAS.DataTransfer.DTO.DynamicQuery.QueryWhere]
$querySettings.Where.Add($whereCondition)

# Build parameter
$parameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Proposal.GetProposalsParameter
$parameter.LoadAllProposals = $true
$parameter.Content = $content
$parameter.LoadOptions = $loadOptions
$parameter.QuerySettings = $querySettings

# Execute API function
$getProposalsR = $apiClient.ProposalClient.GetProposalsAsync($parameter).GetAwaiter().GetResult()

# Show some output
if ($getProposalsR.OperationResult.Successful) {
    foreach ($proposal in $getProposalsR.Proposals) {
        Write-Output "Proposal $($proposal.ProposalID): Created $($proposal.CreateDate)"
    }
} else {
    Write-Output $getProposalsR.OperationResult.ShortMessage
}