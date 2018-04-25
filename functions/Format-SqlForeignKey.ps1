function Format-SqlForeignKey {
    [CmdletBinding()]Param(
        [object]$ForeignKey
       ,[object]$Options
    )
    
    $_TB = "".PadRight(4)
    $_NL = "`r`n"

    $isSystemNamed  = $ForeignKey.is_system_named
    $ParentFullName = "$($ForeignKey.parent_table_schema).$($ForeignKey.parent_table_name)"
    $ParentCols     = $ForeignKey.ParentCols
    $ChildFullRef   = $ForeignKey.ChildFullRef
    $OnDeleteAction = $foreignKey.OnDeleteAction
    $OnUpdateAction = $foreignKey.OnUpdateAction

    Write-Verbose "Parsing FK named '$($foreignKey.fk_name)'."
    $foreignKeyDef=""

<#
    $t_# is text
    $b_# is (line)break
#>
    $b_1=" $_NL"
    $b_2=" $_NL$_TB"
    $b_3=" $_NL$_TB$_TB"
    $b_4=" $_NL$_TB$_TB$_TB"
    $b_5=" $($_NL)go $_NL"

    $t_1="$($b_1)alter table $ParentFullName $b_2 add $($b_2)"

    if($isSystemNamed){
        $t_2=""
    }else{
        $t_2="constraint $($foreignKey.fk_name) $b_3"
    }
    $t_3 = "foreign key "
    $t_4 = "( $ParentCols ) "
    $t_5 = "$b_4 references $ChildFullRef"

    if($foreignKey.del_ref_act -ne 0){
        $t_5+="$b_4 $OnDeleteAction "
    }
    if($foreignKey.upd_ref_act -ne 0){
        $t_5+="$b_4 $OnUpdateAction "
    }

    [PSCustomObject]@{
        InLineBound   = "$t_2$t_3$t_5"
        InLineUnBound = "$t_2$t_3$t_4$t_5"
        OutOfLine     = "$t_1$t_2$t_3$t_4$t_5;$b_5"
    }
}