<#
    Manifest File for 'SqlCreateTable'
#>
@{
    RootModule        = 'SqlCreateTable.psm1'
    ModuleVersion     = '0.0.1'
    Author            = 'Peter Vandivier'
    RequiredModules   = @('SQLPS')
    FunctionsToExport = @(
        'Get-SqlKeyWords'
        'Get-SqlQuoteNameSparse'
        'Get-SqlTable'
        'Get-SqlBoundDefaults'
        'Get-SqlChecks'
        'Get-SqlColumns'
        'Get-SqlForeignKeys'
        'Get-SqlFkColumns'
        'Get-SqlIndexes'
        'Get-SqlIndexColumns'
        'Get-SqlKeyConstraints'
        'Format-SqlCheckConstraint'
        'Format-SqlForeignKey'
        'Format-SqlIndex'
        'Format-SqlKeyConstraint'
        'Format-SqlTableColumn'
        'Get-SqlCreateTable'
    )
    CmdletsToExport   = '*'
    VariablesToExport = '*'
}