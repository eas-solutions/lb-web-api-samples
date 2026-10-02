[CmdletBinding(DefaultParameterSetName = 'ById')]
param(
    [string]$DllPath,
    [string]$ApiUrl,
    [string]$Username,
    [string]$Password,
    [string]$Culture,
    [string]$Language,
    [Parameter(Mandatory = $true, ParameterSetName = 'ByCompany')]
    $Company,
    [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
    [string]$InternalCompanyID
)

$__lbStartLocation = Get-Location
try {
    function Copy-LbEntityProperties {
        param(
            [Parameter(Mandatory = $true)]
            [object]$Target,
            [Parameter(Mandatory = $true)]
            [object]$Source
        )

        $targetType = $Target.GetType()
        $sourceProperties = if ($Source -is [pscustomobject]) {
            $Source.PSObject.Properties
        }
        else {
            $Source.GetType().GetProperties() | ForEach-Object {
                [pscustomobject]@{ Name = $_.Name; Value = $_.GetValue($Source) }
            }
        }

        foreach ($sourceProperty in $sourceProperties) {
            $targetProperty = $targetType.GetProperty($sourceProperty.Name)
            if ($null -eq $targetProperty -or -not $targetProperty.CanWrite) {
                continue
            }

            $value = $sourceProperty.Value
            if ($null -eq $value) {
                $targetProperty.SetValue($Target, $null)
                continue
            }

            if ($value -is [System.Collections.IList] -or $value -is [pscustomobject]) {
                continue
            }

            $propertyType = $targetProperty.PropertyType
            if ($propertyType -eq [guid]) {
                $targetProperty.SetValue($Target, [guid]$value)
                continue
            }

            if ($propertyType -eq [nullable[guid]]) {
                if ([string]::IsNullOrWhiteSpace("$value")) {
                    $targetProperty.SetValue($Target, $null)
                }
                else {
                    $targetProperty.SetValue($Target, [guid]$value)
                }
                continue
            }

            if ($propertyType.IsValueType -or $propertyType -eq [string]) {
                $targetProperty.SetValue($Target, $value)
            }
        }
    }

    function Resolve-LbCompanyEntity {
        param($InputCompany)

        if ($null -eq $InputCompany) {
            return $null
        }

        $companyType = [EAS.LeegooBuilder.Common.DataTransferObjects.Entity.CompanyItem]
        if ($InputCompany -is $companyType) {
            return $InputCompany
        }

        if ($InputCompany -is [string]) {
            $parsed = $InputCompany | ConvertFrom-Json
            $entityNode = $parsed
            foreach ($propertyName in $parsed.PSObject.Properties.Name) {
                if ($propertyName -ieq 'company') {
                    $entityNode = $parsed.$propertyName
                    break
                }
            }

            $company = New-Object $companyType
            Copy-LbEntityProperties -Target $company -Source $entityNode
            return $company
        }

        return $null
    }
    . (Join-Path $PSScriptRoot '..\Helpers\Lb-Session.ps1')
    . (Join-Path $PSScriptRoot '..\Helpers\Write-LbApiResult.ps1')

    $connectionSplat = Get-LbConnectionSplat -BoundParameters $PSBoundParameters

    $apiClient = & (Join-Path $PSScriptRoot '..\ImportAndLogin.ps1') @connectionSplat
    
    if ($PSCmdlet.ParameterSetName -eq 'ByCompany') {
        $companyEntity = Resolve-LbCompanyEntity -InputCompany $Company
        $saveParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.SaveCompanyParameter
        $saveParameter.Company = $companyEntity
        $saveParameter.SaveDataMode = [EAS.LeegooBuilder.Common.DataTransferObjects.Entity.Models.SaveDataMode]::Update

        $saveResult = $apiClient.CompaniesAndPersonsClient.SaveCompanyAsync($saveParameter).GetAwaiter().GetResult()
        Write-LbApiResult -ApiResult $saveResult
        return
    }

    $loadParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.LoadCompanyParameter
    $loadParameter.InternalCompanyID = [guid]$InternalCompanyID
    $loadResult = $apiClient.CompaniesAndPersonsClient.LoadCompanyAsync($loadParameter).GetAwaiter().GetResult()

    if (-not $loadResult.OperationResult.Successful) {
        Write-LbApiResult -ApiResult $loadResult
        return
    }

    $loadResult.Company.Name1 = ('Modified Company Name at ({0})' -f (Get-Date).ToString('ddHHmmss'))

    $saveParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.SaveCompanyParameter
    $saveParameter.Company = $loadResult.Company
    $saveParameter.SaveDataMode = [EAS.LeegooBuilder.Common.DataTransferObjects.Entity.Models.SaveDataMode]::Update

    $saveResult = $apiClient.CompaniesAndPersonsClient.SaveCompanyAsync($saveParameter).GetAwaiter().GetResult()
    Write-LbApiResult -ApiResult $saveResult
}
finally {
    if ((Get-Location).Path -ne $__lbStartLocation.Path) {
        Set-Location $__lbStartLocation
    }
}
