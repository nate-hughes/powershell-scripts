Function SyncSQLAgentJobs {
Param(
    [Parameter(mandatory=$true)] 
    [string]$ServerA, 
    [Parameter(mandatory=$true)] 
    [string]$ServerB, 
    [Parameter(mandatory=$false)] 
    [System.Array]$ExcludedCategories=@(), #Job categories to exclude from the synchronization process.
    [Parameter(mandatory=$false)] 
    [System.Array]$IncludedCategories=@(), #Job categories to include in the synchronization process.
    [Parameter(mandatory=$false)] 
    [switch]$DoSync #perform a two way synchronization if specified, otherwise run in reporting mode.
)
<# Created: 2017-12-06
   Author:  David Wiseman
  
   Description: Sync agent jobs between two SQL Server instances or check synchronization status.  This is useful if you are using a high availability technology like
   availability groups, log shipping or database mirroring that does not include SQL Agent jobs in the failover.  The script can be used to validate that the jobs are in sync
   or it can synchronize the jobs.  

   Requires SqlServer powershell module:
   Install-Module -Name SqlServer -AllowClobber

   Example1: 
   ./SyncSQLAgentJobs -ServerA "SERVER1" -ServerB "SERVER2"
   Agent jobs will be checked and differences will be reported. 
   
   Example2: 
   ./SyncSQLAgentJobs -ServerA "SERVER1" -ServerB "SERVER2" -DoSync
   Any jobs that don't exist will be copied from SERVER1 to SERVER2 and from SERVER2 to SERVER1.  Any jobs that are different will be copied from the server with the newer version of the job (Based on DateLastModified).  

   Example3: 
   ./SyncSQLAgentJobs -ServerA "SERVER1" -ServerB "SERVER2" -DoSync ExcludedCategories "ADHOC"
   Same as example 2 but jobs in the category "ADHOC" are excluded from synchronization.

   Note: SQL Agent loads SQLPS which isn't compatible with SqlServer module.  A workaround is to run the following powershell in the SQL Agent job.
    $Error.Clear()
    $out = powershell  -NoProfile -Command "C:\Scripts\SyncSQLAgentJobs.ps1" -ServerA "SERVER1" -ServerB "SERVER2"
    if ($Error.Count -gt 0){
    throw $out
    }
    else{
    $out
    }
   This will ensure the job fails if anything is out of sync.  The SQL Server agent account will need appropriate access to msdb database on both instances.

#>
$ErrorActionPreference="stop"
Import-Module SqlServer -DisableNameChecking

$IncludedCategories

$jobs = Get-SqlAgentJob -ServerInstance $ServerA | Where {$_.Name -ne "DBA - Enable SQL Agent jobs post-Failover"}
$ValidationStatus=$true
$errorMsg=""

$jobs | ForEach-Object{
    $jobA = $_
    $jobB = $null
    $scriptA = ""
    $jobA.Script() | ForEach-Object {$scriptA += $_}
    $jobB = Get-SqlAgentJob -ServerInstance $ServerB -Name $jobA.Name -ErrorAction Ignore

    if ($ExcludedCategories.Contains($jobA.Category)){
        "Skipping " + $ServerA + ": " + $jobA.Name + " : Excluded category: " + $jobA.Category
    }
    elseif($jobB -ne $null -and $ExcludedCategories.Contains($jobB.Category)){
        "Skipping " + $ServerB + ": " + $jobB.Name + " : Excluded category: " + $jobB.Category
    }
    elseif($jobA -ne $null -and $IncludedCategories.Count -gt 0 -and (!$IncludedCategories.Contains($jobA.Category))){
        "Skipping " + $ServerA + ": " + $jobA.Name + " : Not included category: " + $jobA.Category
    }
    elseif($jobB -ne $null -and $IncludedCategories.Count -gt 0 -and (!$IncludedCategories.Contains($jobB.Category))){
        "Skipping " + $ServerB + ": " + $jobB.Name + " : Not included category: " + $jobB.Category
    }
    elseif ($jobB -eq $null){
        $ErrorMsg += "Missing on " + $ServerB + ":" + $jobA.Name + "`n"
        "Missing on " + $ServerB + ":" + $jobA.Name
        $ValidationStatus=$false
        if ($DoSync){
            "Creating job " + $jobA.Name + " on " + $ServerB
             Invoke-Sqlcmd -ServerInstance $ServerB -Query $scriptA -DisableVariables -DisableCommands
        }
    }
        else {
       
        $scriptB = ""
        $jobB.Script() | ForEach-Object {$scriptB += $_}
    
        if ($scriptA -ne $scriptB){
            if ($jobA.DateLastModified -gt $jobB.DateLastModified){
                $ErrorMsg += "Different (Newer on $ServerA): " + $_.Name + "`n"
                "Different (Newer on $ServerA): " + $_.Name
                $ValidationStatus=$false
                if ($DoSync){
                    "Dropping job " + $jobB.Name + " on " + $ServerB
                     $JobB.Drop()
                     "Creating job " + $jobB.Name + " on " + $ServerB
                     Invoke-Sqlcmd -ServerInstance $ServerB -Query $scriptA -DisableVariables -DisableCommands
                }
            }
        }
    }
}
<#
 $missingA = Get-SqlAgentJob -ServerInstance $ServerB | Where-Object {@(Get-SqlAgentJob -ServerInstance $ServerA -Name $_.Name -ErrorAction Ignore).Count -eq 0}
 $missingA | ForEach-Object{
     $jobB = $_
     if ($ExcludedCategories.Contains($jobB.Category)){
        "Skipping " + $ServerB + ": " + $jobB.Name + " : Excluded category: " + $jobB.Category
     }
     else{
         $ErrorMsg += "Missing on " + $ServerA + ":" + $jobB.Name + "`n"
         "Missing on " + $ServerA + ":" + $jobB.Name 
         $ValidationStatus=$false
         if ($DoSync){
                $scriptB = ""
                $jobB.Script() | ForEach-Object {$scriptB += $_}
                "Creating job " + $jobB.Name + " on " + $ServerA
                 Invoke-Sqlcmd -ServerInstance $ServerA -Query $scriptB -DisableVariables -DisableCommands

         }
     }
 }
 if ($ValidationStatus -eq $false -and $DoSync -eq $false){
    $errorMsg = "SQL Agent jobs require synchronization`n" + $errorMsg
    throw $errorMsg
 }
 #>
 }

 # Agent jobs will be checked and differences will be reported. 
SyncSQLAgentJobs -ServerA "PRDEGGDBS02.mf.dou" -ServerB "PRDEGGDBS03.mf.dou"

   