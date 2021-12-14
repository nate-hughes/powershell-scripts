<#
PowerShell and Performance Monitor (Perfmon) Counter
https://www.travisgan.com/2013/03/powershell-and-performance-monitor.html

Get-Counter -ListSet * |
  Sort-Object -Property CounterSetName |
    Format-Table CounterSetName, CounterSetType -AutoSize

Get-Counter -ListSet "*disk*"

#>

$counters = @(
    "\Processor(_total)\% Processor Time"
    ,"\Process(sqlservr)\% Processor Time"
    ,"\System\Processor Queue Length"
    ,"\Memory\Available MBytes"
    ,"\Paging File(_Total)\% Usage"
    ,"\SQLServer:Memory Manager\Memory Grants Pending"
    ,"\SQLServer:Buffer Manager\Lazy writes/sec"
    ,"\SQLServer:Buffer Manager\Page Life Expectancy"
    ,"\SQLServer:Buffer Manager\Page reads/sec"
    ,"\SQLServer:Buffer Manager\Page writes/sec"
    ,"\SQLServer:Memory Manager\Total Server Memory (KB)"
    ,"\SQLServer:Memory Manager\Target Server Memory (KB)"
    ,"\PhysicalDisk(*)\Avg. Disk sec/Read"
    ,"\PhysicalDisk(*)\Avg. Disk sec/Write"
    ,"\PhysicalDisk(*)\Disk Reads/sec"
    ,"\PhysicalDisk(*)\Disk Writes/sec"
    ,"\SQLServer:Access Methods\Forwarded Records/sec"
    ,"\SQLServer:Access Methods\Full Scans/sec"
    ,"\SQLServer:Access Methods\Index Searches/sec"
    ,"\SQLServer:Access Methods\Page Splits/sec"
    ,"\SQLServer:General Statistics\User Connections"
    ,"\SQLServer:SQL Statistics\Batch Requests/sec"
    ,"\SQLServer:SQL Statistics\SQL Compilations/sec"
    ,"\SQLServer:SQL Statistics\SQL Re-Compilations/sec"
)

$collections = Get-Counter -ComputerName localhost -Counter $counters -SampleInterval 1 -MaxSamples 1

$sampling = $collections.CounterSamples | Select-Object -Property TimeStamp, Path, Cookedvalue
$xmlString = $sampling | ConvertTo-Xml -As String

$query = "dbo.usp_InsertPerfmonCounter '$xmlString';"
Invoke-Sqlcmd -ServerInstance localhost -Database db_monitor -Query $query
