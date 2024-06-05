function Get-SqlForeignKeys {
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

    $sql_GetFk = @"
select fk_name             = fk.[name]
    ,fk_id               = fk.[object_id]
    ,fk_schema           = schema_name(fk.[schema_id])
    ,parent_table_id     = fk.parent_object_id
    ,parent_table_schema = object_schema_name(fk.parent_object_id)
    ,parent_table_name   = object_name(fk.parent_object_id)
    ,child_table_id      = fk.referenced_object_id
    ,child_table_schema  = object_schema_name(fk.referenced_object_id)
    ,child_table_name    = object_name(fk.referenced_object_id)
    ,fk.key_index_id
    ,fk.is_disabled
    ,fk.is_not_trusted
    ,fk.delete_referential_action
    ,fk.delete_referential_action_desc
    ,fk.update_referential_action
    ,fk.update_referential_action_desc
    ,fk.is_system_named 
from sys.foreign_keys fk 
where fk.parent_object_id = $objectId;
"@
#endregion

#region execute_return

    $fks = Invoke-DbaQuery @connStr -Query $sql_GetFk

    $fks | ForEach-Object {
        $fkId = $PSItem.fk_id
        $fkc = Get-SqlFkColumns @connStr -fkId $fkId

        $numCols = ($fkc | Measure-Object).Count
        $isBindable = ($numCols -eq 1)
        if($isBindable){$pColId = $fkc.parent_column_id} else {$pColId = [int]$null}
        $pCol = ($fkc | Sort-Object -Property fk_id, ordinal_position).parent_column_name -join ","
        $cCol = ($fkc | Sort-Object -Property fk_id, ordinal_position).child_column_name  -join ","

        $PSItem | Add-Member -MemberType NoteProperty -Name NumberOfColumns -Value $numCols
        $PSItem | Add-Member -MemberType NoteProperty -Name IsBindable      -Value $isBindable
        $PSItem | Add-Member -MemberType NoteProperty -Name ParentColumnID  -Value $pColId
        $PSItem | Add-Member -MemberType NoteProperty -Name ParentCols      -Value $pCol
        $PSItem | Add-Member -MemberType NoteProperty -Name ChildCols       -Value $cCol
    }

    $fks | ForEach-Object {
        $p_s = (Get-SqlQuoteNameSparse -text $PSItem.parent_table_schema).text
        $p_t = (Get-SqlQuoteNameSparse -text $PSItem.parent_table_name).text
        $p_c = $PSItem.ParentCols

        $c_s = (Get-SqlQuoteNameSparse -text $PSItem.child_table_schema).text
        $c_t = (Get-SqlQuoteNameSparse -text $PSItem.child_table_name).text
        $c_c = $PSItem.ChildCols
                
        [PSCustomObject] @{
            fk_name             = (Get-SqlQuoteNameSparse -text $PSItem.fk_name).text
            fk_id               = $PSItem.fk_id
            fk_schema           = (Get-SqlQuoteNameSparse -text $PSItem.fk_schema).text
            parent_table_id     = $PSItem.parent_table_id
            parent_table_schema = $p_s
            parent_table_name   = $p_t
            child_table_id      = $PSItem.child_table_id
            child_table_schema  = $c_s
            child_table_name    = $c_t
            key_index_id        = $PSItem.key_index_id
            is_disabled         = $PSItem.is_disabled
            is_not_trusted      = $PSItem.is_not_trusted
            del_ref_act         = $PSItem.delete_referential_action
            OnDeleteAction      = ("on delete", ($PSItem.delete_referential_action_desc).Replace("_"," ").ToLower()) -join " "
            upd_ref_act         = $PSItem.update_referential_action
            OnUpdateAction      = ("on update", ($PSItem.update_referential_action_desc).Replace("_"," ").ToLower()) -join " "
            is_system_named     = $PSItem.is_system_named
            NumberOfColumns     = $PSItem.NumberOfColumns
            IsBindable          = $PSItem.IsBindable
            ParentColumnID      = $PSItem.ParentColumnID
            ParentCols          = $p_c
            ChildCols           = $c_c
            ParentFullRef       = "$p_s.$p_t ( $p_c )"
            ChildFullRef        = "$c_s.$c_t ( $c_c )"
        }
    }
#endregion
}