# Dll laden
Add-Type -Path "$PSScriptRoot\..\bin\EAS.LeegooBuilder.Web.WebApiClient.dll" -IgnoreWarnings

# API Client erzeugen
$uri = New-Object System.Uri -arg "http://avalon.eas-cpq.de:56540/api/"
$apiClient = New-Object EAS.LeegooBuilder.Web.WebApiClient.WebApiClient -arg $uri

Write-Output "Client loaded"

$loginParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.UserServiceWeb.LoginParameter
$loginParameter.Username = "Administrator"
$loginParameter.Password = "admin"
$loginParameter.Culture = "de-DE"
$loginParameter.Language = "de"

$loginResult = $apiClient.LogIn($loginParameter)

if ($loginResult.OperationResult.Successful) {
    Write-Output "Login successful"
}else {
    Write-Output "Login not successful:"
    Write-Output $loginResult.OperationResult.ShortMessage
}

return $apiClient
