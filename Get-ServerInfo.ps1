function Get-ServerInfo {
    param (
        [string]$computername = 'localhost'
    )

    $os = Get-WmiObject Win32_OperatingSystem -computer $computername |
     Select @{l='ComputerName';e={$_.__SERVER}},BuildNumber,ServicePackMajorVersion

    $disk = Get-WmiObject Win32_LogicalDisk -filter "DeviceID='C:'" -computer $computername |
     Select @{l='SysDriveFree';e={$_.FreeSpace / 1MB -as [int]}}
    
    $obj = New-Object -TypeName PSObject
    $obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $computername
    $obj | Add-Member -MemberType NoteProperty -Name BuildNumber -Value ($os.BuildNumber)
    $obj | Add-Member -MemberType NoteProperty -Name SPVersion -Value ($os.servicepackmajorversion)
    $obj | Add-Member -MemberType NoteProperty -Name FreeSpace -Value ($disk.sysdrivefree)

    Write-Output $obj
}

Get-ServerInfo | Format-Table -AutoSize