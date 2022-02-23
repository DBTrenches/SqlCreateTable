# Requires -Modules {SQLServer}
function Get-SqlCreateTable {
<#
    .SYNOPSIS
        Given a table, returns a corresponding complete "CREATE TABLE" sql script.

    .DESCRIPTION
		Allows for returning all columns in the sys.columns collection. 
		Also allows for filtering to a single object. 
		Requires an exact $object_id to be known. See Also: Get-Help Get-SqlTable 
        
    .VARIABLES
        SCRIPTS: "sql_"
            Variables intended to be complete, executable sql are prefixed "sql_"
        COLLECTIONS: "col_"
            Variables that are collections of object metadata to be parsed 
            and transformed into text snippets are prefixed "col_"
        WORKER_VARS:
            Utility Variables in the script follow the form "$_[A-ZA-Z]";
            that is: "$_" followed by two uppercase letters. A more complete 
            description of these can be found from the base of this repo at 
            ~/doc/variable-disambiguation.md but a brief summary follows
                +----------+----------------+
                | var_name | long_name      |
                +----------+----------------+
                | $_TB     | tab            |
                | $_TL     | tab length     |
                | $_NL     | newline        |
                | $_WS     | whitespace     |
                | $_CL     | current line   |
                | $_CM     | column (max)   |
                | $_DM     | DataType (max) |
                +----------+----------------+

    .PARAMETERS
        OPTIONS: "opt_"
            User-supplied syntax modifiers are prefixed "opt_"
            Many of the scripting options have been added as placeholders 
                for vNext work but are unsupported currently.
            Where [switch] options have been defaulted to $true, the intent
                is to keep naming uniformity. It is preferrable to have...
                    $opt_KeepA
                    $opt_KeepB = $true
                ...in lieu of...
                    $opt_KeepA
                    $opt_LoseB
                vFinal aims to parse user options from a config and splat them.
                In this iteration, all switches will have a $true/$false
                assignation & naming uniformity is the best way to keep clarity.
        TO_REVIEW:
            In aggregate, this is actually a pretty stupid usage of [switch]
            vars, maybe swap all for [bool]? Refactor this...

    .EXAMPLE
        The following example... 
            1. sets a splatted connection string
            2. retrieves the identifier for master..spt_monitor
            3. Extracts the "CREATE TABLE ..." script and...
              b. Pipes it to a file
            4. Opens the file in vscode

            $connStr=@{server="."
                database="master"}
            $tbl = (Get-SqlTable @connStr -table spt_monitor).table_id
            (Get-SqlCreateTable @connStr $tbl).CreateTableCommand `
            | Out-File .\spt_values.sql -encoding ascii
            code .\spt_values.sql
#>
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
       ,[byte]$opt_IndentLen = 4
       ,[switch]$opt_UseTabsNotSpaces
       ,[switch]$opt_VerboseNull
       ,[switch]$opt_UseDbHeader
       ,[switch]$opt_BindDefaults   = $true
       ,[switch]$opt_AlignDatatypes = $true
       ,[switch]$opt_TrailingComma
       ,[switch]$opt_TrailingPK
       ,[switch]$opt_InLineFK       = $true
       ,[switch]$opt_InLinePK       = $true
       ,[switch]$opt_InLineChecks   = $true
    )

#region collections

    $connStr = @{
        ServerInstance = $serverInstance
        DatabaseName   = $databaseName
    }

    $col_Table    = Get-SqlTable          @connStr -objectId $objectId 
    $col_UKeys    = Get-SqlKeyConstraints @connStr -tableId $objectId 
    $col_Columns  = Get-SqlColumns        @connStr -objectId $objectId
    $col_Defaults = Get-SqlBoundDefaults  @connStr -objectId $objectId
    $col_FKeys    = Get-SqlForeignKeys    @connStr -objectId $objectId
    $col_Checks   = Get-SqlChecks         @connStr -objectId $objectId
    $col_Indexes  = Get-SqlIndexes        @connStr -objectId $objectId

# Do this only after @connStr has been populated
# otherwise square brackets might get injected 
    $databaseName = (Get-SqlQuoteNameSparse -text $databaseName).text
    $schemaName   = $col_Table.schema_name
    $tableName    = $col_Table.table_name

#endregion

#region static_vars

    if($opt_IndentLen -gt 8){
        Write-Verbose "Max permitted single indentation length is 8 spaces."
        Write-Verbose "Requested indentation size of '$opt_IndentLen' will be overwritten to 8."
        $opt_IndentLen = 4
    }

# TODO: handle for non-aligned user preference
    $_CM = [byte]($col_Columns.Column_Name      | Measure-Object -Maximum -Property Length).Maximum
    $_DM = [byte]($col_Columns.DataTypeFriendly | Measure-Object -Maximum -Property Length).Maximum
    $_TB = "".PadRight($opt_IndentLen)
    $_TL = $_TB.Length
    $_WS = "".PadRight($_TB + $_CM + $_DM)
    $_NL = "`r`n"

    $sql_useDb = @"
use $databaseName
go
"@
    $sql_createTable = @"
create table $schemaName.$tableName (
"@
    if($opt_UseDbHeader){
        $sql_createTable = "$sql_useDb $_NL $sql_createTable"
    }
#endregion

#region body_batch

    $keyCount = ($col_UKeys | Measure-Object).Count
    if($keyCount -gt 0){
        $col_UKeys | ForEach-Object {
            $uk = (Format-SqlKeyConstraint -UKey $PSItem).InLineUnBound
            
            if($PSItem.u_key_ordinal -eq 1){ # skip first comma first key (TODO: clean this up...)
                $sql_createTable += "$_NL    $uk"
            } else {
                $sql_createTable += "$_NL   ,$uk"
            }
        }
    }

# Body in-line
    $col_Columns | ForEach-Object {
        $column_id   = $PSItem.Column_ID
        $column_name = $PSItem.Column_Name
        $_CL = $_WS

        if(($column_id -eq 1) -and ($keyCount -eq 0)){ # skip first comma on tables w/ any key constraint (TODO: clean this up...)
        } else {
            $_CL = $_CL.Insert($_TL-1,",")
        }
        
        $_CL = $_CL.Insert($_TL,$column_name)
        
        $_CL = $_CL.Insert(($_TL+1+$_CM),$PSItem.DataTypeFriendly)
        
        if(-not $PSItem.Nullable){
            $_CL = $_CL.Insert(($_TL+1+$_CM+$_DM)," not null")
        } elseif ($opt_VerboseNull) {
            $_CL = $_CL.Insert(($_TL+1+$_CM+$_DM)," null")
        }
        
        $_CL = $_CL.TrimEnd()

        if($PSItem.HasBoundDefault -and $opt_BindDefaults){ # Bound Defaults
            $boundDefault = $col_Defaults | Where-Object {$PSItem.Column_ID -eq $column_id}
            if($boundDefault.IsSystemNamed){
                $boundDefaultDef="default $($boundDefault.Default_Value)"
            } else {
                $boundDefaultDef="constraint $($boundDefault.Constraint_Name) default $($boundDefault.Default_Value)"
            }
            $_CL += "$_NL$_TB$_TB"
            $_CL += $boundDefaultDef
        }

        $col_Checks | Where-Object {($PSItem.parent_column_id -eq $column_id) -and ($opt_InLineChecks)} `
        | ForEach-Object {
            $checkDef = (Format-SqlCheckConstraint -Check $PSItem).InLineBound
            $_CL += "$_NL$_TB$_TB$checkDef"
        }

        $fk = $col_FKeys | Where-Object {
            ($opt_InLineFK) `
            -and ($PSItem.ParentColumnID -eq $column_id)
        }   
        if(($fk | Measure-Object).Count -gt 0){
            $foreignKeyDef = (Format-SqlForeignKey -ForeignKey $fk).InLineBound
            $_CL += "$_NL$_TB$_TB"
            $_CL += $foreignKeyDef
        }
        
        $sql_createTable += "$_NL$_CL"
    }

# Body non-bindable
    $col_Checks | Where-Object {(-not $PSItem.is_bindable) -and ($opt_InLineChecks)} `
    | ForEach-Object {
        $checkDef = (Format-SqlCheckConstraint -Check $PSItem).InLineUnBound
        $sql_createTable += "$_NL   ,$checkDef"
    }

    $col_FKeys | Where-Object {($opt_InLineFK) -and (-not $PSItem.IsBindable)} `
    | ForEach-Object { # Non-bindable, in-line FKs
        $fk = (Format-SqlForeignKey -ForeignKey $PSItem).InLineUnBound
        $sql_createTable += "$_NL   ,$fk"
    }

    $sql_createTable += "$_NL);$($_NL)go$_NL"

#endregion

#region follow_batches
    Write-Verbose "TODO: suffixed defaults to go here w/ other post-scripts constraints (checks/FK/etc...)"
    $col_Defaults    | Where-Object {(-not $opt_BindDefaults)} `
    | ForEach-Object {}
    
    $col_Checks | Where-Object {(-not $opt_InLineChecks)} `
    | ForEach-Object {
        $checkDef = (Format-SqlCheckConstraint -Check $PSItem).OutOfLine
        $sql_createTable += "$_NL   ,$checkDef"
    }

    $col_FKeys | Where-Object {(-not $opt_InLineFK)} `
    | ForEach-Object {
        $fk = (Format-SqlForeignKey -ForeignKey $PSItem).OutOfLine
        $sql_createTable += $fk
    }
    
    $col_Indexes | Where-Object{((-not $PSItem.is_unique_constraint) -and (-not $PSItem.is_primary_key))} `
    | ForEach-Object {
        $idx = (Format-SqlIndex -Index $PSItem).CreateIndexCommand
        $sql_createTable += $idx
    }

#endregion

    [PSCustomObject] @{
        CreateTableCommand = $sql_createTable
    }
}
