# Create client instance and login
$apiClient = & "$PSScriptRoot\..\ImportAndLogin.ps1"

# Import of Exported Proposal
$importProposalParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ImportExport.ImportProposalsParameter
$importProposalParameter.ProposalFile = [System.IO.File]::ReadAllBytes("C:\Temp\ExportedProposal.leegoo")
$importResult = $apiClient.ImportExportClient.ImportProposalsAsync($importProposalParameter).GetAwaiter().GetResult()
# Show some output
if (!$importResult.OperationResult.Successful) {
    Write-Output $importResult.OperationResult.DetailedMessage
    Exit
}