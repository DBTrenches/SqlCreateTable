function Get-SqlFkColumns {
        [CmdletBinding()]Param(
            [Parameter(Mandatory=$true)]
                [Alias('serverName','sqlServer','server')]
                [string]$serverInstance
           ,[Parameter(Mandatory=$true)]
                [Alias('database','dbName')]
                [string]$databaseName
           ,[Parameter(Mandatory=$true)]
                [Alias('foreign_key_id','fk_id','id','foreignKey_id','foreignKeyId')]   
                [Int32]$fkId
        )

#region query_prepare
    $connStr = @{
        ServerInstance = $serverInstance
        Database       = $databaseName
    }

    $sql_GetFkCol = @"
select fk_id            = fkc.constraint_object_id
    ,ordinal_position   = fkc.constraint_column_id
    ,fkc.parent_column_id
    ,parent_column_name = pc.[name]
    ,child_column_name  = cc.[name]
from sys.foreign_key_columns fkc
join sys.columns pc 
    on pc.[object_id] = fkc.parent_object_id
    and pc.column_id  = fkc.parent_column_id
join sys.columns cc 
    on cc.[object_id] = fkc.referenced_object_id
    and cc.column_id  = fkc.referenced_column_id
where fkc.constraint_object_id = $fkId;
"@
#endregion 

#region execute_return

    (Invoke-Sqlcmd @connStr -Query $sql_GetFkCol) `
    | ForEach-Object {
        [PSCustomObject] @{
            fk_id              = $PSItem.fk_id
            ordinal_position   = $PSItem.ordinal_position
            parent_column_id   = $PSItem.parent_column_id
            parent_column_name = (Get-SqlQuoteNameSparse -text $PSItem.parent_column_name).text
            child_column_name  = (Get-SqlQuoteNameSparse -text $PSItem.child_column_name).text
        }
    }
}
