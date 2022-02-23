function Get-SqlKeyConstraints {
<#
.EXAMPLE
    $id = (Invoke-SqlCmd -server "." -database "tempdb" -Query "select object_id('F394243C.Parent') as id").id
    Get-SqlKeyConstraints -server "." -database "tempdb" -tableId $id
#>
    [CmdletBinding()]Param(
        [Parameter(Mandatory)]
            [Alias('serverName','sqlServer','server')]
            [string]$serverInstance
       ,[Parameter(Mandatory)]
            [Alias('database','dbName')]
            [string]$databaseName
	   ,[Parameter(Mandatory)]
			[Alias('parent_object_id','parent_id','parentId','table_id')]   
	  		[Int32]$tableId
    )

#region query_prepare
    $connStr = @{
        ServerInstance = $serverInstance
        Database       = $databaseName
    }
    
    $sql_GetUKeys = @"
select u_key_name  = kc.[name]
    ,parent_name   = object_name(kc.parent_object_id)
    ,[schema_name] = schema_name(kc.[schema_id])
    ,u_key_ordinal = row_number() over (partition by kc.parent_object_id order by iif(kc.[type]=N'PK',0,1) asc)
    ,u_key_id      = kc.[object_id]
    ,parent_id     = kc.parent_object_id
    ,kc.[schema_id]
    ,key_type      = kc.[type] 
    ,key_type_desc = kc.[type_desc]
    ,kc.unique_index_id
    ,kc.is_system_named
    --,kc.is_enforced 
    ,idx_type      = i.[type]
    ,idx_type_desc = i.[type_desc]
from sys.key_constraints kc
join sys.indexes i 
    on i.index_id = kc.unique_index_id
    and i.[object_id] = kc.parent_object_id
where kc.parent_object_id = $tableId;
"@
#endregion

#region execute_return
    $keys = Invoke-Sqlcmd @connStr -Query $sql_GetUKeys
    
    $keys | ForEach-Object {
        $indexID = $PSItem.unique_index_id
        $uKeyCols = Get-SqlIndexColumns @connStr -tableID $tableId -indexID $indexID

        $PSItem | Add-Member -MemberType NoteProperty -Name KeyColumns -Value $uKeyCols
    }

    $keys | ForEach-Object {
        [PSCustomObject] @{
            u_key_name      = (Get-SqlQuoteNameSparse -text $PSItem.u_key_name).text
            parent_name     = (Get-SqlQuoteNameSparse -text $PSItem.parent_name).text
            schema_name     = (Get-SqlQuoteNameSparse -text $PSItem.schema_name).text
            u_key_ordinal   = $PSItem.u_key_ordinal
            u_key_id        = $PSItem.u_key_id
            parent_id       = $PSItem.parent_id
            schema_id       = $PSItem.schema_id
            key_type        = $PSItem.key_type
            key_type_desc   = $PSItem.key_type_desc
            unique_index_id = $PSItem.unique_index_id
            is_system_named = $PSItem.is_system_named
            is_enforced     = $PSItem.is_enforced
            idx_type        = $PSItem.idx_type
            idx_type_desc   = $PSItem.idx_type_desc
            KeyColumns      = $PSItem.KeyColumns
        }
    }
#endregion
}