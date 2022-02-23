function Get-SqlIndexes {
    [CmdletBinding()]Param(
        [Parameter(Mandatory)]
            [Alias('serverName','sqlServer','server')]
            [string]$serverInstance
       ,[Parameter(Mandatory)]
            [Alias('database','dbName')]
            [string]$databaseName
	   ,[Parameter(Mandatory)]
			[Alias('object_id','id','oid','table_id','tableid')]   
	  		[Int32]$objectId
    )

#region query_prepare
    $connStr = @{
        ServerInstance = $serverInstance
        Database       = $databaseName
    }

    $sql_GetIndexes = @"
select table_id   = i.[object_id]
    ,table_schema = object_schema_name(i.[object_id])
    ,table_name   = object_name(i.[object_id])
    ,index_name   = i.[name]
    ,i.index_id
    ,i.[type]
    ,i.[type_desc]
    ,i.is_unique
    ,i.data_space_id
    ,i.[ignore_dup_key]
    ,i.is_primary_key
    ,i.is_unique_constraint
    ,i.fill_factor
    ,i.is_padded
    ,i.is_disabled
    ,i.[allow_row_locks]
    ,i.[allow_page_locks]
    ,i.has_filter
    ,filter_definition = isnull(i.filter_definition,'')
from sys.indexes i 
where i.index_id > 0
    and i.[object_id] = $objectId;
"@
#endregion

#region execute_return
    $idxs = Invoke-Sqlcmd @connStr -Query $sql_GetIndexes

    $idxs | ForEach-Object {
        $idxId = $PSItem.index_id
        $tblId = $PSItem.table_id

        $idxCols = Get-SqlIndexColumns @connStr -tableid $tblId -indexId $idxId

        $keyCols  = $idxCols | Where-Object {-not $PSItem.is_included_column}
        $inclCols = $idxCols | Where-Object {$PSItem.is_included_column}

        $PSItem | Add-Member -MemberType NoteProperty -Name KeyColumns  -Value $keyCols
        $PSItem | Add-Member -MemberType NoteProperty -Name InclColumns -Value $inclCols
    }

    $idxs | ForEach-Object { 
        [PSCustomObject] @{
            table_id             = $PSItem.table_id
            table_schema         = (Get-SqlQuoteNameSparse -text $PSItem.table_schema).text
            table_name           = (Get-SqlQuoteNameSparse -text $PSItem.table_name).text
            index_name           = (Get-SqlQuoteNameSparse -text $PSItem.index_name).text
            index_id             = $PSItem.index_id
            type                 = $PSItem.type
            type_desc            = $PSItem.type_desc
            is_unique            = $PSItem.is_unique
            data_space_id        = $PSItem.data_space_id
            ignore_dup_key       = $PSItem.ignore_dup_key
            is_primary_key       = $PSItem.is_primary_key
            is_unique_constraint = $PSItem.is_unique_constraint
            fill_factor          = $PSItem.fill_factor
            is_padded            = $PSItem.is_padded
            is_disabled          = $PSItem.is_disabled
            allow_row_locks      = $PSItem.allow_row_locks
            allow_page_locks     = $PSItem.allow_page_locks
            has_filter           = $PSItem.has_filter
            filter_definition    = $PSItem.filter_definition
            KeyColumns           = $PSItem.KeyColumns
            InclColumns          = $PSItem.InclColumns
        } 
    }
#endregion
}
