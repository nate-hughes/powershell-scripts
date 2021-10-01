function Get-SQLDatabaseFilesNotUsed
<#
.Synopsis
    Gets a list of SQL Server database files that are not used

.Description
    Pulls the list of active SQL Server database files from sys.master_files and then compares it to files on disk in order to identify orphaned files

.Parameter SQLServerName
    SQL Server to check

.Parameter IncludeEqual
    Switch to include or omit matching files

    Default: omit matching files

.Example
    Get-SQLDatabaseFilesNotUsed -SQLServerName "SomeSQLServerName"

.Notes
    This HAS to be "Run as Adminstrator"

    This ONLY works for SQL Servers having one instance...the other instance(s) databases will be flagged as unused

.Link
    https://dba.stackexchange.com/questions/50295/how-can-i-find-and-clean-up-unused-database-files
#>
{
param ( 
    [parameter(Mandatory = $true)][string]$SQLServerName,
    [switch]$IncludeEqual = $false
)

$SQLCommand = @"
    SET NOCOUNT ON;
    SELECT  DB_NAME([database_id]) AS [Database Name]
            ,[file_id]
            ,name
            ,physical_name
            ,type_desc
            ,state_desc
            ,CONVERT( bigint, size/128.0) AS [Total Size in MB]
    FROM    master.sys.master_files WITH (NOLOCK)
    ORDER BY DB_NAME([database_id]);
"@

$SQLDatabaseFiles = Invoke-Sqlcmd -ServerInstance $SQLServerName -Query $SQLCommand
 
$SQLDatabaseFilesInUse = $SQLDatabaseFiles | Select-Object @{Name="fullname";Expression={$_.physical_Name -replace "\\\\","\" <#SQL server allows \\ in paths and just uses it like \#> }}

$SQLDatabaseAndLogFilesOnDisk = Invoke-Command -ComputerName $SQLServerName -ScriptBlock { 
    $Filesystems = Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Name -ne "C"}

    Foreach ($FileSystem in $Filesystems) {
        Get-ChildItem $FileSystem.Root -Recurse -include *.mdf,*.ldf,*.ndf -File -ErrorAction SilentlyContinue | Select-Object fullname 
    }
}

$SQLDatabaseAndLogFilesOnDisk = $SQLDatabaseAndLogFilesOnDisk | Select-Object fullname

Compare-Object -ReferenceObject $SQLDatabaseFilesInUse -DifferenceObject $SQLDatabaseAndLogFilesOnDisk -Property FullName -IncludeEqual:$IncludeEqual | FT -AutoSize

}
