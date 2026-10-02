function Write-LbApiResult {
    param(
        [Parameter(Mandatory = $true)]
        $ApiResult,

        [switch]$AsFailure
    )

    $global:LbApiOutput = $ApiResult
    $global:LbApiOutputJSON = ($ApiResult | ConvertTo-Json -Depth 12)

    function Get-LbJsonStringLiteral {
        param(
            [AllowNull()]
            [string]$Value,
            [string]$Indent,
            [switch]$AllowMultiline
        )

        if ($null -eq $Value) {
            return 'null'
        }

        if ($AllowMultiline) {
            $quotedLines = foreach ($line in ($Value -split "`r?`n")) {
                $line.Replace('"', '\"')
            }

            if ($quotedLines.Count -le 1) {
                return "`"$($quotedLines[0])`""
            }

            $continuationIndent = $Indent + '  '
            return '"' + ($quotedLines -join "`n$continuationIndent") + '"'
        }

        $escaped = $Value -replace '\\', '\\\\' -replace '"', '\"' -replace "`r", '\r' -replace "`n", '\n' -replace "`t", '\t'
        return "`"$escaped`""
    }

    function Get-LbCompressedListJson {
        param(
            [System.Collections.IList]$Items,
            [string]$Indent
        )

        if ($Items.Count -eq 0) {
            return '[]'
        }

        $itemIndent = $Indent + '  '
        $itemLines = [System.Collections.Generic.List[string]]::new()
        for ($itemIndex = 0; $itemIndex -lt $Items.Count; $itemIndex++) {
            $itemPrefix = if ($itemIndex -eq 0) { $itemIndent } else { "$itemIndent," }
            $itemLines.Add("$itemPrefix$($Items[$itemIndex] | ConvertTo-Json -Depth 8 -Compress)")
        }

        return "[`n$($itemLines -join "`n")`n$Indent]"
    }

    function Get-LbReadableProperties {
        param([Type]$Type)

        return @(
            $Type.GetProperties([System.Reflection.BindingFlags]'Public,Instance') | Where-Object {
                $_.CanRead -and $_.GetIndexParameters().Count -eq 0
            }
        )
    }

    function Get-LbDisplayJson {
        param(
            [AllowNull()]
            $Value,
            [string]$Indent = '',
            [string]$PropertyName = '',
            [switch]$ForError
        )

        if ($null -eq $Value) {
            return 'null'
        }

        if ($Value -is [string]) {
            return Get-LbJsonStringLiteral -Value $Value -Indent $Indent -AllowMultiline:($ForError -and $PropertyName -eq 'DetailedMessage')
        }

        if ($Value -is [bool]) {
            return $Value.ToString().ToLowerInvariant()
        }

        if ($Value -is [byte[]]) {
            return $Value.Length.ToString()
        }

        if ($Value -is [System.Collections.IList] -and $Value -isnot [string]) {
            if ($Value.Count -eq 0) {
                return '[]'
            }

            if (-not $ForError -and $Value.Count -gt 5) {
                return Get-LbCompressedListJson -Items $Value -Indent $Indent
            }

            $itemIndent = $Indent + '  '
            $itemLines = [System.Collections.Generic.List[string]]::new()
            $itemIndex = 0
            foreach ($item in $Value) {
                $itemJson = Get-LbDisplayJson -Value $item -Indent $itemIndent -ForError:$ForError
                $itemPrefix = if ($itemIndex -eq 0) { $itemIndent } else { "$itemIndent," }
                $itemIndex++
                $itemLines.Add("$itemPrefix$itemJson")
            }

            return "[`n$($itemLines -join "`n")`n$Indent]"
        }

        $valueType = $Value.GetType()
        if ($valueType.IsEnum) {
            return Get-LbJsonStringLiteral -Value $Value.ToString() -Indent $Indent
        }

        if ($valueType.IsValueType) {
            if ($Value -is [guid]) {
                return Get-LbJsonStringLiteral -Value $Value.ToString() -Indent $Indent
            }

            return $Value.ToString()
        }

        $properties = Get-LbReadableProperties -Type $valueType
        if ($properties.Count -eq 0) {
            return Get-LbJsonStringLiteral -Value $Value.ToString() -Indent $Indent
        }

        $childIndent = $Indent + '  '
        $propertyLines = [System.Collections.Generic.List[string]]::new()
        for ($propertyIndex = 0; $propertyIndex -lt $properties.Count; $propertyIndex++) {
            $property = $properties[$propertyIndex]
            $rawChild = $property.GetValue($Value)
            $childJson = if ($property.Name -eq 'Value' -and -not $ForError -and $rawChild -is [System.Collections.IList] -and $rawChild -isnot [string] -and $rawChild -isnot [byte[]] -and $rawChild.Count -gt 5) {
                Get-LbCompressedListJson -Items $rawChild -Indent $childIndent
            }
            else {
                Get-LbDisplayJson -Value $rawChild -Indent $childIndent -PropertyName $property.Name -ForError:$ForError
            }

            $commaSuffix = if ($propertyIndex -lt $properties.Count - 1) { ',' } else { '' }
            $propertyLines.Add("$childIndent`"$($property.Name)`": $childJson$commaSuffix")
        }

        return "{`n$($propertyLines -join "`n")`n$Indent}"
    }

    $isSuccessful = $false
    if ($ApiResult.OperationResult -and $ApiResult.OperationResult.Successful -and -not $AsFailure) {
        $isSuccessful = $true
    }

    $displayJson = Get-LbDisplayJson -Value $ApiResult -ForError:(-not $isSuccessful)

    if ($isSuccessful) {
        Write-Host $displayJson
    }
    else {
        Write-Host $displayJson -ForegroundColor Red
    }
}
