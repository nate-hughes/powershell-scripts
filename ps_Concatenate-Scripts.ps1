#run from cmdline
#D:\GIT\Projects\powershell-scripts\ps_Concatenate-Scripts.ps1 "D:\SourceSafe\push\Prod_Release\DDL" "D:\SourceSafe\push\Prod_Release\1_DDL.sql"

param(
 [string]$inpath,
 [string]$outpath
)

$PathArray = @()

#List file names for all files not containing pattern: "USE "
Get-ChildItem -path $inpath | ? {$_.PSIsContainer -eq $false} | ? {gc $_.pspath | select-string -pattern "USE "}

#Loop through source directory and append file contents to main script
Get-ChildItem -path $inpath |?{ ! $_.PSIsContainer } | %{ Out-File -filepath $outpath -inputobject (get-content $_.fullname) -Append}

#Remove ANSI_NULLS and QUOTED_IDENTIFIER overrides so they do not affect other scripts
(Get-Content $outpath) | Foreach-Object {$_ -replace 'SET ANSI_NULLS ON',''} | Out-File $outpath
(Get-Content $outpath) | Foreach-Object {$_ -replace 'SET ANSI_NULLS OFF',''} | Out-File $outpath
(Get-Content $outpath) | Foreach-Object {$_ -replace 'SET QUOTED_IDENTIFIER ON',''} | Out-File $outpath
(Get-Content $outpath) | Foreach-Object {$_ -replace 'SET QUOTED_IDENTIFIER OFF',''} | Out-File $outpath
(Get-Content $outpath) | Foreach-Object {$_ -replace 'SET XACT_ABORT OFF',''} | Out-File $outpath
