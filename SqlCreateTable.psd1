<#
    Manifest File for 'SqlCreateTable'
#>
@{
    RootModule        = 'SqlCreateTable.psm1'
    ModuleVersion     = '0.1.0'
    Author            = 'Peter Vandivier'
    RequiredModules   = @(
        @{
            ModuleName = 'dbatools'
            ModuleVersion = ' 2.1.15'
            Guid = '9d139310-ce45-41ce-8e8b-d76335aa1789'
        }
    )
    FunctionsToExport = '*'
    CmdletsToExport   = '*'
    VariablesToExport = '*'
}