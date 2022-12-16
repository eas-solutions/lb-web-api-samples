# Dll laden
$apiClient = & "$PSScriptRoot\..\ImportWebClient.ps1"

# Abfrage
$result = $apiClient.AuthenticationService.LoadLoginInfos()


# Ausgabe
if ($result.OperationResult.Successful) {
    foreach ($culture in $result.AvailableCultures) {
        Write-Output "$($culture.Text) - $($culture.ShortText)"
    }
} else {
    Write-Output $result.OperationResult.ShortMessage
}
