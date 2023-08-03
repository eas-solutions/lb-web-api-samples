# Load Client DLL
Add-Type -Path "D:\Quelltexte\EAS-Gitea\LeegooBuilderWeb-API-Samples\bin\EAS.LeegooBuilder.Web.WebApiClient.dll" -IgnoreWarnings
Add-Type -Path "D:\Quelltexte\EAS-Gitea\LeegooBuilderWeb-API-Samples\bin\EAS.LeegooBuilder.Common.DataTransferObjects.dll" -IgnoreWarnings


# !!! Change Here !!!
$apiUrl = "http://localhost:56540/api/"
$username = "Administrator"
$password = "admin"
$culture = "de-DE"
$language = "de"

# Create Client Instance
$uri = New-Object System.Uri -arg $apiUrl
$apiClient = New-Object EAS.LeegooBuilder.Web.WebApiClient.WebApiClient -arg $uri

# Create Login Parameter
$loginParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Authentication.LoginParameter
$loginParameter.Username = $username
$loginParameter.Password = $password
$loginParameter.Culture = $culture
$loginParameter.Language = $language

# Execute Login
$authClient = $apiClient.AuthenticationClient
$loginResult = $authClient.LoginAsync($loginParameter).GetAwaiter().GetResult()

# Validate Result
if ($loginResult.OperationResult.Successful) {
    Write-Debug "Login successful"
}else {
    Write-Output "Login not successful:"
    Write-Output $loginResult.OperationResult.ShortMessage
}

# Return Client Instance
Write-Output $apiClient
