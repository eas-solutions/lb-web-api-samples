param(
    [string]$DllPath,
    [string]$ApiUrl,
    [string]$Username,
    [string]$Password,
    [string]$Culture,
    [string]$Language,
    [string]$Name
)

$__lbStartLocation = Get-Location
try {
    . (Join-Path $PSScriptRoot '..\Helpers\Lb-Session.ps1')
    . (Join-Path $PSScriptRoot '..\Helpers\Write-LbApiResult.ps1')

    $nameFilter = Resolve-LbSessionValue -BoundParameters $PSBoundParameters -ParameterName 'Name' -VariableName 'LbProjectName' -NoFallback
    $applyNameFilter = -not [string]::IsNullOrWhiteSpace($nameFilter)

    $connectionSplat = Get-LbConnectionSplat -BoundParameters $PSBoundParameters
    $apiClient = & (Join-Path $PSScriptRoot '..\ImportAndLogin.ps1') @connectionSplat

    $content = New-Object 'Collections.Generic.List[EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Project.GetProjectsContent]'
    $content.Add([EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Project.GetProjectsContent]::Projects)

    $parameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.Project.GetProjectsParameter
    $parameter.ProjectsContent = $content

    if ($applyNameFilter) {
        $where = New-Object EAS.DataTransfer.DTO.DynamicQuery.QueryWhere
        $where.Field = 'Description'
        $where.Operator = [EAS.DataTransfer.DTO.DynamicQuery.QueryWhere+PredicateOperator]::Contains
        $where.Condition = [EAS.DataTransfer.DTO.DynamicQuery.QueryWhere+PredicateCondition]::And
        $where.Value = $nameFilter

        $querySettings = New-Object EAS.DataTransfer.DTO.DynamicQuery.QuerySettings
        $querySettings.Where = New-Object 'Collections.Generic.List[EAS.DataTransfer.DTO.DynamicQuery.QueryWhere]'
        $querySettings.Where.Add($where)
        $parameter.QuerySettings = $querySettings
    }

    $result = $apiClient.ProjectClient.GetProjectsAsync($parameter).GetAwaiter().GetResult()
    Write-LbApiResult -ApiResult $result
}
finally {
    if ((Get-Location).Path -ne $__lbStartLocation.Path) {
        Set-Location $__lbStartLocation
    }
}
