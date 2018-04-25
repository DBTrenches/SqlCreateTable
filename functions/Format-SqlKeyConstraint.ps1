function Format-SqlKeyConstraint {
    [CmdletBinding()]Param(
        [object]$UKey
       ,[object]$options
    )

    $keyName = $UKey.u_key_name
    $keyCols = (($UKey | Sort-Object -Property key_ordinal).KeyColumns.KeyColumnName) -join ", "
    $tableFullName = "$($UKey.schema_name).$($UKey.parent_name)"

    if($UKey.key_type -eq "PK"){
        $keyTypeName = "primary key"
    } else {
        $keyTypeName = "unique"
    }

    if($UKey.idx_type -eq 1){
        $idxTypeName = "clustered"
    } else {
        $idxTypeName = "nonclustered"
    }

    if(-not $UKey.is_system_named){
        $keyDef = "constraint $keyName "
    }

    $keyDef += "$keyTypeName $idxTypeName ( $keyCols )"

    [PSCustomObject] @{
        InLineBound   = $keyDef
        InLineUnBound = $keyDef
        OutOfLine     = "alter table $tableFullName `r`n    add $keyDef;`r`ngo"
    }
}