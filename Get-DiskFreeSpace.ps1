param (
    $computername = 'localhost'
    ,$drivetype = 3 # fixed disk
)
Get-WmiObject -class Win32_LogicalDisk -computername $computername -filter "drivetype=$drivetype" |
Sort-Object -property DeviceID |
Format-Table -property DeviceID,
                 @{l='FreeSpace(MB)';e={$_.FreeSpace / 1MB -as [int]}},
                 @{l='Size(GB)';e={$_.Size / 1GB -as [int]}},
                 @{l='PctFree';e={$_.FreeSpace / $_.Size * 100 -as [int]}}
