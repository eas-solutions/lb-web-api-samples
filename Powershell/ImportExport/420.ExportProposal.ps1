# Create client instance and login
$apiClient = & "$PSScriptRoot\..\ImportAndLogin.ps1"


# Export of 1st proposal
$exportPorposalParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ImportExport.ExportProposalsParameter
$proposalExportList = New-Object Collections.Generic.List[System.Guid]

# Insert your proposal id here
$proposalExportList.Add("00000000-0000-0000-0000-000000000000")
$exportPorposalParameter.ProposalIds = $proposalExportList
$exportResult = $apiClient.ImportExportClient.ExportProposalsAsync($exportPorposalParameter).GetAwaiter().GetResult()

# Show some output of export
if (!$exportResult.OperationResult.Successful) {
    Write-Output $exportResult.OperationResult.DetailedMessage
    Exit
}

# Write to file
if ($null -ne $exportResult.ProposalFile -and $exportResult.ProposalFile.Length -gt 0) {
    try {
        # Your Path to write the file
        [System.IO.File]::WriteAllBytes("C:\Temp\ExportedProposal.leegoo", $exportResult.ProposalFile)
    } catch {
        Write-Error "An error occurred while writing to the file: $_"
    }
} else {
    Write-Output "No content to write to the file."
}