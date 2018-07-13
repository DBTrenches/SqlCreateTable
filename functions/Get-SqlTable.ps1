# Requires -Modules {SQLServer}
function Get-SqlTable {
<#
    .SYNOPSIS
        Given a partial table identifier, return sanitized identifiers for uniform use.

    .DESCRIPTION
        Permits full name to be passed simply through the table paramter.
        Alternately schema name will be prepended if passed separately.
        Retrieves the object_id via parameterized input & then passes it to direct-executed sql.

#>
    [CmdletBinding()]Param(
        [Parameter(Mandatory=$true)]
            [Alias('serverName','sqlServer','server')]
            [string]$serverInstance
       ,[Parameter(Mandatory=$true)]
            [Alias('database','dbName')]
            [string]$databaseName
       ,[Parameter()][Int32]$objectId = $null
       ,[Parameter()]
			[Alias('schema')]
              [string]$schemaName
       ,[Parameter()]
			[Alias('table')]
              [string]$tableName
    )

    $connStr = @{
        ServerInstance = $serverInstance
        Database       = $databaseName
    }

    if($objectId -eq [Int32]$null) {
        if(-not [string]::IsNullOrEmpty($schemaName)){
            $tableName     = (Get-SqlQuoteNameSparse -text $tableName).text
            $schemaName    = (Get-SqlQuoteNameSparse -text $schemaName).text
            $tableFullName = "$schemaName.$tableName"
        } else {
            $tableFullName = $tableName
        }
        Write-Verbose "Parsed full name is '$tableFullName'."
        Write-Verbose "Searching in database '$databaseName' on server '$serverInstance'."

        $sql_objId = "select [object_id] = isnull(object_id(@table_full_name),0);"
        $conn=new-object data.sqlclient.sqlconnection "Server=$serverInstance;Initial Catalog=$databaseName;Integrated Security=True"
        $conn.open()
        $cmd=new-object system.Data.SqlClient.SqlCommand($sql_objId,$conn)
        $cmd.CommandTimeout=1
        [Void]$cmd.Parameters.AddWithValue("@table_full_name",$tableFullName)
        $ds=New-Object system.Data.DataSet
        $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
        $da.fill($ds) | Out-Null
        $conn.Close()
        
        $ds.Tables | ForEach-Object {
            $objectId = $PSItem.object_id
        }
        
        Write-Verbose "Discovered Object_ID is '$objectId'."
    } else {
        Write-Verbose "User-supplied Object_ID of '$objectId' will be searched."
    }
    
    $sql_getTable = @"
select 
     table_id        = t.[object_id]
    ,table_name      = t.[name]
    ,[schema_name]   = s.[name]
    ,c.num_columns
    ,has_pk          = convert(bit,iif(pk.pk_id is null,0,1))
    ,is_pk_sys_named = pk.is_system_named
    ,pk_name         = isnull(pk.pk_name,'')
    ,pk.pk_id
    ,pk.unique_index_id
    ,is_pk_clustered = convert(bit,iif(pk.[type]=1,1,0))
    ,t.lob_data_space_id -- do stuff if not 0 (zero) or default FG/DS
from sys.tables t
join sys.schemas s on s.[schema_id] = t.[schema_id]
outer apply (
    select num_columns = count(*) 
    from sys.columns c 
    where c.[object_id] = t.[object_id]
) c
outer apply (
    select pk_name = kc.[name]
        ,pk_id   = kc.[object_id]
        ,kc.unique_index_id
        ,kc.is_system_named
        ,i.[type]
    from sys.key_constraints kc
    left join sys.indexes i 
        on i.[object_id] = kc.parent_object_id
        and i.index_id = kc.unique_index_id
    where kc.parent_object_id = t.[object_id]
        and kc.[type] = N'PK'
) pk
where t.[object_id] = $objectId;
"@

    Invoke-Sqlcmd @connStr -Query $sql_getTable | ForEach-Object {
        $out_schema = (Get-SqlQuoteNameSparse -text $PSItem.schema_name).text
        $out_table  = (Get-SqlQuoteNameSparse -text $PSItem.table_name).text
        [PSCustomObject] @{
            table_id        = $PSItem.table_id
            schema_name     = $out_schema
            table_name      = $out_table 
            full_name       = "$out_schema.$out_table"
            num_columns     = $PSItem.num_columns
            has_pk          = $PSItem.has_pk
            is_pk_sys_named = $PSItem.is_pk_sys_named
            pk_name         = (Get-SqlQuoteNameSparse -text $PSItem.pk_name).text
            pk_id           = $PSItem.pk_id
            unique_index_id = $PSItem.unique_index_id
            is_pk_clustered = $PSItem.is_pk_clustered
        }
    }
}