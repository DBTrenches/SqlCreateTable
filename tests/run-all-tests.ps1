Import-Module $PSScriptRoot\..\..\SqlCreateTable -Force

$setup = Get-Content $PSScriptRoot\sql\setup.sql   -Raw
$clean = Get-Content $PSScriptRoot\sql\cleanup.sql -Raw

$env = @{
    ServerInstance = "localhost"
    Database = "tempdb"
}

Invoke-Sqlcmd @env -Query $clean
Invoke-Sqlcmd @env -Query $setup

Invoke-Pester $PSScriptRoot\functions

Invoke-Sqlcmd @env -Query $clean
