<# Ch 2. Running commands #>
# 1.  Create a text file that contains the names of the files and folders in C:\Windows (don’t worry about including subdirectories—that would take too long). Name the text file MyDir.txt.
dir "C:\Windows" > C:\Temp\MyDir.txt
# 2.  Display the contents of that text file.
get-content C:\Temp\MyDir.txt
# 3.  Rename the file from MyDir.txt to WindowsDir.txt.
ren C:\Temp\MyDir.txt WindowsDir.txt
# 4.  Create a new folder named LabOutput—you can either do this in your Documents folder, or in the root of your C: drive.
mkdir C:\Temp\LabOutput
# 5.  Copy WindowsDir.txt into the LabOutput folder.
copy C:\Temp\WindowsDir.txt C:\Temp\LabOutput
# 6.  Delete the original copy of WindowsDir.txt—not the copy that you just made in LabOutput.
del C:\Temp\WindowsDir.txt
# 7.  Display a list of running processes.
get-process
# 8.  Redirect a list of running processes into a file named Procs.txt.
get-process > C:\Temp\Procs.txt
# 9.  Move Procs.txt into the LabOutput folder if it isn’t in there already.
move-item C:\Temp\Procs.txt C:\Temp\LabOutput
# 10.  Display the contents of Procs.txt so that only one page displays at a time (remember the trick with | more).
get-content C:\Temp\LabOutput\Procs.txt | more


<# Ch 3. Using the help system #>
help *content* 
help get-content
help get-content -Full
help get-content -Examples
help get-content -Online
help about*
help about_CommonParameters

get-command -Noun *content*
get-command *content* -CommandType Cmdlet

# 1.  Can you find any cmdlets capable of converting other cmdlets’ output into HTML?
get-command -Noun HTML
# 2.  Are there any cmdlets that can redirect output into a file, or to a printer?
get-command -Noun file,printer
# 3.  How many cmdlets are available for working with processes? (Hint: Remember that cmdlets all use a singular noun.)
get-command -Noun process
# 4.  What cmdlet might you use to write to an event log?
get-command -Verb write -Noun EventLog
# 5.  You’ve learned that aliases are nicknames for cmdlets; what cmdlets are available to create, modify, export, or import aliases?
get-command -Noun Alias
# 6.  Is there a way to keep a transcript of everything you type in the shell, and save that transcript to a text file?
get-command -Noun transcript
# 7.  It can take a long time to retrieve all of the entries from the Security event log. How can you get just the 100 most recent entries?
get-command -Verb get -Noun EventLog
help get-eventlog -Parameter Newest 
# 8.  Is there a way to retrieve a list of the services that are installed on a remote computer?
get-command -Verb get -Noun service
help get-service -Parameter computername
# 9.  Is there a way to see what processes are running on a remote computer?
help Get-Process -Parameter computername
# 10.  Examine the help file for the Out-File cmdlet. The files created by this cmdlet default to a width of how many characters? Is there a parameter that would enable you to change that width?
help out-file -Parameter width
# 11.  By default, Out-File will overwrite any existing file that has the same filename as what you specify. Is there a parameter that would prevent the cmdlet from overwriting an existing file?
help out-file -Parameter noclobber
# 12.  How could you see a list of all aliases defined in PowerShell?
help about_Aliases
get-alias
# 13.  Using both an alias and abbreviated parameter names, what is the shortest command line you could type to retrieve a list of running processes from a computer named Server1?
gps -cn Server1
ps -c Server1
# 14.  How many cmdlets are available that can deal with generic objects? (Hint: Remember to use a singular noun like “object” rather than a plural one like “objects”).
get-command -Noun object
# 15.  This chapter briefly mentioned arrays. What help topic could tell you more about them?
help about*
help about_arrays


<# Ch 4. The pipeline: connecting commands #>
Get-Process | Export-Csv C:\Temp\LabOutput\Procs.csv
Import-Csv C:\Temp\LabOutput\Procs.csv
Get-Process | Export-Clixml C:\Temp\LabOutput\Procs.xml
Import-Clixml C:\Temp\LabOutput\Procs.xml
help diff
diff -ReferenceObject (Import-Clixml C:\Temp\LabOutput\Procs.xml) -DifferenceObject (ps) -Property Name
get-service | Out-GridView
get-service | ConvertTo-Html | Out-File C:\Temp\LabOutput\Services.htm
$ConfirmPreference

# 1.  Create a CliXML reference file for the services on your computer. Then, change the status of some non-essential service like BITS (stop it if it’s already started; start it if it’s stopped on your computer). Finally, use Diff to compare the reference CliXML file to the current state of your computer’s services. You’ll need to specify more than the Name property for the comparison—does the -property parameter of Diff accept multiple values? How would you specify those multiple values?
Get-Service | Export-Clixml C:\Temp\LabOutput\Services.xml
help diff
diff -ReferenceObject (Import-Clixml C:\Temp\LabOutput\Services.xml) -DifferenceObject (get-service) -Property Status,Name
# 2.  Create two similar, but different, text files. Try comparing them using Diff. To do so, run something like this: Diffreference (Get-Content File1.txt)-difference (Get-Content File2.txt). If the files have only one line of text that’s different, the command should work. If you add a bunch of lines to one file, the command may stop working. Try experimenting with the Diff command’s -syncWindow parameter to see if you can get the command working again.
diff -ReferenceObject (C:\Temp\LabOutput\Procs.txt) -DifferenceObject (C:\Temp\LabOutput\WindowsDir.txt)
# 3.  What happens if you run Get-Service | Export-CSV services.csv | Out-File from the console? Why does that happen?
Get-Service | Export-CSV services.csv | Out-File <#ERR: Export-CSV : Access to the path 'C:\WINDOWS\system32\services.csv' is denied.#>
# 4.  Apart from getting one or more services and piping them to Stop-Service, what other means does Stop-Service provide for you to specify the service or services you want to stop? Is it possible to stop a service without using Get-Service at all?
help stop-service -Parameter DisplayName
# 5.  What if you wanted to create a pipe-delimited file instead of a comma-separated file? You would still use the Export-CSV command, but what parameters would you specify?
help Export-Csv -Parameter Delimiter
# 6.  Is there a way to eliminate the # comment line from the top of an exported CSV file? That line normally contains type information, but what if you wanted to omit that from a particular file?
help Export-Csv -Parameter NoTypeInformation
# 7.  Export-CliXML and Export-CSV both modify the system, because they can create and overwrite files. What parameter would prevent them from overwriting an existing file? What parameter would ask you if you were sure before proceeding to write the output file?
help Export-Csv -Parameter NoClobber
help Export-Csv -Parameter Confirm
# 8.  Windows maintains several regional settings, which include a default list separator. On U.S. systems, that separator is a comma. How can you tell Export-CSV to use the system’s default separator, rather than a comma?
help Export-Csv -Parameter UseCulture


<# Ch 5. Adding commands #>
Get-PSSnapin -Registered
get-content env:psmodulepath
dir "C:\Program Files (x86)\Microsoft SQL Server\150\Tools\PowerShell\Modules\"
Get-Module -ListAvailable
Import-Module -Name ServerManager
Remove-Module -Name ServerManager


<# Ch. 6 Objects: just data by another name #>
Get-Process | Get-Member
Get-Process | Sort-Object -property CPU,Id -Descending
Get-Process | Select-Object -property Name,ID,VM,PM | ConvertTo-Html | Out-File C:\Temp\LabOutput\test2.html

Get-Process |
Sort-Object VM -descending |
Select-Object Name,ID,VM

Get-Process | Sort VM -descending | Select Name,ID,VM | gm

# 1.  Identify a cmdlet that will produce a random number.
get-command -Noun random
get-random
# 2.  Identify a cmdlet that will display the current date and time.
get-command -Noun date -Verb get
get-date
# 3.  What type of object does the cmdlet from task #2 produce? (What is the type name of the object produced by the cmdlet?)
get-date | get-member #TypeName: System.DateTime
# 4.  Using the cmdlet from task #2 and Select-Object, display only the current day of the week in a table like this:
# DayOfWeek
# ---------
# Monday
get-date | Select-Object -Property DayOfWeek
# 5.  Identify a cmdlet that will display information about installed hotfixes.
get-command -Noun hotfix
help Get-HotFix
# 6.  Using the cmdlet from task #5, display a list of installed hotfixes. Sort the list by the installation date, and display only the installation date, the user who installed the hotfix, and the hotfix ID.
Get-HotFix | gm
Get-HotFix | Sort InstallDate | Select InstallDate, InstalledBy, HotFixID
# 7.  Repeat task #6, but this time sort the results by the hotfix description, and include the description, the hotfix ID, and the installation date. Put the results into an HTML file.
Get-HotFix | Sort Description | Select Description, HotFixID, InstallDate | ConvertTo-Html | Out-File C:\Temp\LabOutput\HotFixes.html
# 8.  Display a list of the 50 newest entries from the Security event log (you can use a different log, such as System or Application, if your Security log is empty). Sort the list so that the oldest entries appear first, and so that entries made at the same time are sorted by their index. Display the index, time, and source for each entry. Put this information into a text file (not an HTML file, just a plain text file).
help get-eventlog
get-eventlog application | gm
get-eventlog application -Newest 50 | Sort TimeWritten, Index | Select Index, TimeWritten, Source | Out-File C:\Temp\LabOutput\AppLog.txt


<# Ch. 8 Formatting—and why it’s done on the right #>
help Format-Table
Get-WmiObject Win32_BIOS | Format-Table -autoSize
Get-Process | Format-Table -property ID,Name,Responding -autoSize
Get-Service | Sort-Object Status | Format-Table -groupBy Status
Get-Service | Format-Table Name,Status,DisplayName -autoSize -wrap

help Format-List -Examples
Get-Service | Format-List

help Format-Wide
Get-Process | Format-Wide name -Column 4

#provide a column header that’s different from the property name
Get-Service | Format-Table @{l='ServiceName';e={$_.Name}},Status,DisplayName
#put a mathematical expression in place
Get-Process | Format-Table Name, @{l='VM(MB)';e={$_.VM / 1MB -as [int]}} -autosize

# 1.  Display a table of processes that includes only the process names, IDs, and whether or not they’re responding to Windows (the Responding property has that information). Have the table take up as little horizontal room as possible, but don’t allow any information to be truncated.
Get-Process | Select-Object -Property ProcessName,Id,Responding | Format-Table -AutoSize -Wrap
# 2.  Display a table of processes that includes the process names and IDs. Also include columns for virtual and physical memory usage, expressing those values in megabytes (MB).
Get-Process | Select-Object -Property ProcessName,Id,@{l='VM(MB)';e={$_.VM / 1MB -as [int]}},@{l='PM(MB)';e={$_.PM / 1MB -as [int]}} -First 10 | Format-Table -AutoSize
# 3.  Use Get-EventLog to display a list of available event logs. (Hint: You’ll need to read the help to learn the correct parameter to accomplish that.) Format the output as a table that includes, in this order, the log display name and the retention period. The column headers must be “LogName” and “RetDays.”
Get-EventLog -List | Select @{l="LogName";e={$_.Log}},@{l="RetDays";e={$_.Retain}} | Format-Table -AutoSize
# 4.  Display a list of services so that a separate table is displayed for services that are started and services that are stopped. Services that are started should be displayed first. (Hint: You’ll use a -groupBy parameter).
Get-Service | Select -Property Status,@{l='Service';e={$_.Name}} | Sort @{Expression="Status";Descending=$true},Service | Format-Table -GroupBy Status


<# Ch. 9 Filtering and comparisons #>
Get-Service -Name e*,*s*
Get-Service | Where-Object -filter { $_.Status -eq 'Running' }
Get-Process | Where-Object -filter { $_.Name -notlike 'powershell*' } | Sort VM -Descending | Select -First 10 | Measure-Object -Property VM -Sum

# 1.  Import the ServerManager module in Windows Server 2008 R2. Using the Get-WindowsFeature cmdlet, display a list of server roles and features that are currently installed.
Import-Module ServerManager
Get-WindowsFeature | Where {$_.InstallState -eq "Installed"}
# 2.  Import the ActiveDirectory module in Windows Server 2008 R2. Using the Get-ADUser cmdlet, display a list of users whose -First property is equal to the special value $null. (Hint: This property isn’t retrieved from the directory by default. You’ll have to specify a parameter that forces this property to be retrieved if you want to look at it). Your final list should include only the user name of the users who meet this criterion. This is a tricky task, because getting $null into the filter criteria for the cmdlet’s own -filter parameter may not be possible.
Import-Module ActiveDirectory
help get-aduser -Full
Get-ADUser -Filter * -Properties PasswordLastSet | Where {$_.PasswordLastSet -eq $null} | Select -Property UserPrincipalName
# 3.  Display a list of hotfixes that are security updates.

# 4.  Using Get-Service, is it possible to display a list of services that have a start type of Automatic, but that aren’t currently started?

# 5.  Display a list of hotfixes that were installed by the Administrator, and which are updates.

# 6.  Display a list of all processes running as either Conhost or Svchost.


