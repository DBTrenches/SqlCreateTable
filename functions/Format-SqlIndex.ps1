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

    $CLUSTERED_OR_NOT = switch($Index.type){
        1 {"clustered "}
        5 {"clustered columnstore "}
        6 {"columnstore "}
    }
    
    $is_columnstore = $Index.type -in (5,6)

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
    $createIndexCommand += "create $UNIQUE_OR_NOT$($CLUSTERED_OR_NOT)index $i $_NL    on $s.$t "
    if(-not $is_columnstore){
        $createIndexCommand += "( $keyCols )"
        $createIndexCommand += "$includeBlock"
    }
    if($Index.has_filter){$createIndexCommand += "$($_NL)where $($Index.filter_definition)"}
    $createIndexCommand += ";$($_NL)go$_NL"

    [PSCustomObject]@{
        CreateIndexCommand = $createIndexCommand
    }
}