# Create client instance and login
$apiClient = & "$PSScriptRoot\..\ImportAndLogin.ps1"

$exportProposalByIdParamter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ImportExport.ExportProposalsByProjectIdParameter
$exportProposalByIdParamter.ProjectIds = New-Object Collections.Generic.List[System.Guid]

# Insert your project id here
$exportProposalByIdParamter.ProjectIds.Add("00000000-0000-0000-0000-000000000000")
$exportProposalByIdParamter.AddBaseData = $true
$exportProjectResult = $apiClient.ImportExportClient.ExportProposalsByProjectIdAsync($exportProposalByIdParamter).GetAwaiter().GetResult()

# Show some output of export
if (!$exportProjectResult.OperationResult.Successful) {
    Write-Output $exportProjectResult.OperationResult.DetailedMessage
    Exit
}

# Write to file
if ($null -ne $exportProjectResult.ProposalFile -and $exportProjectResult.ProposalFile.Length -gt 0) {
    try {
        # Your Path to write the file
        [System.IO.File]::WriteAllBytes("C:\Temp\ExportedProposalById.leegoo", $exportProjectResult.ProposalFile)
    } catch {
        Write-Error "An error occurred while writing to the file: $_"
    }
} else {
    Write-Output "No content to write to the file."
}