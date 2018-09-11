#Import the SQL Server module and create the SMO Server object.
Import-Module SQLPS
$instanceName = "localhost"
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName

<#
Then we specify what we want returned. We ask for the list of databases 
and then send them through the pipeline and request the data returned in a list format.
#>

$server.Logins | Format-List

<#ADDING A NEW LOGIN
The below lines of code will create a new login for "Mark".
#>
$loginName = "Mark"
$login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $server, $loginName

<#
Here we specify the LoginType is SqlLogin and verify PasswordExpirationEnabled is disabled.
Then we prompt the user for the password, and create the login.
#>
$login.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::SqlLogin
$login.PasswordExpirationEnabled = $false
$pw = Read-Host "Enter preferred password" –AsSecureString

#Next we invoke the Create method of the Login class to create the configured login
$login.Create($pw)

<#Pause
Switch to SSMS and refresh Logins folder, then notice 'Mark' is listed.
#>

<#ADDING A DATABASE USER
The below lines of code will create a new database user named "Mark" which will map
to the corresponding server login we created above.
#>
$loginName = "Mark"

<#
This next line of code will retrieve the corresponding server login we would like 
to map the new database user to.
#>
$login = $server.Logins[$loginName]

<#
Then we configure the database mapping
#>
$databasename = "AdventureWorks2014"
$database = $server.Databases[$databasename]

<#
Finally, the below code will create the database user.
#>
$dbUserName = "Mark"
$dbuser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User -ArgumentList $database, $dbUserName

$dbuser.Login = $loginName
$dbuser.Create()

<#Pause
Switch to SSMS and refresh Users folder, then notice 'Mark' is listed.
#>

<#GETTING PERMISSIONS
The below lines of code will list logins, their assigned roles, database mappings and permissions.
NOTE: user needs permissions on at least one object w/in DB to show up
#>
$databases = @("AdventureWorks2014")
$results = @()

$databases | ForEach-Object {
  $database = $server.Databases[$_]
  $users = $database.Users
}

#PROPERTIES
$users |
  Sort-Object -Property Name |
  Where-Object IsSystemObject -EQ $false |
  ForEach-Object {
    $user  = $_

    #OBJECT PERMISSIONS
    $database.EnumObjectPermissions($user.Name) | ForEach-Object {
      $perm = $_
      $item = [PSCustomObject] @{
        Login = $user.Login
        DBUser = $user.Name
        DBName = $database.Name
        DBRoles = ($user.EnumRoles())
        Object = $perm.ObjectName
        Permission = $perm.PermissionType
      }
      $results += $item
    }
  }

$results | Format-Table -AutoSize
