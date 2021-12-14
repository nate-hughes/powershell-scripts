$src_sql_server = "source_sql_server"
$tgt_sql_server = "target_sql_server"

# exec = 1 - execute disable/enable
# exec = 0 - output disable/enable scripts
$exec = 0

# include or ignore backup jobs
$include_bak_jobs = 1

# list of DBA jobs to disable/enable
$dba_jobs_array = @(
    "DBA - Audit Table Trim Job"
    ,"DBA - Daily Backup Report"
    ,"DBA - Login Tracker"
    ,"DBA - Wait Stats Tracker"
)

$jobs_query = "
SELECT	name
		,enabled
		,'EXEC msdb.dbo.sp_update_job @job_name=N''' + name + ''', @enabled=' + TRY_CONVERT(CHAR(1),enabled) + ';' as tgt_command
		,'EXEC msdb.dbo.sp_update_job @job_name=N''' + name + ''', @enabled=' + CASE WHEN enabled = 0 THEN '1' ELSE '0' END + ';' as src_command
FROM	msdb.dbo.sysjobs;
"

$src_jobs = Invoke-Sqlcmd -ServerInstance $src_sql_server -Query $jobs_query
$tgt_jobs = Invoke-Sqlcmd -ServerInstance $tgt_sql_server -Query $jobs_query

$src_script = ""
$tgt_script = ""

# sync DBA jobs
$src_jobs | Where {($_.name -like "DBA*") -and ($dba_jobs_array.Contains($_.name))} | Sort name | ForEach {
    $job_name = $_.name
    $src_command = $_.src_command
    $tgt_command = $_.tgt_command
    
    $src_script += "$src_command `r`n"
    
    If ($tgt_jobs | Where {$_.name -eq $job_name}) {
        $tgt_script += "$tgt_command `r`n"
    }
}

# sync backup jobs
# ignores BackupDB_FULL_All_Local_DBs
If ($include_bak_jobs = 1) {
    $src_jobs | Where {($_.name -like "BackupDB*") -and ($_.name -ne "BackupDB_FULL_All_Local_DBs") -and ($_.enabled -eq 1)} | Sort name | ForEach {
        $job_name = $_.name
        $src_command = $_.src_command
        $tgt_command = $_.tgt_command
    
        $src_script += "$src_command `r`n"
    
        If ($tgt_jobs | Where {$_.name -eq $job_name}) {
            $tgt_script += "$tgt_command `r`n"
        }
    }
}

# everything else enabled
$src_jobs | Where {($_.name -notlike "DBA*") -and ($_.name -notlike "BackupDB*") -and ($_.enabled -eq 1)} | Sort name | ForEach {
    $job_name = $_.name
    $src_command = $_.src_command
    $tgt_command = $_.tgt_command
    
    $src_script += "$src_command `r`n"
    
    If ($tgt_jobs | Where {$_.name -eq $job_name}) {
        $tgt_script += "$tgt_command `r`n"
    }
}

# everything else disabled
$src_jobs | Where {($_.name -notlike "DBA*") -and ($_.name -notlike "BackupDB*") -and ($_.enabled -eq 0)} | Sort name | ForEach {
    $job_name = $_.name
    $tgt_command = $_.tgt_command
    
    If ($tgt_jobs | Where {($_.name -eq $job_name) -and ($_.enabled -eq 1)}) {
        $tgt_script += "$tgt_command `r`n"
    }
}

If ($exec -eq 0) {
    $output_script = ":connect $src_sql_server `r`n"
    $output_script += $src_script
    $output_script += "`r`n"
    
    $output_script += ":connect $tgt_sql_server `r`n"
    $output_script += $tgt_script
    $output_script += "`r`n"

    $output_script
} elseif ($exec -eq 1) {
    Invoke-Sqlcmd -ServerInstance $src_sql_server -Query $src_script
    Invoke-Sqlcmd -ServerInstance $tgt_sql_server -Query $tgt_script
}
