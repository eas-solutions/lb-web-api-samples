# Create client instance and login
$apiClient = & "$PSScriptRoot\..\ImportAndLogin.ps1"

# Create request parameter
$content = New-Object Collections.Generic.List[EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Project.GetProjectsContent]
$content.Add([EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Project.GetProjectsContent]::Projects)

$loadOptions = New-Object Collections.Generic.List[EAS.LeegooBuilder.Web.Contracts.Models.Enums.ProjectLoadType]
$loadOptions.Add([EAS.LeegooBuilder.Web.Contracts.Models.Enums.ProjectLoadType]::AllProjects)

$parameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Project.GetProjectsParameter
$parameter.LoadOptions = $loadOptions
$parameter.ProjectsContent = $content

# Execute API function
$getProjectsR = $apiClient.ProjectClient.GetProjectsAsync($parameter).GetAwaiter().GetResult()

# Show some output
if ($getProjectsR.OperationResult.Successful) {
    foreach ($project in $getProjectsR.Projects) {
        Write-Output "$($project.ProjectID) - $($project.Description) - $($project.Note)"
    }
} else {
    Write-Output $getProjectsR.OperationResult.ShortMessage
}
