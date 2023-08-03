set-location $PSScriptRoot

# Create client instance
$apiClient = & "..\ImportAndLogin.ps1"

# Write some output
Write-Output "Start loading login infos..."

# Execute API function
$parameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Authentication.LoadLoginInfosParameter
$result = $apiClient.AuthenticationClient.LoadLoginInfosAsync($parameter).GetAwaiter().GetResult()

# Show some output
if ($result.OperationResult.Successful) {
    write-output "Available Cultures:"
    foreach ($culture in $result.AvailableCultures) {
        Write-Output "$($culture.Text) - $($culture.ShortText)"
    }
} else {
    Write-Output $result.OperationResult.ShortMessage
}
