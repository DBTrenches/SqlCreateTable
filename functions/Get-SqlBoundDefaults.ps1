function Get-SqlBoundDefaults {
    [CmdletBinding()]Param(
        [Parameter(Mandatory=$true)]
            [Alias('serverName','sqlServer','server')]
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
        ServerInstance = $serverInstance
        Database       = $databaseName
    }

    $sql_GetDefaults=@"
select
    Server_Name = cast(serverproperty(N'Servername') as sysname)
   ,[Database_Name] = db_name()
   ,Table_Schema = schema_name(t.[schema_id])
   ,Table_Name = t.[name]
   ,Column_ID = ac.column_id
   ,Column_Name = ac.[name]
   ,[Name] = dc.[name]
   ,IsSystemNamed = cast(dc.is_system_named as bit)
   ,IsFileTableDefined = cast(iif(fsdo.[object_id] is null, 0, 1) as bit)
   ,[Text] = dc.[definition]
   ,Table_ID = t.[object_id]
from sys.tables t
inner join sys.all_columns ac on ac.[object_id] = t.[object_id]
inner join sys.default_constraints dc on dc.[object_id] = ac.default_object_id
left outer join sys.filetable_system_defined_objects fsdo on fsdo.[object_id] = dc.[object_id]    
where t.[object_id] = $objectId;
"@

#endregion

    (Invoke-Sqlcmd @connStr -Query $sql_GetDefaults) `
    | ForEach-Object { 
        [PSCustomObject] @{
            Server_Name        = $PSItem.Server_Name
            Database_Name      = (Get-SqlQuoteNameSparse -text $PSItem.Database_Name).text
            Table_Schema       = (Get-SqlQuoteNameSparse -text $PSItem.Table_Schema).text
            Table_Name         = (Get-SqlQuoteNameSparse -text $PSItem.Table_Name).text
            Column_ID          = $PSItem.Column_ID
            Column_Name        = (Get-SqlQuoteNameSparse -text $PSItem.Column_Name).text
            Constraint_Name    = (Get-SqlQuoteNameSparse -text $PSItem.Name).text
            IsSystemNamed      = $PSItem.IsSystemNamed
            IsFileTableDefined = $PSItem.IsFileTableDefined
            Default_Value      = $PSItem.Text
            Table_ID           = $PSItem.Table_ID
        }
    }
}