[CmdletBinding(DefaultParameterSetName = 'ById')]
param(
    [string]$DllPath,
    [string]$ApiUrl,
    [string]$Username,
    [string]$Password,
    [string]$Culture,
    [string]$Language,
    [Parameter(Mandatory = $true, ParameterSetName = 'ByPerson')]
    $Person,
    [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
    [string]$InternalPersonID
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

            if ($propertyType -eq [string]) {
                $targetProperty.SetValue($Target, $value)
                continue
            }

            $underlyingType = [Nullable]::GetUnderlyingType($propertyType)
            if ($null -eq $underlyingType) {
                $underlyingType = $propertyType
            }

            if ($underlyingType.IsPrimitive -or $underlyingType.IsEnum) {
                $convertedValue = [Convert]::ChangeType($value, $underlyingType)
                $targetProperty.SetValue($Target, $convertedValue)
                continue
            }

            if ($propertyType.IsValueType) {
                $targetProperty.SetValue($Target, $value)
            }
        }
    }

    function Resolve-LbPersonEntity {
        param($InputPerson)

        if ($null -eq $InputPerson) {
            return $null
        }

        $personType = [EAS.LeegooBuilder.Common.DataTransferObjects.Entity.PersonItem]
        if ($InputPerson -is $personType) {
            return $InputPerson
        }

        if ($InputPerson -is [string]) {
            $parsed = $InputPerson | ConvertFrom-Json
            $entityNode = $parsed
            foreach ($propertyName in $parsed.PSObject.Properties.Name) {
                if ($propertyName -ieq 'person') {
                    $entityNode = $parsed.$propertyName
                    break
                }
            }

            $person = New-Object $personType
            Copy-LbEntityProperties -Target $person -Source $entityNode
            return $person
        }

        return $null
    }
    . (Join-Path $PSScriptRoot '..\Helpers\Lb-Session.ps1')
    . (Join-Path $PSScriptRoot '..\Helpers\Write-LbApiResult.ps1')

    $connectionSplat = Get-LbConnectionSplat -BoundParameters $PSBoundParameters

    $apiClient = & (Join-Path $PSScriptRoot '..\ImportAndLogin.ps1') @connectionSplat
    
    if ($PSCmdlet.ParameterSetName -eq 'ByPerson') {
        $personEntity = Resolve-LbPersonEntity -InputPerson $Person
        $saveParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.SavePersonParameter
        $saveParameter.Person = $personEntity
        $saveParameter.SaveDataMode = [EAS.LeegooBuilder.Common.DataTransferObjects.Entity.Models.SaveDataMode]::Update

        $saveResult = $apiClient.CompaniesAndPersonsClient.SavePersonAsync($saveParameter).GetAwaiter().GetResult()
        Write-LbApiResult -ApiResult $saveResult
        return
    }

    $loadParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.LoadPersonParameter
    $loadParameter.InternalPersonID = [guid]$InternalPersonID
    $loadResult = $apiClient.CompaniesAndPersonsClient.LoadPersonAsync($loadParameter).GetAwaiter().GetResult()

    if (-not $loadResult.OperationResult.Successful) {
        Write-LbApiResult -ApiResult $loadResult
        return
    }

    $loadResult.Person.Name = ('Modified Person Name at ({0})' -f (Get-Date).ToString('ddHHmmss'))

    $saveParameter = New-Object EAS.LeegooBuilder.Web.Contracts.Models.ParameterClasses.CompaniesAndPersons.SavePersonParameter
    $saveParameter.Person = $loadResult.Person
    $saveParameter.SaveDataMode = [EAS.LeegooBuilder.Common.DataTransferObjects.Entity.Models.SaveDataMode]::Update

    $saveResult = $apiClient.CompaniesAndPersonsClient.SavePersonAsync($saveParameter).GetAwaiter().GetResult()
    Write-LbApiResult -ApiResult $saveResult
}
finally {
    if ((Get-Location).Path -ne $__lbStartLocation.Path) {
        Set-Location $__lbStartLocation
    }
}
