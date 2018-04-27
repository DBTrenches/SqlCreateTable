# SqlCreateTable

SMO Create-Table output was too bulky & I'm a delicate flower, so I wrote this to satisfy my Golidlocks-level pickiness. Pipes out prettified `CREATE` object syntax for SQL tables & dependent objects.

`Install-Module .\SqlCreateTable`

```
$here = (Get-Item -Path ".\").FullName
if(Test-Path $here\SqlCreateTable.psd1){
	Add-Content $profile "`r`nImport-Module $here\SqlCreateTable"
}
```

