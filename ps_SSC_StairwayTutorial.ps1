## SQLServerCentral - Stairway to SQL PowerShell - tutorial scripts & notes ##

<#
Stairway to SQL PowerShell Level 3: Input and Output with PowerShell
http://www.sqlservercentral.com/articles/Stairway+Series/91448/
#>

# Out-* cmdlets
"DBAduck" | Out-Host                          # output to screen
"DBAduck" | Out-File C:\Windows\Temp\file.txt # output to file
"DBAduck" | Out-Null                          # discard output
"DBAduck" | Out-GridView                      # output to GridView (outside PowerShell window)

# Out-* cmdlets using Variables instead of Pipeline
$name = “DBAduck” 
Out-Host –InputObject $name 
Out-File –FilePath C:\Windows\Temp\file.txt –InputObject $name 
Out-Null –InputObject $name 
Out-GridView –InputObject $name

# Out-* cmdlets using Variables with switches
$name = “DBAduck”
Out-File –FilePath C:\Windows\Temp\file.txt –InputObject $name –Append    # add to the end of existing file
Out-File –FilePath C:\Windows\Temp\file.txt –InputObject $name –NoClobber # don't over-write the existing file
# -NoClobber throws an error because the file already exists

# *-Content cmdlets
Add-Content -LiteralPath C:\Windows\Temp\addcontent.txt -Value “This is a test”  # Add content to end of file or create file if doesn't exist
“This is another test” | Add-Content –LiteralPath C:\Windows\Temp\addcontent.txt

Get-Content C:\Windows\Temp\addcontent.txt                                       # Get content from file by line into collection of objects, typically strings
ForEach($var in (Get-Content C:\Windows\Temp\addcontent.txt)) { $var } 

Set-Content -LiteralPath C:\Windows\Temp\setcontent.txt -Value “Setting Content” # Set content to a file; if file exists, contents will be replaced
Get-Content C:\Windows\Temp\setcontent.txt 
Set-Content -LiteralPath C:\Windows\Temp\setcontent.txt -Value “Other Content” 
Get-Content C:\Windows\Temp\setcontent.txt

# Import-CSV and Export-CSV
Get-Process | Export-Csv C:\Windows\Temp\process.csv # Get-Process: get the processes on my computer
$processes = Import-Csv C:\Windows\Temp\process.csv
$processes | Get-Member

# Write-* cmdlets
$age = Read-Host "Please enter your age "
Write-Host “Thank you for playing. You are $age years old.”
Write-Output “This is output”
Write-Error “This is an error”
Write-Warning “This is a warning”

# Write-Output is a little more useful than other Write-* commands as it can be used to return values from a Function as well as to write data to the output of your script
ForEach($item in (Get-ChildItem C:\Windows\Temp)) { Write-Output $item.FullName }
Get-Help Write-Output -full


<#
Stairway to SQL PowerShell Level 4: Objects in SQL PowerShell
http://www.sqlservercentral.com/articles/Stairway+Series/93403/
#>

# Using Get-Member to show different parts of an Object
Get-EventLog –Logname System | Select –First 1 | Get-Member

# Get SMO (Shared Management Objects) Server Object with Properties, Methods, Events
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList "localhost"
$server | Get-Member

# Code to enumerate global trace flags in this instance
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList localhost
$server.EnumActiveGlobalTraceFlags()

# Using PingSqlServerVersion to get version from an instance
$server = New-Object –TypeName Microsoft.SqlServer.Management.Smo.Server –ArgumentList localhost
$server.PingSqlServerVersion(“localhost”)

# EnumProcesses method, $true and $false
$server = New-Object –TypeName Microsoft.SqlServer.Management.Smo.Server –ArgumentList localhost
$server.EnumProcesses($true)| Format-Table -Auto   # $true excludes System SPIDs
$server.EnumProcesses($false) | Format-Table –Auto # $false includes System SPIDs

<#
Try the method on the Server object called GetActiveDBConnectionCount with a parameter of the database name
in a string. Use the Script method with no parameters, and see what you get when you use the Server object
and try it against a Database object (hint: $db = Server.Databases[“dbname”]).
#>
$server = New-Object –TypeName Microsoft.SqlServer.Management.Smo.Server –ArgumentList localhost
$db = $server.Databases["rp_util"]
$server.GetActiveDBConnectionCount($db)


<#
Stairway to SQL PowerShell Level 5: SQL Server PowerShell Building Blocks
http://www.sqlservercentral.com/articles/Stairway+Series/97805/
#>

# Variations of Loading Assemblies
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
[System.Reflection.Assembly]::Load("Microsoft.SqlServer.Smo")
[System.Reflection.Assembly]::Load("Microsoft.SqlServer.Smo, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")
[System.Reflection.Assembly]:: LoadFrom("c:\Sample.Assembly.dll")
[System.Reflection.Assembly]:: LoadFile("c:\Sample.Assembly.dll")
# last two threw an error

Add-Type –AssemblyName "Microsoft.SqlServer.Smo"
Add-Type –AssemblyName "Microsoft.SqlServer.Smo, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

# Use of a static function in String object
# Static members are objects that can be used without loading the assembly
[String]::Format("{0} is a good guy.", "Ben")
# Output: Ben is a good guy

# Basic building blocks of a Function
Function Get-ProcessExamples {                                # Function name in Verb-Noun form
   Param (                                                    # Parameter block
       $sqlserver
   )

   Begin { Write-Host "This is a pre-processor $sqlserver" }  # Begin block: one time piece of code that runs first and then does not run again until function is called again
   Process { Write-Host "This is the main body $sqlserver" }  # Process block: run against multiple rows or objects
   End { Write-Host "This is the post-processor $sqlserver" } # End block: one time piece of code that runs before the function ends
}
Get-ProcessExamples localhost

# Create function Get-SqlMaxMemory
Function Get-SqlMaxMemory {
	Param ( [string]$sqlserver )
	
	$sqlconn = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $sqlserver
	
	$maxmem = $sqlconn.Configuration.MaxServerMemory.RunValue
	Write-Output $($maxmem)
}
Get-SqlMaxMemory localhost


<#
Stairway to SQL PowerShell Level 6: PowerShell Modules
http://www.sqlservercentral.com/articles/Stairway+Series/109321/
Modules are simply a collection of functions that are most likely related to each other and packaged in a way that allow you to import them as a group.
#>

# Loading TestSqlModule into your PowerShell session
# Command to import a module named TestSqlModule
# PowerShell will look in My Documents\WindowsPowerShell\Modules\TestSqlModule for a file called TestSqlModule.psm1
# Or in the C:\Windows\System32\WindowsPowerShell\v1.0\Modules\TestSqlModule directory
Import-Module TestSqlModule

# To list modules available to load or import
Get-Module –ListAvailable


# Creating a file that will be used with dot-sourcing
# dot sourcing a file with a function to reuse the function
# save the following code into a file called afunction.ps1
Function Get-CurrentDirListing {
   Dir
}

# If you've created the file suggested above, you can now go to a command line in PowerShell and run the following starting with the .
. C:\Users\nateh\Documents\WindowsPowerShell\afunction.ps1
# If afunction.ps1 exists and contains a function called Get-CurrentDirListing, and you dot-sourced it, then you could call Get-CurrentDirListing
Get-CurrentDirListing

<#
Couldn't get following steps for SQLPSX to work
#>
# Import Module SQLPSX and get a database
# module set SQLPSX at http://sqlpsx.codeplex.com
Import-Module SQLPSX

# localhost\I12 is my instance name, but you can substitute an instance that you have to test this.
$db = Get-SqlDatabase –sqlserver localhost –dbname master
$db.Name


<#
Stairway to SQL PowerShell Level 7: SQL Server PowerShell and the Basics of SMO
http://www.sqlservercentral.com/articles/Stairway+Series/109921/
#>

# Making a Configuration Change to SQL Server
# Begin 1st Run script
Add-Type –AssemblyName "Microsoft.SqlServer.Smo, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
# Changed Version=11.0.0.0 (2008R2) to Version=13.0.0.0 (2016)
$server = New-Object –TypeName Microsoft.SqlServer.Management.Smo.Server –ArgumentList "localhost"
$server.Configuration.MaxServerMemory
$server.Configuration.MaxServerMemory.ConfigValue = 12288 #17408
$server.Alter()
# End 1st Run script 
# Clear the profiler window and run the following statement
# to see if the next statement produces any profiler output
$server.Configuration.MaxServerMemory
# Begin 2nd Run script (reset value)
$server.Configuration.MaxServerMemory.ConfigValue = 17408
$server.Alter()
$server.Configuration.MaxServerMemory
# End 2nd Run script 

#Retrieval of Database Properties via SMO
Add-Type –AssemblyName "Microsoft.SqlServer.Smo, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
$server = New-Object –TypeName Microsoft.SqlServer.Management.Smo.Server –ArgumentList "localhost"
$db = $server.Databases["rp_util"]
$db | Select Name, ID, DataSpaceUsage, SpaceAvailable, Size | Format-Table –Auto

# Making a Database Property Change
Add-Type –AssemblyName "Microsoft.SqlServer.Smo, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
$server = New-Object –TypeName Microsoft.SqlServer.Management.Smo.Server –ArgumentList "localhost"
$db = $server.Databases["rp_util"]
$db.PageVerify = "CHECKSUM"
$db.RecoveryModel = "Full"
$db.Alter()
#Verify
$db.PageVerify
$db.RecoveryModel
# Reset RecoveryModel
$db.RecoveryModel = "Simple"
$db.RecoveryModel

# Using Get-Member to see the nature of the properties
$server | Get-Member -Type Property


<#
Stairway to SQL PowerShell Level 8: SQL Server PowerShell Provider
http://www.sqlservercentral.com/articles/Stairway+Series/117133/
#>

# Loading SQL Provider by Version
#SQL 2008/R2
Get-PSSnapin –Registered
Add-PSSnapin SqlServerCmdletSnapin 
Add-PSSnapin SqlServerProviderSnapin
#SQL 2012
Import-Module SQLPS –DisableNameChecking
#SQL 2014
Import-Module SQLPS –DisableNameChecking
#SQL 2016
Import-Module SqlServer –DisableNameChecking

<#
SQLPS cmdlets:     https://docs.microsoft.com/en-us/powershell/module/sqlps/?view=sqlserver-ps
SqlServer cmdlets: https://docs.microsoft.com/en-us/powershell/module/sqlserver/?view=sqlserver-ps
#>

# Examples of Path-Like structures in SQL Server
# change directories to the SQL Provider at the Instance level
Cd SQLSERVER:\sql\localhost\DEFAULT
# list the databases in the instance
Dir Databases | Select Name
# See if database Ben exists
Test-Path SQLSERVER:\sql\localhost\DEFAULT\Databases\Ben
# See system databases
Dir Databases –Force | Select Name

# PowerShell to get the Tables and Script them in SQL using the Provider
$sqlpath = "SQLSERVER:\sql\localhost\DEFAULT\Databases\rp_util\Tables"

ForEach($tb in (Get-ChildItem $sqlpath)) {
    $tb.Script() | Add-Content "C:\Windows\Temp\$($tb.Name)_table.sql"
}


<#
Stairway to SQL PowerShell Level 9: Objects For Everyone
http://www.sqlservercentral.com/articles/Stairway+Series/122675/
#>

# remove all imported modules
Get-Module | Remove-Module

### START: Create Login ###
<#
Tutorial version wasn't working so I scrapped it and went with this one:
  Creating a SQL Server Login Using PowerShell and SMO
  https://mcpmag.com/articles/2017/11/30/creating-a-sql-server-login.aspx
#>
## Add Assemblies 
  Add-Type -AssemblyName  "Microsoft.SqlServer.ConnectionInfo,  Version=13.0.0.0,  Culture=neutral,  PublicKeyToken=89845dcd8080cc91"   -ErrorAction Stop
  Add-Type -AssemblyName  "Microsoft.SqlServer.Smo,  Version=13.0.0.0,Culture=neutral,PublicKeyToken=89845dcd8080cc91"  -ErrorAction Stop
  Add-Type -AssemblyName  "Microsoft.SqlServer.SMOExtended,  Version=13.0.0.0, Culture=neutral,  PublicKeyToken=89845dcd8080cc91"   -ErrorAction Stop
  Add-Type -AssemblyName  "Microsoft.SqlServer.SqlEnum,  Version=13.0.0.0, Culture=neutral,  PublicKeyToken=89845dcd8080cc91"   -ErrorAction Stop
  Add-Type -AssemblyName  "Microsoft.SqlServer.Management.Sdk.Sfc,  Version=13.0.0.0,Culture=neutral,   PublicKeyToken=89845dcd8080cc91" -ErrorAction  Stop

## Connect to the SQL Server 
  $sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server ("localhost")

## Create SQL Logins first
  $sqlServer.Logins | Format-Table -Property Parent, ID, Name, CreateDate,  LoginType

  [Microsoft.SqlServer.Management.Smo.Login]::New 

  ## Below Commented lines failed: Method invocation failed because [Microsoft.SqlServer.Management.Smo.Login] does not contain a method named 'New'.
  #$SQLLogin = [Microsoft.SqlServer.Management.Smo.Login]::New($sqlServer, 'TestUser') 
  #$SQLLogin.LoginType  = [Microsoft.SqlServer.Management.Smo.LoginType]::SqlLogin
  #$SQLLogin.PasswordPolicyEnforced  = $False 
  #$SQLLogin.Create
  #$SQLLogin.Create('SuperSecretPassword,DontTell!')
  
  $SQLLogin = New-Object -TypeName microsoft.sqlserver.management.smo.login -ArgumentList $sqlServer,"TestUser"
  $SQLLogin.LoginType = "SqlLogin"
  $SQLLogin.PasswordPolicyEnforced = $false
  $SQLLogin.Create('SuperSecretPassword,DontTell!')

  #Verify SQL Logon created
  $sqlServer.Logins.Refresh()
  $sqlServer.Logins | Format-Table -Property Parent, ID, Name, CreateDate,  LoginType

## Create domain account
  ## Below Commented lines failed: Method invocation failed because [Microsoft.SqlServer.Management.Smo.Login] does not contain a method named 'New'.
  #$SQLWindowsLogin = [Microsoft.SqlServer.Management.Smo.Login]::New($sqlServer, 'rivendell\admin.prox')
  #$SQLWindowsLogin.LoginType  = [Microsoft.SqlServer.Management.Smo.LoginType]::WindowsUser
  #$SQLWindowsLogin.Create() 

  $SQLWindowsLogin = New-Object -TypeName microsoft.sqlserver.management.smo.login -ArgumentList $sqlServer,"REALPOINTDEV\nateh"
  $SQLWindowsLogin.LoginType = "WindowsUser"
  $SQLWindowsLogin.Create()
  
  #Verify SQL Logon created
  $sqlServer.Logins.Refresh()
  $sqlServer.Logins | Format-Table -Property Parent, ID, Name, CreateDate,  LoginType

## Drop logins
  $ToDrop = $sqlServer.Logins['TestUser']
  $ToDrop.Drop()     
  
  $ToDrop = $sqlServer.Logins['REALPOINTDEV\rlyddy']
  $ToDrop.Drop()

  #Verify SQL Logon created
  $sqlServer.Logins.Refresh()
  $sqlServer.Logins | Format-Table -Property Parent, ID, Name, CreateDate,  LoginType
### END: Create Login ###

### START: Create a Database ###
  Add-Type -AssemblyName "Microsoft.SqlServer.Smo, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
  Add-Type -AssemblyName "Microsoft.SqlServer.SmoExtended, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

  $class = "Microsoft.SqlServer.Management.Smo"
  #$server = New-Object -TypeName "$class.Server" -ArgumentList "LOCALHOST\DEFAULT" # put your instance name in this place
  $server = new-object ('Microsoft.SqlServer.Management.Smo.Server') "LOCALHOST"

  $db = New-Object -TypeName "$class.Database" -ArgumentList $server, "TestDb"

  $filegroup = New-Object -TypeName "$class.Filegroup" -ArgumentList $db, "PRIMARY"

  $db.FileGroups.Add($filegroup)

  $file = New-Object -TypeName "$class.DataFile" -ArgumentList $filegroup, "$($db.Name)_Data"

  $file.Size = 256000
  $file.GrowthType = "KB" 
  $file.Growth = 256000
  $file.MaxSize = 20202020
  $file.FileName = "D:\MSSQL12.MSSQLSERVER\SQL_DATA\TestDb.mdf"

  $filegroup.Files.Add($file)

  $logfile = New-Object -TypeName "$class.LogFile" -ArgumentList $db, "$($db.Name)_log"

  $logfile.Size = 128000
  $logfile.GrowthType = "KB" 
  $logfile.Growth = 128000
  $logfile.MaxSize = 20202020
  $logfile.FileName = "D:\MSSQL12.MSSQLSERVER\SQL_DATA\TestDb_log.ldf"

  $db.LogFiles.Add($logfile)

  $db.Create()
### END: Create a Database ###

### START: Create a Database User ###
  Add-Type -AssemblyName "Microsoft.SqlServer.Smo, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
  Add-Type -AssemblyName "Microsoft.SqlServer.SmoExtended, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

  $class = "Microsoft.SqlServer.Management.Smo"
  #$server = New-Object -TypeName "$class.Server" -ArgumentList "LOCALHOST\DEFAULT"  #put your own server name in
  $server = new-object ('Microsoft.SqlServer.Management.Smo.Server') "LOCALHOST"

  $db = $server.Databases["TestDb"]
  $name = "TestUser"
  $login = "TestUser"

  $user = New-Object -TypeName "$class.User" -ArgumentList $db, $name
  $user.Login = $login
  $user.DefaultSchema = 'dbo'

  $user.Create()
### END: Create a Database User ###

### START: Create a Table ###
  Add-Type -AssemblyName "Microsoft.SqlServer.Smo, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
  Add-Type -AssemblyName "Microsoft.SqlServer.SmoExtended, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

  $class = "Microsoft.SqlServer.Management.Smo"
  #$server = New-Object -TypeName "$class.Server" -ArgumentList "LOCALHOST\S1"  #put your own server name in
  $server = new-object ('Microsoft.SqlServer.Management.Smo.Server') "LOCALHOST"

  $db = $server.Databases["TestDb"]

  #$Table1 = New-Object -TypeName "$class.Table" -ArgumentList $db, "Table1"
  $Table1 = New-Object ("Microsoft.SqlServer.Management.Smo.Table") ($db, "Table1", "dbo")
  #$Table1Id = New-Object -TypeName "$class.Column" -ArgumentList "Table1, $Table1Id"

  #$DataTypeInt = New-Object -TypeName "$class.DataType" -Argumentlist "Int"
  $DataTypeInt = [Microsoft.SqlServer.Management.SMO.DataType]::Int
  $Table1Id =  New-Object -TypeName Microsoft.SqlServer.Management.SMO.Column -argumentlist $Table1,"Table1Id", $DataTypeInt  
  $Table1Id.Nullable = $false
  #$Table1Id.DataType = $DataTypeInt
  $Table1.Columns.Add($Table1Id)

  #$Name = New-object -TypeName "$class.Column" -ArgumentList $Table1, "Name"

  #$DataTypeVarChar = New-Object -TypeName "$class.datatype" -ArgumentList "VarChar", 50
  $DataTypeVarChar = [Microsoft.SqlServer.Management.SMO.DataType]::VarChar(50) 
  $Name =  New-Object -TypeName Microsoft.SqlServer.Management.SMO.Column -argumentlist $Table1,"Name", $DataTypeVarChar  
  $Name.Nullable = $true
  #$Name.DataType = $DataTypeVarChar
  $Table1.Columns.Add($Name)

  $Table1.Create()
### END: Create a Table ###

### START: Create an Index ###
  Add-Type -AssemblyName "Microsoft.SqlServer.Smo, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
  Add-Type -AssemblyName "Microsoft.SqlServer.SmoExtended, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

  $class = "Microsoft.SqlServer.Management.Smo"
  #$server = New-Object -TypeName "$class.Server" -ArgumentList "LOCALHOST\S1"
  $server = new-object ('Microsoft.SqlServer.Management.Smo.Server') "LOCALHOST"
  $db = $server.Databases["TestDb"]

  $table = $db.Tables["Table1"]

  $index = New-Object -TypeName "$class.Index" -ArgumentList $table, "NewIndex"

  $col1 = New-Object -TypeName "$class.IndexedColumn" -ArgumentList $index, "Table1Id", $true
  $index.IndexedColumns.Add($col1)

  $index.IndexKeyType = [Microsoft.SqlServer.Management.Smo.IndexKeyType]::DriPrimaryKey
  $index.IsClustered = $true

  $index.Create()
### END: Create an Index ###


<#
Stairway to SQL PowerShell Level 10: Getting data in and out of SQL Server using SQL Server PowerShell
http://www.sqlservercentral.com/articles/Stairway+Series/134672/
#>

## Using ExecuteNonQuery (used to execute TSQL and return no results)
$version = "13.0.0.0"
Add-Type -AssemblyName "Microsoft.SqlServer.Smo, Version=$version, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

$instance = "localhost"
$dbname = "TestDb"
$class = "Microsoft.SqlServer.Management.Smo"

$server = New-Object –TypeName "$class.Server" –Args $instance
$db = $server.Databases[$dbname]

$db.ExecuteNonQuery(“INSERT INTO dbo.Table1 (Table1Id, Name) VALUES (1, 'BoboBob')”)
# There should now be a row in the table with Name = BoboBob

## Using ExecuteWithResults (used to execute TSQL and return results)
$version = "13.0.0.0"
Add-Type -AssemblyName "Microsoft.SqlServer.Smo, Version=$version, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

$instance = "localhost"
$dbname = "TestDb"
$class = "Microsoft.SqlServer.Management.Smo"

$server = New-Object –TypeName "$class.Server" –Args $instance
$db = $server.Databases[$dbname]

$ds = $db.ExecuteWithResults(“SELECT * FROM dbo.Table1”)

$dt = $ds.Tables[0]

$dt | ft Table1Id, Name -Auto
# You should see the row in the table.

## Using Invoke-Sqlcmd (cmdlet will return a set of row objects from the query that is executed)
# To gain access to the cmdlet Invoke-Sqlcmd you need to load the module sqlps
Import-Module sqlps –DisableNameChecking

$instance = "localhost"
$dbname = "TestDb"

$results = Invoke-SqlCmd –ServerInstance $instance –Database $dbname –Query “SELECT * FROM dbo.Table1”

$results | ft Table1Id, Name -Auto
# You should see the rows in the table.

## Using Invoke-Sqlcmd2 (return the results as a DataTable or DataRow)
# To gain access to the Function Invoke-Sqlcmd2 you need to dot source the file Invoke-Sqlcmd2.ps1
# you can get the file at 
# https://gallery.technet.microsoft.com/scriptcenter/7985b7ef-ed89-4dfd-b02a-433cc4e30894
. C:\Users\nateh\Documents\WindowsPowerShell\Invoke-Sqlcmd2.ps1

$instance = "localhost"
$dbname = "TestDb"

$results = Invoke-SqlCmd2 –ServerInstance $instance –Database $dbname –Query “SELECT * FROM dbo.Table1” –As DataTable

$results | ft Table1Id, Name -Auto
# You should see the rows in the table.Listing 10.5 Using Invoke-Sqlcmd2

## Using .Net to get data out
$ServerInstance = "localhost"
$Database = "TestDb"
$ConnectionTimeout = 30
$Query = "SELECT * FROM dbo.Table1"

$conn = new-object System.Data.SqlClient.SQLConnection
$ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance, $Database, $ConnectionTimeout

$conn.ConnectionString = $ConnectionString

$conn.Open()
$cmd = New-Object system.Data.SqlClient.SqlCommand($Query, $conn)
$ds = New-Object System.Data.DataSet
$da = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
[void]$da.Fill($ds)
$conn.Close()

$ds.Tables[0] | ft Table1Id, Name –Auto
# You should see the row in the table.

## Writing data to SQL with Write-DataTable
# To gain access to the Function Invoke-Sqlcmd2 you need to dot source the file Invoke-Sqlcmd2.ps1
# you can get the file at 
# https://gallery.technet.microsoft.com/scriptcenter/7985b7ef-ed89-4dfd-b02a-433cc4e30894
# Create a table as a clone to Table1
# IF object_id('Table2') IS NOT NULL DROP TABLE Table2;
# CREATE TABLE dbo.Table2 (Table2Id int NOT NULL, Name varchar(50) )
. C:\Users\nateh\Documents\WindowsPowerShell\Invoke-Sqlcmd2.ps1
. C:\Users\nateh\Documents\WindowsPowerShell\Write-DataTable.ps1

$instance = "localhost"
$dbname = "TestDb"

$results = Invoke-SqlCmd2 –ServerInstance $instance –Database $dbname –Query “SELECT * FROM dbo.Table1” –As DataTable

# Original script threw ERROR:
# Write-DataTable : System.Management.Automation.MethodInvocationException: Exception calling "WriteToServer" with "1" argument(s): "Cannot access destination table 'dbo.Table2'."  
# built table and then ran
Write-DataTable –ServerInstance $instance –Database $dbname –TableName “dbo.Table2” –Data $results

$newtable = Invoke-SqlCmd2 –ServerInstance $instance –Database $dbname –Query “SELECT * FROM dbo.Table2” –As DataTable

$newtable | ft Table1Id, Name -Auto
# You should see the rows in the table.

## Writing data to SQL with Write-DataTable with custom DataTable
# Create a new table to hold the data called Table3
# IF object_id('Table3') IS NOT NULL DROP TABLE Table3;
# CREATE TABLE dbo.Table3 (Table3Id int NOT NULL, Name varchar(50), EmailAddress varchar(128) )
. C:\Users\nateh\Documents\WindowsPowerShell\Invoke-Sqlcmd2.ps1
. C:\Users\nateh\Documents\WindowsPowerShell\Write-DataTable.ps1

$instance = "localhost"
$dbname = "TestDb"

$dt = New-Object –TypeName System.Data.DataTable –Args “ImportData”
$colTable3Id = New-Object System.Data.DataColumn "Table1Id", ([int])
$colName = New-Object system.Data.DataColumn "Name", ([string])
$colName.MaxLength = 50
$colEmail = New-Object system.Data.DataColumn BobColumn, ([string])
$colEmail.MaxLength = 128

$dt.Columns.Add($colTable3Id)
$dt.Columns.Add($colName)
$dt.Columns.Add($colEmail)

$row = $dt.NewRow()
$row.Table1Id = 50
$row.Name = "Ben Miller"
$row.BobColumn = "email@hotmail.com"

$dt.Rows.Add($row)

$row = $dt.NewRow()
$row.Table1Id = 51
$row.Name = "Kalen Delaney"
$row.BobColumn = "different_email@hotmail.com"

$dt.Rows.Add($row)

# Original script threw ERROR:
# Write-DataTable : System.Management.Automation.MethodInvocationException: Exception calling "WriteToServer" with "1" argument(s): "Cannot access destination table 'dbo.Table3'."
# built table and then ran
Write-DataTable –ServerInstance $instance –Database $dbname –TableName “dbo.Table3” –Data $dt

$newtable = Invoke-SqlCmd2 –ServerInstance $instance –Database $dbname –Query “SELECT * FROM dbo.Table3” –As DataTable

$newtable | ft Table1Id, Name, EmailAddress -Auto
# You should see the rows in the table.


<#
Stairway to SQL PowerShell Level 11: SQL Server Maintenance Using SQL PowerShell
http://www.sqlservercentral.com/articles/Stairway+Series/134713/
#>

### START: Server Information ###

## Getting SQL Server Configuration properties list
# Load the Assemblies
Import-Module SQLPS –DisableNameChecking
$server = Get-Item SQLSERVER:\sql\localhost\default

$server.Configuration.Properties | 
      Select –First 10 DisplayName, ConfigValue, RunValue, IsDynamic | 
              FT * -AutoSize

## Insert snapshot of configuration into table
<# SqlConfigMonitor table for storing snapshots of configuration
CREATE TABLE dbo.SqlConfigMonitor (
	DisplayName varchar(128) NOT NULL,
	ConfigValue varchar(10) NULL,
	RunValue varchar(10) NULL,
	IsDynamic bit NULL,
	GatherDate datetime NOT NULL DEFAULT(getdate())
)
#>
. C:\Users\nateh\Documents\WindowsPowerShell\Out-DataTable.ps1
. C:\Users\nateh\Documents\WindowsPowerShell\Write-DataTable.ps1

$server = Get-Item SQLSERVER:\sql\localhost\default
$config = $server.Configuration.Properties | 
      Select DisplayName, ConfigValue, RunValue, IsDynamic | 
              Out-DataTable

Write-DataTable -ServerInstance localhost `
    -Database TestDb -TableName SqlConfigMonitor `
    -Data $config

$query = "SELECT * FROM dbo.SqlConfigMonitor"
Invoke-Sqlcmd –ServerInstance localhost –Query $query –Database TestDb

### END: Server Information ###

### START: Maintaining a Database using PowerShell ###

## Retrieve serveral database properties
$database = Get-Item SQLSERVER:\sql\localhost\default\Databases\TestDb
$database | Select Name, PageVerify, CompatibilityLevel |
    ft * -AutoSize

## Changing database properties
$database = Get-Item SQLSERVER:\sql\localhost\default\Databases\TestDb
$database.PageVerify = "CHECKSUM"
$database.CompatibilityLevel = "120"
$database.Alter()

$database.Refresh()
$database | Select Name, PageVerify, CompatibilityLevel |
    ft * -AutoSize 

### END: Maintaining a Database using PowerShell ###

### START: Index Maintenance with PowerShell ###
<# TSQL to Rebuild or Reorganize the index
CREATE TABLE [dbo].[TestTable](
	[id] [int] NULL,
	[test] [varchar](30) NULL,
	[test2] [varchar](30) NULL
) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_TestTable_ID] ON [dbo].[TestTable]
(
	[id] ASC
)

ALTER INDEX IX_TestTable_ID ON dbo.TestTable REBUILD
ALTER INDEX IX_TestTable_ID ON dbo.TestTable REORGANIZE
#>

## PowerShell and SMO used to Rebuild and Reorganize Indexes
# get the database
$database = Get-Item SQLSERVER:\sql\localhost\default\Databases\TestDb

# get the index, in this case very specific
$index = $database.Tables["TestTable"].Indexes["IX_TestTable_ID"]

# Rebuild the index
$index.Rebuild()

# Reorganize the index
$index.Reorganize()

### END: Index Maintenance with PowerShell ###


