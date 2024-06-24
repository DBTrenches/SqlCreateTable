Import-Module $PSScriptRoot\..\..\SqlCreateTable -Force

$setup = Get-Content $PSScriptRoot\sql\setup.sql   -Raw
$clean = Get-Content $PSScriptRoot\sql\cleanup.sql -Raw

$env = @{
    SqlInstance = "localhost"
    Database = "tempdb"
}

Invoke-DbaQuery @env -Query $clean
Invoke-DbaQuery @env -Query $setup

Invoke-Pester $PSScriptRoot\functions

Invoke-DbaQuery @env -Query $clean
