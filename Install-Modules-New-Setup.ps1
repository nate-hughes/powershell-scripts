Get-Module -ListAvailable

install-module SimplySql
install-module SqlServer
install-module AWSPowerShell

## Powershell install - No match was found for the specified search criteria and module name
## https://stackoverflow.com/questions/63385304/powershell-install-no-match-was-found-for-the-specified-search-criteria-and-mo
# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name JoinModule

# How to Install or Uninstall RSAT in Windows 11
# https://techcommunity.microsoft.com/t5/windows-11/how-to-install-or-uninstall-rsat-in-windows-11/m-p/3273590
# RSAT: Active Directory Domain Services and Lightweight Directory Services Tools

 Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser 
 
 $PSVersionTable