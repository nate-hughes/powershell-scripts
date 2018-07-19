<#
SQLServerCentral Stairway to SQL PowerShell: http://www.sqlservercentral.com/stairway/91327/
#>

## Changing the ExecutionPolicy value ##
## NOTE: requires "Run As Administrator" 

Get-ExecutionPolicy
# Restricted: Allows you to run script only through the interactive console. No script files are allowed to be executed. Only interactive sessions are allowed.
# RemoteSigned: Allows scripts to run on the local machine but requires scripts to be signed if downloaded from the internet.
# AllSigned: Requires all scripts to be signed.
# Unrestricted: Runs all scripts without restriction, if you download a script from the internet, you will be prompted for permission to run.
# Bypass: Nothing is blocked and there are no warnings or prompts.

Set-ExecutionPolicy RemoteSigned


## Modify profile ##
## NOTE: need to restart ISE w/o "Run As Administrator"

$profile # get path to profile

notepad $profile # open profile to edit

# copy the following block to notepad, save and restart ISE
<#
$global:CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()

Import-Module SqlServer

function prompt
{
    $wintitle = $CurrentUser.Name + " " + $Host.Name + " " + $Host.Name
    $host.ui.rawui.WindowTitle = $wintitle
    Write-Host ("PS " + $(get-location) +">") -nonewline -foregroundcolor Magenta 
    return " "
}
#>


## enable working w/ SQL Server in PowerShell

# verify that PowerShell is able to see SQL Server module
Get-Module -ListAvailable -Name SQL*

# unload/load SQL Server module
Remove-Module SqlServer
Import-Module SqlServer

# verify SQL Server module loaded
Get-Command -Module SqlServer -CommandType Cmdlet #| Out-GridView
