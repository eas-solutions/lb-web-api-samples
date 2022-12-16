# Load Client DLL
Add-Type -Path "$PSScriptRoot\..\bin\EAS.LeegooBuilder.Web.WebApiClient.dll" -IgnoreWarnings

# !!! Change Here !!!
$apiUrl = "http://avalon.eas-cpq.de:56540/api/"
$username = "Administrator"
$password = "admin"
$culture = "de-DE"
$language = "de"

# Create Client Instance
$uri = New-Object System.Uri -arg $apiUrl
$apiClient = New-Object EAS.LeegooBuilder.Web.WebApiClient.WebApiClient -arg $uri

# Create Login Parameter
$loginParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.UserServiceWeb.LoginParameter
$loginParameter.Username = $username
$loginParameter.Password = $password
$loginParameter.Culture = $culture
$loginParameter.Language = $language

# Execute Login
$loginResult = $apiClient.LogIn($loginParameter)

# Validate Result
if ($loginResult.OperationResult.Successful) {
    Write-Output "Login successful"
}else {
    Write-Output "Login not successful:"
    Write-Output $loginResult.OperationResult.ShortMessage
}

# Return Client Instance
return $apiClient
