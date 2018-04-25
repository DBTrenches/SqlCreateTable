# Requires -Modules {SQLServer}
function Get-SqlColumns {
<#
    .SYNOPSIS
        Roughly: minor modifications to the profiled query passed to SQL Server by SMO when
		executing Script Table As > CREATE To > ... from Object Explorer.
		Returns NO DATA for views. 

	.DESCRIPTION
		Returning all columns for a single object in the sys.tables collection. 

	.EXAMPLE
		Returns columns for spt_monitor.
			$oid = (Get-SqlTable -tableName "spt_monitor" -server localhost -database master).table_id
			Get-SqlColumns -server localhost -database master -tableid $oid | ft
		
		Returns no data since spt_values is a view.
			$oid = (Get-SqlTable -tableName "spt_values" -server localhost -database master).table_id
			Get-SqlColumns -server localhost -database master -objectId $oid
#>
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
	
	$sql_getColumns = @"
select Server_Name = cast(serverproperty(N'Servername') as sysname)
	,[Database_Name] = db_name()
	,Table_Schema = schema_name(t.[schema_id])
	,Table_Name = t.[name]
	,ID = c.column_id
	,[Name] = c.[name]
	,AnsiPaddingStatus = c.is_ansi_padded
	,Collation = isnull(c.collation_name, N'')
	,ColumnEncryptionKeyID = c.column_encryption_key_id
	,Computed = c.is_computed
	,ComputedText = isnull(cc.[definition], N'')
	,DataTypeSchema = s1.[name]
	,[Default] = case
					when c.default_object_id = 0 then N''
					when d.parent_object_id > 0 then N''
					else d.[name]
				end
	,DefaultConstraintName = isnull(dc.[name], N'')
	,DefaultSchema = case
						when c.default_object_id = 0 then N''
						when d.parent_object_id > 0 then N''
						else schema_name(d.[schema_id])
					end
	,EncryptionAlgorithm = c.encryption_algorithm_name
	,EncryptionType = c.[encryption_type] 
	,GeneratedAlwaysType = c.generated_always_type
	--,GraphType = isnull(c.graph_type, 0)
	,[Identity] = c.is_identity
	,IdentitySeed = cast(isnull(ic.seed_value, 0) as bigint)
	,IdentityIncrement = cast(isnull(ic.increment_value, 0) as bigint)
	,IsFileStream = cast(c.is_filestream as bit)
	,IsPersisted = cast(isnull(cc.is_persisted, 0) as bit)
	,IsForeignKey = cast(isnull((select top 1 1
								from sys.foreign_key_columns as fkc
								where fkc.parent_column_id = c.column_id
									and fkc.parent_object_id = c.[object_id])
							,0) as bit)
	,IsMasked = c.is_masked
	,IsSparse = c.is_sparse
	,IsColumnSet = cast(c.is_column_set as bit)
	,[Length] = cast(iif(t3.[name] in (N'nchar', N'nvarchar') and c.max_length<>-1,c.max_length/2,c.max_length) as int)
	,NotForReplication = isnull(ic.is_not_for_replication, 0)
	,Nullable = c.is_nullable
	,NumericScale = cast(c.scale as int)
	,NumericPrecision = cast(c.[precision] as int)
	,[RowGuidCol] = c.is_rowguidcol 
	,[Rule] = iif(c.rule_object_id = 0,N'',r.[name])
	,RuleSchema = iif(c.rule_object_id=0,N'',schema_name(r.[schema_id]))
	,SystemType = isnull(t3.[name], N'')
	,XmlSchemaNamespace = isnull(xs.[name], N'')
	,XmlSchemaNamespaceSchema = isnull(s2.[name], N'')
	,XmlDocumentConstraint = isnull(iif(c.is_xml_document=1,2,1),0)
	,DataType = t2.[name]
-- added cols not in SMO query follow
	,TableID = t.[object_id]
	,DataTypeFriendly = t2.[name]
		+case 
			when c.user_type_id in (165,167,173,175) -- bin & ascii
				then '('+isnull(convert(varchar,nullif(c.max_length,-1)),'max')+')' 
			when c.user_type_id in (231,239) -- unicode
				then '('+isnull(convert(varchar,nullif(c.max_length,-1)/2),'max')+')' 
			when c.system_type_id in (106,108) -- decimal & numeric
				then '('+convert(varchar,c.[precision])+','+convert(varchar,c.scale)+')' 
			when c.system_type_id in (41,42,43) -- date & time w/ scale
				then '('+convert(varchar,c.scale)+')' 
			else '' 
		end
        +iif(convert(sysname,databasepropertyex(db_name(),'Collation'))<>isnull(c.collation_name, N'') 
                and c.user_type_id in (165,167,173,175,231,239) 
            ,' collate '+isnull(c.collation_name, N'')
            ,'')
        +iif(c.is_sparse=1,' sparse','')
        +iif(c.is_identity=0,''
                ,' identity('+convert(varchar(19),ic.seed_value)+','+convert(varchar(16),ic.increment_value)+')'
				  +iif(ic.is_not_for_replication=1,' not for replication',''))
	,HasBoundDefault = cast(iif(c.default_object_id=0,0,1) as bit)
from sys.tables t
join sys.all_columns c on c.[object_id] = t.[object_id]
left join sys.computed_columns cc 
	on cc.[object_id] = c.[object_id]
	and cc.column_id = c.column_id
left join sys.types t2 on t2.user_type_id = c.user_type_id
left join sys.schemas s1 on s1.[schema_id] = t2.[schema_id]
left join sys.objects d on d.[object_id] = c.default_object_id
left join sys.default_constraints dc on c.default_object_id = dc.[object_id]
left join sys.identity_columns ic 
	on ic.[object_id] = c.[object_id]
	and ic.column_id = c.column_id
left join sys.types t3 
	on (t3.user_type_id = c.system_type_id and t3.user_type_id = t3.system_type_id)
	or (
			t3.system_type_id = c.system_type_id
		and t3.user_type_id = c.user_type_id
		and t3.is_user_defined = 0
		and t3.is_assembly_type = 1
	)
left join sys.objects r on r.[object_id] = c.rule_object_id
left join sys.xml_schema_collections xs on xs.xml_collection_id = c.xml_collection_id
left join sys.schemas s2 on s2.[schema_id] = xs.[schema_id]
where t.[object_id] = $objectId;
"@
#endregion

#region execute_return
	(Invoke-Sqlcmd @connStr -Query $sql_getColumns) `
	| ForEach-Object { 
		[PSCustomObject] @{
			Server_Name              = $PSItem.Server_Name
			Database_Name            = (Get-SqlQuoteNameSparse -text $PSItem.Database_Name).Text
			Table_Schema             = (Get-SqlQuoteNameSparse -text $PSItem.Table_Schema).Text
			Table_Name               = (Get-SqlQuoteNameSparse -text $PSItem.Table_Name).Text
			Column_ID                = $PSItem.ID
			Column_Name              = (Get-SqlQuoteNameSparse -text $PSItem.Name).Text
			AnsiPaddingStatus        = $PSItem.AnsiPaddingStatus
			Collation                = $PSItem.Collation
			ColumnEncryptionKeyID    = $PSItem.ColumnEncryptionKeyID
			Computed                 = $PSItem.Computed
			ComputedText             = $PSItem.ComputedText
			DataTypeSchema           = $PSItem.DataTypeSchema
			Default                  = $PSItem.Default
			DefaultConstraintName    = (Get-SqlQuoteNameSparse -text $PSItem.DefaultConstraintName).text
			DefaultSchema            = $PSItem.DefaultSchema
			HasBoundDefault          = $PSItem.HasBoundDefault
			EncryptionAlgorithm      = $PSItem.EncryptionAlgorithm
			EncryptionType           = $PSItem.EncryptionType
			GeneratedAlwaysType      = $PSItem.GeneratedAlwaysType
			GraphType                = $PSItem.GraphType
			Identity                 = $PSItem.Identity
			IdentitySeed             = $PSItem.IdentitySeed
			IdentityIncrement        = $PSItem.IdentityIncrement
			IsFileStream             = $PSItem.IsFileStream
			IsPersisted              = $PSItem.IsPersisted
			IsForeignKey             = $PSItem.IsForeignKey
			IsMasked                 = $PSItem.IsMasked
			IsSparse                 = $PSItem.IsSparse
			IsColumnSet              = $PSItem.IsColumnSet
			Length                   = $PSItem.Length
			NotForReplication        = $PSItem.NotForReplication
			Nullable                 = $PSItem.Nullable
			NumericScale             = $PSItem.NumericScale
			NumericPrecision         = $PSItem.NumericPrecision
			RowGuidCol               = $PSItem.RowGuidCol
			Rule                     = $PSItem.Rule
			RuleSchema               = $PSItem.RuleSchema
			SystemType               = $PSItem.SystemType
			XmlSchemaNamespace       = $PSItem.XmlSchemaNamespace
			XmlSchemaNamespaceSchema = $PSItem.XmlSchemaNamespaceSchema
			XmlDocumentConstraint    = $PSItem.XmlDocumentConstraint
			DataType                 = $PSItem.DataType
			TableID                  = $PSItem.TableID
			DataTypeFriendly         = $PSItem.DataTypeFriendly
		}
	}
#endregion
}
