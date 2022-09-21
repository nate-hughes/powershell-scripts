$Report = @()
foreach($Path in (Get-Disk).Path) {
    $DiskId = (Get-Partition -DiskId $Path).DiskId
    $Disk = (Get-Disk -Path $Path).Number
    $EbsVolumeId = GetEBSVolumeId($Path)
    $SizeGB = ((Get-Disk -Path $Path).Size / 1GB)
    # GetDriveLetter
    if($Disk -eq 0){
        $VirtualDevice = "root"
        $DriveLetter = "C"
    } else {
        $VirtualDevice = "N/A"
        $DriveLetter = (Get-Partition -DiskNumber $Disk -ErrorAction SilentlyContinue).DriveLetter
        if(!$DriveLetter) {
            $DriveLetter = ((Get-Partition -DiskId $Path -ErrorAction SilentlyContinue).AccessPaths).Split(",")[0]
        } 
    }
    # GetDeviceName
    if($EbsVolumeId -clike 'vol*') {
        $Device  = ((Get-EC2Volume -VolumeId $EbsVolumeId).Attachment).Device
        $VolumeName = (Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue).FileSystemLabel
    }
    $Disk = New-Object PSObject -Property @{
      Disk          = $Disk
      DriveLetter   = $DriveLetter
      EbsVolumeId   = $EbsVolumeId 
      Device        = $Device 
      VirtualDevice = $VirtualDevice 
      VolumeName    = $VolumeName
      SizeGB        = $SizeGB
    }
	$Report += $Disk
}
$Report | Sort-Object Disk | Format-Table -AutoSize -Property Disk, Partitions, DriveLetter, EbsVolumeId, Device, VirtualDevice, VolumeName, SizeGB
