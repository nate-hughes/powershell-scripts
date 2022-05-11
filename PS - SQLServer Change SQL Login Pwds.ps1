<#
How to Create a Random Password Generator
https://adamtheautomator.com/random-password-generator/
#>
function New-RandomPassword {
    param(
        [Parameter()]
        [int]$MinimumPasswordLength = 12,
        [Parameter()]
        [int]$MaximumPasswordLength = 17,
        [Parameter()]
        [int]$NumberOfAlphaNumericCharacters = 5,
        [Parameter()]
        [switch]$ConvertToSecureString
    )
    
    Add-Type -AssemblyName 'System.Web'
    $length = Get-Random -Minimum $MinimumPasswordLength -Maximum $MaximumPasswordLength
    $password = [System.Web.Security.Membership]::GeneratePassword($length,$NumberOfAlphaNumericCharacters)
    if ($ConvertToSecureString.IsPresent) {
        ConvertTo-SecureString -String $password -AsPlainText -Force
    } else {
        $password
    }
}


# retrieve SQL Logins
$sqlserver = localhost
$logins_qry = "select name from sys.server_principals where name like 'cm %';"
Invoke-Sqlcmd -ServerInstance $sqlserver -Query $logins_qry | ForEach {
    $sql_login = $_.name
    $password = New-RandomPassword
    $alter_stmt = "ALTER LOGIN [$sql_login] WITH PASSWORD=N'$password';";
    $alter_stmt
}
