<# MONITORING FAILED JOBS
This script will retrieve a list of failed jobs and email
them to a specified recipient.
#>
Import-Module SQLPS
$servername = "localhost"
$server = New-Object "Microsoft.SqlServer.Management.Smo.Server" $servername

<# Retrieve list of jobs that failed and then convert the data to HTML #>
$content = (
  $server.JobServer.Jobs |
    Where-Object LastRunOutcome -EQ "Failed" |
    Select-Object Name, LastRunDate |
    ConvertTo-Html
)

<# Email settings #>
$currdate = Get-Date -Format "yyyy-MM-dd hhmmtt"
$smtp = "mail.mailserver.local"
$to = "DBA Team<DBATeam@mailserver.local>"
$from = "DBMail<DBMail@mailserver.local>"
$subject = "Failed Jobs (as of $currdate)"

<# Send the email #>
Send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body "$($content)" -BodyAsHtml