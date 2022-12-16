# Create client instance and login
$apiClient = & "$PSScriptRoot\..\ImportAndLogin.ps1"

# Create request parameter
$content = New-Object Collections.Generic.List[EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ProjectServiceWeb.GetProjectsContent]
$content.Add([EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ProjectServiceWeb.GetProjectsContent]::All)

$loadOptions = New-Object Collections.Generic.List[EAS.LeegooBuilder.Web.Contracts.Models.Enums.ProjectLoadType]
$loadOptions.Add([EAS.LeegooBuilder.Web.Contracts.Models.Enums.ProjectLoadType]::AllProjects)

$paramter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ProjectServiceWeb.GetProjectsParameter
$paramter.LoadOptions = $loadOptions
$paramter.ProjectsContent = $content

# Execute API function
$result = $apiClient.ProjectService.GetProjects($paramter)

# Show some output
if ($result.OperationResult.Successful) {
    foreach ($project in $result.Projects) {
        Write-Output "$($project.ProjectID) - $($project.Description) - $($project.Note)"
    }
} else {
    Write-Output $result.OperationResult.ShortMessage
}
