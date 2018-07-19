<#
.SYNOPSIS
Gets a ServerConnection.
.DESCRIPTION
The Get-SqlConnection function gets a ServerConnection to the specified SQL Server.
.INPUTS
None
    You cannot pipe objects to Get-SqlConnection 
.OUTPUTS
Microsoft.SqlServer.Management.Common.ServerConnection
    Get-SqlConnection returns a Microsoft.SqlServer.Management.Common.ServerConnection object.
.EXAMPLE
Get-SqlConnection "localhost\instancename"
This command gets a ServerConnection to SQL Server localhost\instancename using Windows Authentication.
.EXAMPLE
Get-SqlConnection " localhost\instancename " "sa" "Passw0rd"
This command gets a ServerConnection to SQL Server localhost\instancename using SQL authentication.
.LINK
Get-SqlConnection 
#>
function Get-SqlConnection
{
    param(
    [Parameter(Position=0, Mandatory=$true)] [string]$sqlserver,
    [Parameter(Position=1, Mandatory=$false)] [string]$username, 
    [Parameter(Position=2, Mandatory=$false)] [string]$password
    )
    
    if($Username -and $Password)
    { $con = new-object ("Microsoft.SqlServer.Management.Common.ServerConnection") $sqlserver,$username,$password }
    else
    { $connection = new-object ("Microsoft.SqlServer.Management.Common.ServerConnection") $sqlserver }
	
    $connection.Connect()

    Write-Output $connection
    
} #Get-SqlConnection


Export-ModuleMember -function Get-SqlConnection