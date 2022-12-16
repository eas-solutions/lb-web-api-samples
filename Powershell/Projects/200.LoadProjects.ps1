# Dll laden
$apiClient = & "$PSScriptRoot\..\ImportAndLogin.ps1"

# Abfrage
$paramter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ProjectServiceWeb.GetProjectsParameter

$result = $apiClient.ProjectService.GetProjects($paramter)

# Ausgabe
if ($result.OperationResult.Successful) {
    foreach ($project in $result.Projects) {
        Write-Output "$($project.Description) - $($culture.ShortText)"
    }
} else {
    Write-Output $result.OperationResult.ShortMessage
}
