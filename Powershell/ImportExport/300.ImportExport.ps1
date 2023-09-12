# Create client instance and login
$apiClient = & "$PSScriptRoot\..\ImportAndLogin.ps1"

# Loading of Projects
$paramter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Project.GetProjectsParameter
$projectContentParameter = New-Object Collections.Generic.List[EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Project.GetProjectsContent]
$projectContentParameter.Add([EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Project.GetProjectsContent]::All)
$paramter.ProjectsContent = $projectContentParameter
$paramter.LoadOptions = [EAS.LeegooBuilder.Web.Contracts.Models.Enums.ProjectLoadType]::AllProjects
$result = $apiClient.ProjectClient.GetProjectsAsync($paramter).GetAwaiter().GetResult()

if (!$result.OperationResult.Successful) {
    Write-Output $result.OperationResult.ShortMessage
    Exit
}
foreach ($project in $result.Projects) {
    Write-Output "$($project.ProjectID) - $($project.Description) - $($project.Note)"
}

# Select 1st project
$project = $result.Projects[0]

# Loading of Proposals
$proposalParamter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Proposal.GetProposalsParameter
$proposalParamter.ProjectId = $project.InternalProjectID
$proposalParamter.Content = [EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Proposal.GetProposalsContent]::All
$loadOptions = New-Object Collections.Generic.List[EAS.LeegooBuilder.Web.Contracts.Models.Enums.ProposalLoadType]
$loadOptions.Add([EAS.LeegooBuilder.Web.Contracts.Models.Enums.ProposalLoadType]::AllProposals)
$proposalParamter.LoadOptions = $loadOptions
$proposalResult = $apiClient.ProposalClient.GetProposalsAsync($proposalParamter).GetAwaiter().GetResult()

if (!$proposalResult.OperationResult.Successful) {
    Write-Output $proposalResult.OperationResult.DetailedMessage
    Exit
}
foreach ($proposal in $proposalResult.Proposals) {
    Write-Output "$($proposal.ProposalID) - $($proposal.Description) - $($proposal.Note)"
}

# Export of 1st proposal
$exportPorposalParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ImportExport.ExportProposalsParameter
$proposalExportList = New-Object Collections.Generic.List[System.Guid]
$proposalExportList.Add($proposalResult.Proposals[0].InternalProposalID)
$exportPorposalParameter.ProposalIds = $proposalExportList
$exportResult = $apiClient.ImportExportClient.ExportProposalsAsync($exportPorposalParameter).GetAwaiter().GetResult()

# Show some output
if (!$exportResult.OperationResult.Successful) {
    Write-Output $exportResult.OperationResult.DetailedMessage
    Exit
}

if ($null -ne $exportResult.ProposalFile -and $exportResult.ProposalFile.Length -gt 0) {
    try {
        [System.IO.File]::WriteAllBytes("C:\Temp\ExportedProposal.leegoo", $exportResult.ProposalFile)
    } catch {
        Write-Error "An error occurred while writing to the file: $_"
    }
} else {
    Write-Output "No content to write to the file."
}

# Import of Exported Proposal
$importProposalParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ImportExport.ImportProposalsParameter
$importProposalParameter.ProposalFile = [System.IO.File]::ReadAllBytes("C:\Temp\ExportedProposal.leegoo")
$importResult = $apiClient.ImportExportClient.ImportProposalsAsync($importProposalParameter).GetAwaiter().GetResult()
# Show some output
if (!$importResult.OperationResult.Successful) {
    Write-Output $importResult.OperationResult.DetailedMessage
    Exit
}


# Export of Proposal by ProjectId
$exportProposalByIdParamter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ImportExport.ExportProposalsByProjectIdParameter
$exportProposalByIdParamter.ProjectIds = New-Object Collections.Generic.List[System.Guid]
$exportProposalByIdParamter.ProjectIds.Add($project.InternalProjectID)
$exportProposalByIdParamter.AddBaseData = $true
$exportProjectResult = $apiClient.ImportExportClient.ExportProposalsByProjectIdAsync($exportProposalByIdParamter).GetAwaiter().GetResult()

if (!$exportProjectResult.OperationResult.Successful) {
    Write-Output $exportProjectResult.OperationResult.DetailedMessage
    Exit
}

if ($null -ne $exportProjectResult.ProposalFile -and $exportProjectResult.ProposalFile.Length -gt 0) {
    try {
        [System.IO.File]::WriteAllBytes("C:\Temp\ExportedProposalById.leegoo", $exportProjectResult.ProposalFile)
    } catch {
        Write-Error "An error occurred while writing to the file: $_"
    }
} else {
    Write-Output "No content to write to the file."
}