#run from cmdline
#C:\Users\nateh\Projects\powershell-scripts\ps_Concatenate-Scripts.ps1 "D:\SourceSafe\push\Oct 19\FN" "D:\SourceSafe\push\Oct 19\FN.sql"

param(
 [string]$inpath,
 [string]$outpath
)

$PathArray = @()

#List file names for all files not containing pattern: "USE "
Get-ChildItem -path $inpath | ? {$_.PSIsContainer -eq $false} | ? {gc $_.pspath | select-string -pattern "USE "}

#Get-ChildItem -path $inpath -recurse |?{ ! $_.PSIsContainer } |?{($_.name).contains(".sql")} | %{ Out-File -filepath $outpath -inputobject (get-content $_.fullname) -Append}
Get-ChildItem -path $inpath |?{ ! $_.PSIsContainer } | %{ Out-File -filepath $outpath -inputobject (get-content $_.fullname) -Append}

#Remove ANSI_NULLS and QUOTED_IDENTIFIER overrides so they do not affect other scripts
(Get-Content $outpath) | Foreach-Object {$_ -replace 'SET ANSI_NULLS ON',''} | Out-File $outpath
(Get-Content $outpath) | Foreach-Object {$_ -replace 'SET ANSI_NULLS OFF',''} | Out-File $outpath
(Get-Content $outpath) | Foreach-Object {$_ -replace 'SET QUOTED_IDENTIFIER ON',''} | Out-File $outpath
(Get-Content $outpath) | Foreach-Object {$_ -replace 'SET QUOTED_IDENTIFIER OFF',''} | Out-File $outpath
