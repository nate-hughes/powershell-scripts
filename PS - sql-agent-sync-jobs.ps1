<#
   Based on PS script found here:
      How to handle SQL Agent Jobs with Always On Availability Groups?
      https://wisedataman.com/how-to-handle-sql-agent-jobs-with-always-on-availability-groups

   Description: Sync SQL Agent jobs between two SQL Server instances. This script can be used to validate that the jobs are in sync
   or it can synchronize the jobs. If you opt to synchronize, the script will create or update existing jobs. It WILL NOT delete jobs.
 
   Requires SqlServer powershell module:
   Install-Module -Name SqlServer -AllowClobber
#>

$src_sql_server = "source_sql_server"
$tgt_sql_server = "target_sql_server"

# exec = 1 - synchronize the jobs
# exec = 0 - output synchronization status of the jobs
$exec = 0

# include or ignore backup jobs
$include_bak_jobs = 0

# mute in-sync jobs
$mute = 1

$ErrorActionPreference="stop"

Import-Module SqlServer -DisableNameChecking

# get source jobs
If ($include_bak_jobs -eq 1) {
    $src_jobs = (Get-SqlAgentJob -ServerInstance $src_sql_server)
} Else {
    $src_jobs = (Get-SqlAgentJob -ServerInstance $src_sql_server) | Where {$_.name -notlike "BackupDB*"}
}

$src_jobs | ForEach-Object {
    $src_job = $_
    $tgt_job = $null
    $src_script = ""
    $src_job.Script() | ForEach-Object {$src_script += $_}
    $tgt_job = Get-SqlAgentJob -ServerInstance $tgt_sql_server -Name $src_job.Name -ErrorAction Ignore
    
    If ($tgt_job -eq $null) {
        # job does not exist, create it
        If ($exec -eq 0) {
            "Create: " + $src_job.Name
        } ElseIf ($exec -eq 1) {
            "Creating job " + $src_job.Name + " on " + $tgt_sql_server
            Invoke-Sqlcmd -ServerInstance $tgt_sql_server -Query $src_script -DisableVariables -DisableCommands
            $tgt_disable_job = "EXEC msdb.dbo.sp_update_job @job_name=N'" + $src_job.Name + "', @enabled=0;"
            Invoke-Sqlcmd -ServerInstance $tgt_sql_server -Query $tgt_disable_job -DisableVariables -DisableCommands
        }
    } Else {
        # job exists
        $tgt_script = ""
        $tgt_job.Script() | ForEach-Object {$tgt_script += $_}

        # check for exact match
        If ($src_script -eq $tgt_script) {
            If ($mute -eq 0) {
                "OK: " + $src_job.Name
            }
        } Else {
            # check for DateDiff on DateLastModified, if within 5 minutes assume job is in sync
            $ModDiffInMin = ($src_job.DateLastModified - $tgt_job.DateLastModified).Minutes
            If ($ModDiffInMin -gt 5) {
                "Different: " + $src_job.Name

                If ($exec -eq 1) {
                    "Dropping job " + $src_job.Name + " on " + $tgt_sql_server
                    $tgt_job.Drop()
                    "Creating job " + $src_job.Name + " on " + $tgt_sql_server
                    Invoke-Sqlcmd -ServerInstance $tgt_sql_server -Query $src_script -DisableVariables -DisableCommands
                    $tgt_disable_job = "EXEC msdb.dbo.sp_update_job @job_name=N'" + $src_job.Name + "', @enabled=0;"
                    Invoke-Sqlcmd -ServerInstance $tgt_sql_server -Query $tgt_disable_job -DisableVariables -DisableCommands
                }
            }
        }
    }
}

