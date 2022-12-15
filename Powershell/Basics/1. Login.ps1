# Dll laden
Add-Type -Path "$PSScriptRoot\..\..\bin\EAS.LeegooBuilder.Web.WebApiClient.dll"

# API Client erzeugen
$uri = New-Object System.Uri -arg "http://avalon.eas-cpq.de:56540/api/"
$apiClient = New-Object EAS.LeegooBuilder.Web.WebApiClient.WebApiClient -arg $uri


# Abfrage

$result = $apiClient.AuthenticationService.LoadLoginInfos()





# Ausgabe
if ($result.OperationResult.Successful) {
    foreach ($culture in $result.AvailableCultures) {
        Write-Output "$($culture.Text) - $($culture.ShortText) "
    }
} else {
    Write-Output $result.OperationResult.ShortMessage
}
