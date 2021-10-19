

$Path = "C:\Temp\"
"$($Path)Test_$(Get-Date -f yyyyMMdd_HHmmss).txt"

$Path = "C:\Temp"
[string]::Format(“{0}\{1}_{2}.txt”, $Path, ‘Test’, (Get-Date -f yyyyMMdd_HHmmss))

$Path = "C:\Temp"
‘{0}\{1}_{2}.txt’ -f $Path, ‘Test’, (Get-Date -f yyyyMMdd_HHmmss)
