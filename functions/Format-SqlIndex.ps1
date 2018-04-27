function Format-SqlIndex {
    [CmdletBinding()]Param(
        [object]$Index
       ,[object]$options 
    )
    $_NL = "`r`n"
    $_TB = "".PadRight(4)
   
    $s = $Index.table_schema
    $t = $Index.table_name
    $i = $Index.index_name

    if($Index.type -eq 1){
        $CLUSTERED_OR_NOT = "clustered "
    }
    if($Index.is_unique){
        $UNIQUE_OR_NOT = "unique "
    }

    $keyCols = ($Index.KeyColumns | Sort-Object -Property key_ordinal).KeyColumnName -join "$_NL$_TB$_TB,"
    $inclCols = ($Index.InclColumns).column_name -join "$_NL$_TB$_TB,"
    $hasInclCols = (($Index.InclColumns | Measure-Object).Count -gt 0)
    
    if($hasInclCols){
        $includeBlock = " $_NL$($_TB)include ( $inclCols ) "
    }

    $createIndexCommand = ""
    $createIndexCommand += "create $UNIQUE_OR_NOT$($CLUSTERED_OR_NOT)index $i $_NL$($_TB)on $s.$t ( "
    $createIndexCommand += "$keyCols )"
    $createIndexCommand += "$includeBlock;$($_NL)go$_NL"

    [PSCustomObject]@{
        CreateIndexCommand = $createIndexCommand
    }
}