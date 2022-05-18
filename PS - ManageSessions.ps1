# create new remote PS session
$sql_servers = New-PSSession -ComputerName sqlserver1,sqlserver2,sqlserver3

# show sessions
Get-PSSession

# enter session
Get-PSSession -ComputerName sqlserver1 | Enter-PSSession 

<# RUN SOME COMMANDS #>

# exit session
Exit-PSSession

# close session
Get-PSSession | Remove-PSSession # all open session
Remove-PSSession -Session $sql_servers # just sql_servers session
