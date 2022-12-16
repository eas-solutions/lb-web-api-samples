# Load Client DLL
Add-Type -Path "$PSScriptRoot\..\bin\EAS.LeegooBuilder.Web.WebApiClient.dll" -IgnoreWarnings

# Create Client Instance
$uri = New-Object System.Uri -arg "http://localhost:56540/api/"
$apiClient = New-Object EAS.LeegooBuilder.Web.WebApiClient.WebApiClient -arg $uri

# Create Login Parameter
$loginParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.UserServiceWeb.LoginParameter
$loginParameter.Username = "Administrator"
$loginParameter.Password = "admin"
$loginParameter.Culture = "de-DE"
$loginParameter.Language = "de"

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
