
#Import-Module SqlServer
#Remove-Module SqlServer

$search = "rogers"

<#
#Run to create encrypted password file(s).
$credential = Get-Credential
$credential.Password | ConvertFrom-SecureString | Set-Content D:\CredStore\uat-nservicebus.txt
#>

$sqlserver_array = @(
    [pscustomobject]@{name="PRDEGGDBS01";hostname="PRDEGGDBS01.mf.dou"}
    [pscustomobject]@{name="PRDEGGDBS02";hostname="PRDEGGDBS02.mf.dou"}
    [pscustomobject]@{name="PRDEGGDBS03";hostname="PRDEGGDBS03.mf.dou"}
    [pscustomobject]@{name="PRDEGGSSIS01";hostname="PRDEGGSSIS01.mf.dou"}
    [pscustomobject]@{name="UATSQL1";hostname="UATSQL1.mf.dou"}
    [pscustomobject]@{name="SBXSQL1";hostname="SBXSQL1.mf.dou"}

    [pscustomobject]@{name="prd-nservicebus";hostname="nservicebus-mint-adder.cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-nservicebus";hostname="uat-nservicebus-social-stinkbug.cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-nservicebus";hostname="sbx-nservicebus-obliging-bobcat.cweluei2okuj.us-east-1.rds.amazonaws.com"}
)

$username = "nate.hughes"
$encrypted_password = Get-Content C:\CredStore\prd.txt | ConvertTo-SecureString
$prd_nservicebus_credential = New-Object System.Management.Automation.PsCredential($username, $encrypted_password)
$encrypted_password = Get-Content C:\CredStore\uat.txt | ConvertTo-SecureString
$uat_nservicebus_credential = New-Object System.Management.Automation.PsCredential($username, $encrypted_password)

# Check for Logins
$sqlserver_array | Where {$_.name -NotLike "*nservicebus"} | ForEach {
    $sqlserver = $_.hostname
    $sqlname = $_.name
    Get-SqlLogin -ServerInstance $sqlserver -LoginName "\b*$search.*" -RegEx -ErrorAction SilentlyContinue | Select -Property @{Name = "Server"; Expression = {$sqlname}}, Name, LoginType, @{Name = "Disable"; Expression = {"ALTER LOGIN [" + $_.Name + "] DISABLE;"}}
}
$sqlserver_array | Where {$_.name -like "*nservicebus"} | ForEach {
    $sqlserver = $_.hostname
    $sqlname = $_.name
    If ($sqlname -eq "prd-nservicebus") {
        Get-SqlLogin -Credential $prd_nservicebus_credential -ServerInstance $sqlserver -LoginName "\b*$search.*" -RegEx -ErrorAction SilentlyContinue | Select -Property @{Name = "Server"; Expression = {$sqlname}}, Name, LoginType, @{Name = "Disable"; Expression = {"ALTER LOGIN [" + $_.Name + "] DISABLE;"}}
    } Else {
        Get-SqlLogin -Credential $uat_nservicebus_credential -ServerInstance $sqlserver -LoginName "\b*$search.*" -RegEx -ErrorAction SilentlyContinue | Select -Property @{Name = "Server"; Expression = {$sqlname}}, Name, LoginType, @{Name = "Disable"; Expression = {"ALTER LOGIN [" + $_.Name + "] DISABLE;"}}
    }
}

<#
# Collect Editions and Versions
$sqlserver_array | Where {$_.name -NotLike "*nservicebus"} | ForEach {
    $sqlserver = $_.hostname
    $sqlname = $_.name
    $sqlinstance += Get-SqlInstance -ServerInstance $sqlserver | Select -Property @{Name = "Server"; Expression = {$sqlname}}, Edition, VersionString, ProductLevel, ProductUpdateLevel
}
$sqlserver_array | Where {$_.name -like "*nservicebus"} | ForEach {
    $sqlserver = $_.hostname
    $sqlname = $_.name
    If ($sqlname -eq "prd-nservicebus") {
        $sqlinstance += Get-SqlInstance -Credential $prd_nservicebus_credential -ServerInstance $sqlserver | Select -Property @{Name = "Server"; Expression = {$sqlname}}, Edition, VersionString, ProductLevel, ProductUpdateLevel
    } Else {
        $sqlinstance += Get-SqlInstance -Credential $uat_nservicebus_credential -ServerInstance $sqlserver | Select -Property @{Name = "Server"; Expression = {$sqlname}}, Edition, VersionString, ProductLevel, ProductUpdateLevel
    }
}
$sqlinstance | Select Server, Edition, VersionString, ProductLevel, ProductUpdateLevel | Format-Table
$sqlinstance.Clear()
#>
