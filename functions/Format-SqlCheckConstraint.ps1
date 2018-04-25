function Format-SqlCheckConstraint {
    [CmdletBinding()]Param(
        [object]$Check
       ,[object]$options
    )

    $checkName = $Check.check_name
    $tableFullName = "$($Check.schema_name).$($Check.parent_name)"

    $checkDef = "check $($Check.definition)"
    
    
    if($Check.is_system_named){
    } else {
        $checkDef = "constraint $checkName $checkDef"
    }
    
    if($Check.is_bindable){
        $inLineBound = $checkDef
    } else {
        $inLineBound = ""
    }

    [PSCustomObject] @{
        InLineBound   = $inLineBound
        InLineUnBound = $checkDef
        OutOfLine     = "alter table $tableFullName `r`n    add $checkDef;`r`ngo"
    }
}
