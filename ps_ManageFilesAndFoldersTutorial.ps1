# Clear the screen
Clear-Host

# Got to your personal temp directory and see what's in it
Set-Location $env:TEMP
Get-ChildItem

<# FILE PROPERTIES #>

# Create a file and verify it's existence
# Test-Path command returns "True" or "False"
Echo text > text.txt
Test-Path text.txt

# Check for any text files in the current directory
Test-Path *.txt

# Get info about specified file
# fl --> display full output of Get-ChildItem command
Get-ChildItem text.txt | fl
(Get-ChildItem text.txt).CreationTime | fl

# Get content of specified file
Get-Content text.txt

# Get filename, file size and contents of specified file
# % --> repeat what comes after it for each item passed to it by the pipe
# $_ --> means the current file
# ; --> separate commands, do what is left of it then do what is right of it in that order
Get-ChildItem text.txt |
  %{$_.Name; $_.Length; Get-Content $_}
# Add labels and formatting for readability
Get-ChildItem text.txt |
  %{"File Name: " + $_.Name; "File Size: " + $_.Length; "Data: " ; Get-Content $_; "-----"} |
  more

<# MOVING & COPYING FILES #>

# Take every file/folder in a directory and then create a folder with the first letter of the
# file/folder name and then move that file into the newly created folder
Get-ChildItem | %{$abc = $_.Name[0]; New-Item -ItemType directory $abc ; Move-Item $_ $abc}
# See organized directory
Get-ChildItem
# See full structure that was created
Get-ChildItem -Recurse
# Put the files/folders back
Get-ChildItem -Recurse | %{Move-Item $_.FullName .}
# Clean up "first letter" folders
Get-ChildItem | Where-Object {$_.Name.Length -eq 1} | Remove-Item

# Organize files by file type
Get-ChildItem | %{$ext = $_.Name.Split(".")[1].ToUpper(); New-Item -ItemType directory $ext; Move-Item $_ $ext}

# Move file
Move-Item C:\Users\nateh\AppData\Local\Temp\XML\*.* C:\Users\nateh\AppData\Local\Temp

#Copy file
Copy-Item tmp14C0.xml C:\Users\nateh\AppData\Local\Temp\XML\tmp14C0.xml

# Create file
New-Item TestKill.txt -ItemType file

# Delete file
Remove-Item TestKill.txt

#Delete everything w/ XML file type within a folder
Get-ChildItem | Where-Object {$_.Name.Split(".")[1] -eq "XML"} | Remove-Item -Force

<# READING FILES #>

# Create a file w/ stuff in it
Get-ChildItem c:\ > list.txt
# Read the file
Get-Content list.txt

# Read the last n lines
$n = 10
Get-Content list.txt | Select-Object -Last $n

# Create a file w/ some repeating lines
("a,b,a,b,a,c,a,d,a,e,a,f,a,g").Split(",") > list2.txt
# Read the file
Get-Content list2.txt
# Filter out duplicate lines
Get-Content list2.txt | Select-Object -Unique
# Filter for lines that start with a given letter
Get-Content list2.txt | Where-Object {$_ -like "a*"}

# Create a file w/ several names in it
("albert,bobby,andrew,billy,alice,carl,ahmed,don,andy,ed,abby,frank,alan,gary").Split(",") > names.txt
# Filter for lines that start with a given letter
Get-Content names.txt | Where-Object {$_ -like "a*"}
# Drop all those names into a new file
Get-Content names.txt | Where-Object {$_ -like "a*"} > A-Names.txt
# Verify contents
Get-Content A-Names.txt
# Drop names in new "letter" files 
Get-Content names.txt | %{$file = $_[0] + "-Names.txt"; echo $_ >> $file }
# Verify contents
Get-Content B-Names.txt

<# RENAMING FILES #>

# Rename file
Rename-Item B-Names.txt BNames.txt
# Verify contents
Get-Content B-Names.txt
Get-Content BNames.txt

# Rename all files ending with TXT
Get-ChildItem *.txt | %{$n = $_.BaseName + ".log"; Rename-Item $_ $n}
# Verify extension change
Get-ChildItem *.log

