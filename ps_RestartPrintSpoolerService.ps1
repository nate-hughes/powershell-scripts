Stop-Service -Name Spooler -Force

Remove-Item -Path C:\WINDOWS\System32\spool\PRINTERS\*.*

Start-Service -Name Spooler
