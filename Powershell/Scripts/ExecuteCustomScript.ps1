# Load Client DLL
Add-Type -Path "D:\WebAPI\Client\EAS.LeegooBuilder.Web.WebApiClient.dll" -IgnoreWarnings

# !!! Change Here !!!
$apiUrl = "http://localhost:56540/api/"
$username = "s.wolski"
$password = "easeas"
$culture = "en-GB"
$language = "en"
$scriptName = "CustomerImport"

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

    # Parameter for Loading Script
    $parameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ScriptingServiceWeb.LoadScriptListParameter

    # Script Types to Load (CustomerScripts = 4)
    $scriptTypes = New-Object Collections.Generic.List[EAS.LeegooBuilder.Web.Contracts.CustomScriptTypeWeb]
    $scriptTypes.Add(4)
    $parameter.ScriptTypes = $scriptTypes;
    
    # Load Scripts
    $LoadScriptResult = $apiClient.ScriptingService.LoadScriptList($parameter)

    if ($LoadScriptResult.OperationResult.Successful){
        
        $scripts =  $LoadScriptResult.ScriptInfos.Values[0][0]

        # Searching relevant Script
        foreach($scriptInfo in $scripts){
            foreach($script in $scriptInfo){
                # Execution only for relevant script
                if ($script.Description.Equals($scriptName)){
                    
                    # Set Executionparameters
                    $executeScriptParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ScriptingServiceWeb.ExecuteCustomScriptParameter
                    $scriptArgs = $parameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.ScriptingServiceWeb.CustomScriptArgumentsWeb
                    $scriptArgs.scriptId = $script.ScriptId

                    $executeScriptParameter.CustomScriptArguments = $scriptArgs

                    # Execute Script
                    $executeScriptResult = $apiClient.ScriptingService.ExecuteCustomScript($executeScriptParameter)
                    if ($executeScriptResult.OperationResult.Successful){
                        Write-Output "Execution successful"
                    }else{
                        Write-Output "Execution not successful"
                    }
                }
            }
        }
    }else {
        Write-Output "Loading not successful:"
        Write-Output $LoadScriptResult.OperationResult.ShortMessage
    }
}else {
    Write-Output "Login not successful:"
    Write-Output $loginResult.OperationResult.ShortMessage
}

# Return Client Instance
return $apiClient
