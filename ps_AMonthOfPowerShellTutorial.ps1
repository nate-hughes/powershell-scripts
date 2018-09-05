<#
Wayne Sheffield: "A Month of PowerShell" blog series
https://blog.waynesheffield.com/wayne/a-month-of-powershell/
#>

## Day 1 (Getting Started)
# Discovery cmdlets
Get-Help    # Displays help about Windows PowerShell cmdlets and concepts.
Get-Command # Gets all commands that are installed on the computer.
Get-Member  # Gets the properties and methods of objects.

# see all of the processes running on your computer
Get-Process 
# but I’m only interested in the sql processes
Get-Process | Where-Object processname -EQ 'sqlservr'

# see the list of available drives in PowerShell
# includes physical drives, drives to the HKCU and HKLM registry hives, drive to the Windows environmental variables and others
Get-PSDrive


## Day 2 (Variables and Operators)
# String variables are assigned by using quotation marks
  # Single quotation marks use the literal value inside the quotation marks as the string.
  # Double quotation marks will perform string substitution of other variables in the string.
$i = 123
$s = 'Hello'
$s2 = "$s $i"
$s2
# OUTPUT >> Hello 123

# build a string by concatenation
$q = "SELECT TOP (1000)"
$q = $q + " [BusinessEntityId],"
$q = $q + " [FirstName],"
$q = $q + " [LastName]"
$q = $q + " FROM [AdventureWorks2012].[dbo].[Person];"
$q
# use of a Here-String: starts with @” (or @’), and this must end the line that it is on. The string ends with “@ (or ‘@), which must be on a line by itself.
# Respects all line breaks, quotation marks (single or double) and white space within the string and maintains that in the variable.
$q = @"
SELECT  TOP (1000)
        [BusinessEntityId],
        [FirstName],
        [LastName]
FROM    [AdventureWorks2012].[dbo].[Person];
"@
$q

# assign variables to specific .NET data types by preceding the variable declaration with the data type:
[int]$A = 50
$A

# clear all the contents of a variable
Clear-Variable -Name A
$A
# remove/delete a variable
Remove-Variable -Name A
$A

# Arrays: ways to assign items to arrays
$A = 5,3,4,2,1                           #specific items
$B = 6..10                               #range, integers only
$C = @("String1", "String2", "String3")  #specific separate string items
$D = @()                                 #empty array
[array] $E = "a;e;i;o;u;y" -split ";"    #specific separate string items

#Hash tables (simply a Name-Value pair)
$Z = @{"Colorado" = "Denver"; "Virginia" = "Richmond"; "North Carolina" = "Raleigh"}
$Z.Add("Alaska", "Fairbanks")
$Z


## Day 3 (Security)
Get-ExecutionPolicy
# Restricted: Does not load configuration files or run scripts. The default execution policy.
# AllSigned: Requires that all scripts and configuration files be signed by a trusted publisher, including scripts that you write on the local computer.
# RemoteSigned: Requires that all scripts and configuration files downloaded from the Internet be signed by a trusted publisher.
# Unrestricted: Loads all configuration files and runs all scripts. If you run an unsigned script that was downloaded from the Internet, you are prompted
#   for permission before it runs.
# Bypass: Nothing is blocked and there are no warnings or prompts.
# Undefined: Removes the currently assigned execution policy from the current scope. This parameter will not remove an execution policy that is set in a
#   Group Policy scope.

Set-ExecutionPolicy remotesigned # for this to work, you need to be running PowerShell as an administrator


## Day 4 (Scripting)
# For readability purposes, the command continuation character is a ` (character under tilde on keyboard). For instance:
Get-Process | `
    Where-Object ProcessName -EQ 'sqlservr'

# Functions are a pre-defined script block that is assigned a name and includes 
  # “function” keyword
  # optional scope
  # name (that you select)
  # optional parameters
  # script block consisting of one or more PowerShell commands
# Best practice: follow PowerShell's verb-noun naming convention
function Get-CurrentUser
{
    [system.security.principal.windowsidentity]::GetCurrent().Name
}

Get-CurrentUser

# Modules are a group of related functions. You create the module by:
  # Placing the related functions into one script file.
  # Save the script file with a .psm1 extension.
  # Move the file into the $ENV:PSModulePath directory.
  # Load the module with the Import-Module cmdlet.
  # Unload the module with the Remove-Module cmdlet.
  # You can list the functions in the module with the Export-ModuleMember cmdlet.

# Error Handling methods: 
  # Trap function (see Get-Help Trap)
  # Try-Catch-Finally (see Get-Help Try)

# Common Trap function to handle any errors that occur
Trap
{
    # Handle the error
    $err = $_.Exception
    write-host $err.Message
    while( $err.InnerException )
    {
        $err = $err.InnerException
        write-output $err.Message
    };
    # End the script.
    break
}


## Day 5 (Scripting - Putting it together)
<#
  Disk Partition Alignment Best Practices for SQL Server
  https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008/dd758814(v=sql.100)
#>
# get various properties from the Win32_DiskPartition class
Get-WMIObject Win32_DiskPartition | `
    Select-Object DiskIndex, Index, BootPartition, StartingOffset, Size, BlockSize

# format as a table
Get-WMIObject Win32_DiskPartition | `
    Select-Object DiskIndex, Index, BootPartition, StartingOffset, Size, BlockSize | `
    Format-Table

# order it by DiskIndex and Index properties before pipelining to Select-Object 
Get-WMIObject Win32_DiskPartition | `
    Sort-Object DiskIndex, Index | `
    Select-Object DiskIndex, Index, BootPartition, StartingOffset, Size, BlockSize | `
    Format-Table

# remove white space
Get-WMIObject Win32_DiskPartition | `
    Sort-Object DiskIndex, Index | `
    Select-Object DiskIndex, Index, BootPartition, StartingOffset, Size, BlockSize | `
    Format-Table  -AutoSize

# build a hash table to set what the properties in the format-table look like
<#
  Remember a hash table is a table of Name-Value pairs
  Label: Disk           Expression: DiskIndex
  Label: Partition      Expression: Index
  Label: Boot Partition Expression: BootPartition
  etc.
  
  Hash table definition replaces Select-Object functionality

  "{0:N0}" -f explained:
  The initial 0 (before the colon) represents the index number of the item being formatted in that script block.
    In a zero-based language, this is the first (and in our case, only) item.
  The “N” represents the type of formatting to be applied; N is for Numeric.
  The final number is the number of decimal places to be displayed.
  The “-f” is the format parameter, followed by the value that we want to format.
#>
$b = @{Expression = {$_.DiskIndex};Label="Disk"},`
@{Expression = {$_.Index};Label="Partition"},`
@{Expression = {$_.BootPartition};Label="Boot Partition"},`
@{Expression = {"{0:N3}" -f ($_.Size/1Gb)};Label="Size (GB)"; align="right"},`
@{Expression = {"{0:N0}" -f ($_.BlockSize)};Label="BlockSize";align="right"},`
@{Expression = {"{0:N0}" -f ($_.StartingOffset/1Kb)};Label="Offset (KB)"; align="right"},`
@{Expression = {"{0:N0}" -f ($_.StartingOffset/$_.BlockSize)};Label="Offset (Sectors)";align="right"}
 
Get-WMIObject Win32_DiskPartition | `
    Sort-Object DiskIndex, Index | `
    Format-Table $b -AutoSize

# plug in the drive letter for the partitions
FUNCTION Get-DriveLetter($PartPath) {
       #Get the logical disk mapping
       $LogicalDisks = Get-WMIObject Win32_LogicalDiskToPartition | `
        Where-Object {$_.Antecedent -eq $PartPath}
       $LogicalDrive = Get-WMIObject Win32_LogicalDisk | `
        Where-Object {$_.__PATH -eq $LogicalDisks.Dependent}
    $LogicalDrive.DeviceID
}
 
# Hash table to set what the properties in the format-table look like
$b = @{Expression = {$_.DiskIndex};Label="Disk"},`
@{Expression = {$_.Index};Label="Partition"},`
@{Expression = {Get-DriveLetter($_.__PATH)};Label="Drive"},`
@{Expression = {$_.BootPartition};Label="Boot Partition"},`
@{Expression = {"{0:N3}" -f ($_.Size/1Gb)};Label="Size (GB)"; align="right"},`
@{Expression = {"{0:N0}" -f ($_.BlockSize)};Label="BlockSize";align="right"},`
@{Expression = {"{0:N0}" -f ($_.StartingOffset/1Kb)};Label="Offset (KB)"; align="right"},`
@{Expression = {"{0:N0}" -f ($_.StartingOffset/$_.BlockSize)};Label="Offset (Sectors)";align="right"},`
@{Expression = {IF (($_.StartingOffset % 64KB) -EQ 0) {" Yes"} ELSE {"  No"}};Label="64KB"}
 
Get-WMIObject Win32_DiskPartition | `
    Sort-Object DiskIndex, Index | `
    Format-Table $b -AutoSize

<#
  rework to output the results to a file
  Saved script: ps_GetPartitionAlignmentInfo.ps1
#>


## Day 6 (Exporting and Importing)
<# EXPORT #>
# Set-Content cmdlet
$t = @'
ServerName
localhost\SQL2005
localhost\SQL2008
localhost\SQL2008R2
localhost\SQL2012
'@
 
Set-Content -path $env:TEMP\ServerList.txt -Value $t
 
Notepad $env:TEMP\ServerList.txt

# Export-CSV cmdlet
Get-Process | `
    Where-Object ProcessName –EQ 'sqlservr' | `
    Export-CSV -Path $env:TEMP\SQLProcesses.txt -Delimiter ":"
 
Notepad $env:TEMP\SQLProcesses.txt

# Out-File cmdlet
Get-Process |`
    Where-Object ProcessName -EQ 'sqlservr' |`
    Out-File $env:TEMP\SQLProcesses.dat
 
Notepad $env:TEMP\SQLProcesses.dat

<# IMPORT #>
# Get-Content cmdlet
$i = 0
ForEach ($Item in Get-Content -Path $env:TEMP\ServerList.txt)
{
    $i += 1 # added line variable number to show this is actually working with one line at a time
    Write-Host $i, $Item
}

# Import-CSV cmdlet
$Servers = Import-CSV -Path $env:TEMP\ServerList.csv
$i = 0
ForEach ($Server in $Servers)
{
    $i += 1
    Write-Host $i, $Server.ServerName
}

Import-CSV $env:Temp\SQLProcesses.txt -Delimiter ":" |`
    Select-Object Name, Id


## Day 7 (Script Input/Output)
# Sending messages to the user
$DebugPreference = "SilentlyContinue"
Write-Debug "A fantastic, helpful debug message"
Write-Debug "A fantastic, helpful debug message" -Debug
$DebugPreference = "Continue"
Write-Debug "A fantastic, helpful debug message"
$DebugPreference = "SilentlyContinue"
 
$File = "X:\temp\output.txt"
if (!(Test-Path $File)) {Write-Error "File $File not found!"}
 
Write-Host "Here's a message for you!"
 
Write-Warning "Here's a colored message for you!"
 
Write-Verbose "Searching the Application Event Log" -Verbose
 
$ProgressPreference
for ($i = 1; $i -le 100; $i++)
{
    Write-Progress "Search in Progress" -Status "$i% Complete:" -PercentComplete $i;
}

# Getting Input from the user
$Input = Read-Host -Prompt "enter some text"
$Pwd   = Read-Host -Prompt "Enter your password" -AsSecureString
 
$Input
$Pwd

# Sending output to other locations
Get-Process | Out-Null
Get-Process | Out-Host
Get-Process | Out-File $env:TEMP\ProcessList.txt
Get-Process | Out-Printer
Get-Process | Out-String
Get-Process | Out-Default
Get-Process | Out-GridView


## Day 8 (Working with Snippets in the ISE)
<#
Snippets are a method to allow you to paste text into the ISE console with CTRL+J
Default snippets: shipped with PowerShell
Module-based snippets: for any imported module
User-defined snippets: personal, created with New-ISESnippet cmdlet
    When created, an XML file named the title of the snippet is created in the
    $Home:\Documents\WindowsPowerShell\Snippets folder with an extension of “ps1xml”.
    Snippets in the home folder will automatically be loaded. Snippets in other locations
    will have to be loaded yourself.
#>

# To delete a snippet
Get-IseSnippet
Get-IseSnippet | Remove-Item

# Generic error trapping
New-IseSnippet -Title "Error Trap-Generic" -Description "Generic Error Trapping routine" -Text ‘# Handle any errors that occur
Trap
{
    # Handle the error
    $err = $_.Exception
    write-host $err.Message
    while( $err.InnerException )
    {
        $err = $err.InnerException
        write-output $err.Message
    };
    # End the script.
    break
}'

# Generic header routine for the script files
# CaretOffset parameter places caret (aka cursor) at specified position
New-IseSnippet -Title "SMO Header" -Description "SMO Generic Header" -Text '
#Assign variables
$Instance   = "localhost\"
$DBName     = ""
$SchemaName = ""
$ObjectName = ""
 
#Assign the SMO class to a variable
$SMO        = "Microsoft.SqlServer.Management.Smo"
 
# get the server
$Server = New-Object ("$SMO.Server") "$Instance"
 
# assign the database name to a variable
$MyDB = $Server.Databases[$DBName]
 
# assign the schema to a variable
$Schema = $MyDB.Schemas[$SchemaName]
 
' -CaretOffset 150


## Day 9 (Getting Started with SMO)
<#
http://msdn.microsoft.com/en-us/library/ms162169.aspx: “SQL Server Management Objects (SMO) is a collection
of objects that are designed for programming all aspects of managing Microsoft SQL Server.”
#>

<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream

=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
# get list of all SQL instances on this server along with Service Account, OS, Version, ProductLevel and Edition
Get-ChildItem SQLSERVER:\SQL\LocalHost | 
    Select-Object InstanceName, ServiceAccount, Platform, Version, ProductLevel, Edition |`
    Format-Table -AutoSize

# get all of the SQL Servers on your network
[System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources()

# get list of all databases on an instance
Get-ChildItem SQLServer:\SQL\localhost\Default\Databases


<#
STARTING RUNNING INTO ISSUES
SWITCHED TO eBOOK "PowerShell for SQLServer including SQL 2016"
#>
<<<<<<< Updated upstream
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
