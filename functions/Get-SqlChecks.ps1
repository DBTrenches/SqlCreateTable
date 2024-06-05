function Get-SqlChecks {
    [CmdletBinding()]Param(
        [Parameter(Mandatory=$true)]
            [Alias('serverName','sqlServer','server','sqlInstance')]
            [string]$serverInstance
       ,[Parameter(Mandatory=$true)]
            [Alias('database','dbName')]
            [string]$databaseName
	   ,[Parameter(Mandatory=$true)]
			[Alias('object_id','id','oid','table_id','tableid')]   
	  		[Int32]$objectId
    )

#region query_prepare
    $connStr = @{
        SqlInstance = $serverInstance
        Database    = $databaseName
    }

    $sql_GetChecks = @"
select check_name  = cc.[name]
    ,parent_name   = object_name(cc.parent_object_id)
    ,[schema_name] = schema_name(cc.[schema_id])
    ,check_id      = cc.[object_id]
    ,parent_id     = cc.parent_object_id
    ,cc.[schema_id]
    ,cc.parent_column_id
    ,is_bindable   = convert(bit,cc.parent_column_id)
    ,cc.[definition]
    ,cc.is_disabled
    ,cc.is_not_trusted
    ,cc.uses_database_collation
    ,cc.is_system_named 
from sys.check_constraints cc
where cc.parent_object_id = $objectId;
"@
#endregion

#region execute_return
    $checks = Invoke-DbaQuery @connStr -Query $sql_GetChecks

    $checks | ForEach-Object {
        [PSCustomObject] @{
            check_name              = (Get-SqlQuoteNameSparse -text $PSItem.check_name).text
            parent_name             = (Get-SqlQuoteNameSparse -text $PSItem.parent_name).text
            schema_name             = (Get-SqlQuoteNameSparse -text $PSItem.schema_name).text
            check_id                = $PSItem.check_id
            parent_id               = $PSItem.parent_id
            schema_id               = $PSItem.schema_id
            parent_column_id        = $PSItem.parent_column_id
            is_bindable             = $PSItem.is_bindable
            definition              = $PSItem.definition
            is_disabled             = $PSItem.is_disabled
            is_not_trusted          = $PSItem.is_not_trusted
            uses_database_collation = $PSItem.uses_database_collation
            is_system_named         = $PSItem.is_system_named
        }
    }
#endregion
}