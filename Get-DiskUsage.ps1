# collect disk usage info
Get-CimInstance win32_logicaldisk  |
    Where-Object {$_.MediaType -eq 12 <#Fixed hard disk media#>} |
    Select-Object -Property SystemName, DeviceId, VolumeName, Size, FreeSpace, @{name="CollectionDate";expression={Get-Date}} |
    Format-Table SystemName, DeviceId, VolumeName, @{name="Size";expression={[math]::Round($_.Size/1MB,0)}},@{name="FreeSpace";expression={[math]::Round($_.FreeSpace/1MB,0)}},@{name="PctUsed";expression={1.0-([math]::Round($_.FreeSpace/$_.Size,2))}},CollectionDate
    
