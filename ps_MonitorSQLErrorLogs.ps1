<# MONITORING LOGS
This script will retrieve the last 15 error entries from the SQL Server
error log, convert the returned data to HTML and email the data to a
specified recipient.
#>
Import-Module SQLPS
$servername = "localhost"
$server = New-Object "Microsoft.SqlServer.Management.Smo.Server" $servername

<# Retrieve last 15 error entries and convert the data to HTML #>
$content = (
  $server.ReadErrorLog() |
    Where-Object {$_.Text -like "*failed*" -or $_.Text -like "*error*" -or $_.HasErrors -eq $true} |
    Select-Object LogDate, ProcessInfo, Text, HasErrors -Last 15 |
    ConvertTo-Html
)

<# Email settings #>
$currdate = Get-Date -Format "yyyy-MM-dd hhmmtt"
$smtp = "mail.mailserver.local"
$to = "DBA Team<DBATeam@mailserver.local>"
$from = "DBMail<DBMail@mailserver.local>"
$subject = "Most Current 15 Errors/Failures (as of $currdate)"

<# Send the email #>
Send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body "$($content)" -BodyAsHtml

