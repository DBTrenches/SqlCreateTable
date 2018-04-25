function Get-SqlIndexColumns {
    [CmdletBinding()]Param(
        [Parameter(Mandatory=$true)]
            [Alias('serverName','sqlServer','server')]
            [string]$serverInstance
       ,[Parameter(Mandatory=$true)]
            [Alias('database','dbName')]
            [string]$databaseName
	   ,[Parameter(Mandatory=$true)]
			[Alias('object_id','oid','table_id','tableid')]   
	  		[Int32]$objectId
       ,[Parameter(Mandatory=$true)]
			[Alias('index_id','idxId')]   
            [Int32]$indexId
    )

#region query_prepare
    $connStr = @{
        ServerInstance = $serverInstance
        Database       = $databaseName
    }

    $sql_GetIndexColumns = @"
select table_id = ic.[object_id]
    ,ic.index_id
    ,ic.index_column_id
    ,ic.column_id
    ,column_name = c.[name]
    ,ic.key_ordinal
    ,ic.partition_ordinal
    ,ic.is_descending_key
    ,ic.is_included_column 
from sys.index_columns ic
join sys.columns c 
    on c.[object_id] = ic.[object_id]
    and c.column_id  = ic.column_id
where ic.[object_id] = $objectId
    and ic.index_id  = $indexId;
"@
#endregion

#region execute_return
    $idxCols = Invoke-Sqlcmd @connStr -Query $sql_GetIndexColumns

    $idxCols | ForEach-Object { 
        $KeyColumnName = (Get-SqlQuoteNameSparse -text $PSItem.column_name).text
        if($PSItem.is_included_column){$KeyColumnName = ""}
        if($PSItem.is_descending_key){
            $KeyColumnName += " desc"
        }

        [PSCustomObject] @{
            table_id           = $PSItem.table_id
            index_id           = $PSItem.index_id
            index_column_id    = $PSItem.index_column_id
            column_id          = $PSItem.column_id
            column_name        = (Get-SqlQuoteNameSparse -text $PSItem.column_name).text
            KeyColumnName      = $KeyColumnName
            key_ordinal        = $PSItem.key_ordinal
            partition_ordinal  = $PSItem.partition_ordinal
            is_descending_key  = $PSItem.is_descending_key
            is_included_column = $PSItem.is_included_column            
        } 
    }
#endregion
}