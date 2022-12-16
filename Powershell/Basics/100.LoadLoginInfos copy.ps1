# Create client instance
$apiClient = & "$PSScriptRoot\..\ImportWebClient.ps1"

# Execute API function
$result = $apiClient.AuthenticationService.LoadLoginInfos()

# Show some output
if ($result.OperationResult.Successful) {
    foreach ($culture in $result.AvailableCultures) {
        Write-Output "$($culture.Text) - $($culture.ShortText)"
    }
} else {
    Write-Output $result.OperationResult.ShortMessage
}
