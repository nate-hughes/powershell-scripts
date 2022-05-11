$groupname = "DB-GROUP-Technology"
$users = Get-ADGroupMember -Identity $groupname | ? {$_.objectclass -eq "user"}
foreach ($activeusers in $users | sort name) { Get-ADUser -Identity $activeusers | ? {$_.enabled -eq $true} | select Name, SamAccountName, UserPrincipalName, Enabled }