<# MONITORING DISK SPACE USAGE
This script will email disk space usage to specified recipient.
#>

<# Configure server and set the critical threshold for disk space. #>
$servername = "localhost"
$criticalthreshold = 10

<# Configure the html content #>
$htmlhead = "<head><title>Disk Space Report</title></head>"
$htmlbody = "<body>"
$htmlbody += "<p>$($subject)</p>"

# Create table headers
$htmlbody += "<table><tbody>"
$htmlbody += "<th>Device ID</th>"
$htmlbody += "<th>Size (GB)</th>"
$htmlbody += "<th>Free Space (GB)</th>"
$htmlbody += "<th>Free Space (%)</th>"

<# Configure table content
Table data is dynamically generated based off extracted disk usage data.
#>
Get-WmiObject -Class Win32_LogicalDisk -ComputerName $servername |
  ForEach-Object { $disk = $_
  $size = "{0:N1}" -f ($disk.Size/1GB)
  $freespace = "{0:N1}" -f ($disk.FreeSpace/1GB)
    if ($disk.Size -gt 0) {
      $freespacepercent = "{0:N1}" -f ($disk.FreeSpace/$disk.Size)
    }
    else {
      $freespacepercent = ""
    }
    if ($freespacepercent -ne "" -and $freespacepercent -lt $criticalthreshold) {
      $htmlbody += "<tr class='critical'>"
    }
    else {
      $htmlbody += "<tr>"
    }
    $htmlbody += "<td>$($disk.DeviceID)</td>"
    $htmlbody += "<td>$($size)</td>"
    $htmlbody += "<td>$($freespace)</td>"
    $htmlbody += "<td>$($freespacepercent)</td>"
    $htmlbody += "</tr>"
  }
$htmlbody += "</tbody></table></body></html>"
# compose full html content
$htmlcontent = $htmlhead + $htmlbody

<# Email settings #>
$currdate = Get-Date -Format "yyyy-MM-dd hhmmtt"
$smtp = "mail.mailserver.local"
$to = "DBA Team<DBATeam@mailserver.local>"
$from = "DBMail<DBMail@mailserver.local>"
$subject = "Disk Space Usage Report for $servername (as of $currdate)"

<# Send the email #>
Send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body "$($htmlcontent)" -BodyAsHtml