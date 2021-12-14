# ISE
$Path = "C:\Program*"
$File = "DTSWizard.exe"
dir -Path $Path -Filter $File -Recurse -ErrorAction SilentlyContinue | %{$_.FullName}

# CMD
powershell "dir -Path C:\Program* -Filter DTSWizard.exe -Recurse -ErrorAction SilentlyContinue | %{$_.FullName}"
