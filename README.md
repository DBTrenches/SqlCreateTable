# SqlCreateTable

SMO is super bulky. For a leaner `CREATE` table syntax, use this. Designed with future customization in mind. 

`Install-Module .\SqlCreateTable`

```
$here = (Get-Item -Path ".\").FullName
if(Test-Path $here\SqlCreateTable.psd1){
	Add-Content $profile "`r`nImport-Module $here\SqlCreateTable"
}
```

