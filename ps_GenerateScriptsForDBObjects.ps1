# Use PowerShell to Script SQL Database Objects
# https://blogs.technet.microsoft.com/heyscriptingguy/2010/11/04/use-powershell-to-script-sql-database-objects/

# ScriptingOptions Class
# https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.scriptingoptions.aspx

#Clear screen (for testing)
Clear-Host

#Define database and login
$ServerName = "RPDEVSQLVS1.REALPOINTDEV.GMACCM.COM"
#$ServerName = "LOCALHOST"
$DBName = "MORA"

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
$SMOserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') -argumentlist $ServerName
$db = $SMOserver.databases[$DBName]

$Objects = $db.Views
#$Objects += $db.Tables
$Objects += $db.StoredProcedures
$Objects += $db.UserDefinedFunctions
$Objects += $db.Synonyms
$Objects += $db.Triggers

#Build this portion of the directory structure out here in case scripting takes more than one minute.
$SavePath = "D:\DB-Scripts\" + $($DBName)
$DateFolder = get-date -format yyyyMMddHHmm
new-item -type directory -name "$DateFolder"-path "$SavePath"
$USEStmt = "USE " + $($DBName) + "
GO"

foreach ($ScriptThis in $Objects | where {!($_.IsSystemObject)}) {

#Need to Add Some mkDirs for the different $Fldr=$ScriptThis.GetType().Name
$scriptr = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)
$scriptr.Options.Encoding = [System.Text.Encoding]::ASCII
$scriptr.Options.AppendToFile = $True            # specifies whether the script is appended to the end of the output file or overwrites it.
$scriptr.Options.AllowSystemObjects = $False     # specifies whether system objects can be scripted.
$scriptr.Options.ClusteredIndexes = $True        # specifies whether statements that define clustered indexes are included in the generated script.
$scriptr.Options.DriAll = $True                  # specifies whether all DRI objects are included in the generated script.
$scriptr.Options.ScriptDrops = $False            # specifies whether the script operation generates a Transact-SQL script to remove the referenced component.
$scriptr.Options.IncludeHeaders = $False         # specifies whether the generated script is prefixed with a header that contains information which includes the date and time of generation.
$scriptr.Options.ToFileOnly = $True              # specifies whether to output to file only or to also generate string output.
$scriptr.Options.Indexes = $True                 # specifies whether indexes are included in the generated script.
$scriptr.Options.Permissions = $False            # specifies whether to include all permissions in the generated script.
$scriptr.Options.WithDependencies = $False       # specifies whether to include all dependent objects in the generated script.
<#Script the Drop too#>
$ScriptDrop = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)
$ScriptDrop.Options.Encoding = [System.Text.Encoding]::ASCII
$ScriptDrop.Options.AppendToFile = $True
$ScriptDrop.Options.AllowSystemObjects = $False
$ScriptDrop.Options.ClusteredIndexes = $True
$ScriptDrop.Options.DriAll = $True
$ScriptDrop.Options.ScriptDrops = $True
$ScriptDrop.Options.IncludeHeaders = $False
$ScriptDrop.Options.ToFileOnly = $True
$ScriptDrop.Options.Indexes = $True
$ScriptDrop.Options.WithDependencies = $False
$ScriptDrop.Options.IncludeIfNotExists = $True    # specifies whether to check the existence of an object before including it in the script.
<#This section builds folder structures.  Remove the date folder if you want to overwrite#>
$TypeFolder=$ScriptThis.GetType().Name
if ((Test-Path -Path "$SavePath\$DateFolder\$TypeFolder") -eq "true") 
        {"Scripting Out $TypeFolder $ScriptThis"} 
    else {new-item -type directory -name "$TypeFolder"-path "$SavePath\$DateFolder"}
$ScriptFile = $ScriptThis -replace "\[|\]"
$ScriptDrop.Options.FileName = "" + $($SavePath) + "\" + $($DateFolder) + "\" + $($TypeFolder) + "\" + $($ScriptFile) + ".SQL"
$scriptr.Options.FileName = "$SavePath\$DateFolder\$TypeFolder\$ScriptFile.SQL"
#This is where each object actually gets scripted one at a time.
$ScriptDrop.Script($ScriptThis)
$scriptr.Script($ScriptThis)
"USE " + $($DBName) + ";
GO

" + (Get-Content "$SavePath\$DateFolder\$TypeFolder\$ScriptFile.SQL" -Raw) | Set-Content "$SavePath\$DateFolder\$TypeFolder\$ScriptFile.SQL"
(Get-Content "$SavePath\$DateFolder\$TypeFolder\$ScriptFile.SQL" -Raw) | Foreach-Object {$_ -replace 'SET ANSI_NULLS ON
GO',''} | Out-File "$SavePath\$DateFolder\$TypeFolder\$ScriptFile.SQL" -Encoding ascii
(Get-Content "$SavePath\$DateFolder\$TypeFolder\$ScriptFile.SQL" -Raw) | Foreach-Object {$_ -replace 'SET ANSI_NULLS OFF
GO',''} | Out-File "$SavePath\$DateFolder\$TypeFolder\$ScriptFile.SQL" -Encoding ascii
(Get-Content "$SavePath\$DateFolder\$TypeFolder\$ScriptFile.SQL" -Raw) | Foreach-Object {$_ -replace 'SET QUOTED_IDENTIFIER ON
GO',''} | Out-File "$SavePath\$DateFolder\$TypeFolder\$ScriptFile.SQL" -Encoding ascii
(Get-Content "$SavePath\$DateFolder\$TypeFolder\$ScriptFile.SQL" -Raw) | Foreach-Object {$_ -replace 'SET QUOTED_IDENTIFIER OFF
GO',''} | Out-File "$SavePath\$DateFolder\$TypeFolder\$ScriptFile.SQL" -Encoding ascii
} #This ends the loop
