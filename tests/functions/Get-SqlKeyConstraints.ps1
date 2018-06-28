$id = (Invoke-SqlCmd -server "." -database "tempdb" -Query "select object_id('F394243C.Parent') as id").id
$keys = Get-SqlKeyConstraints -server "." -database "tempdb" -tableId $id
$pk = $keys| Where-Object key_type -eq "PK"
$ak = $keys| Where-Object key_type -eq "UQ"

Describe "Unique Key unit tests" {
    It "Key count" { $keys.Count | Should be 2 } 
    It "PK"        { $pk.u_key_name | Should be "pk_Parent" }
    It "AK"        { $ak.u_key_name | Should be "ak_Parent" }
}
