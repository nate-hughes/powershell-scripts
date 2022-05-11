
#Import-Module SqlServer
#Remove-Module SqlServer

$search = "singari"

<#
#Run to create encrypted password file(s).
$credential = Get-Credential
$credential.Password | ConvertFrom-SecureString | Set-Content D:\CredStore\uat-nservicebus.txt
#>

$sqlserver_array = @(
    [pscustomobject]@{name="PRDAG1";hostname="PRDAG1.mf.dou"}
    [pscustomobject]@{name="PRDAG2";hostname="PRDAG2.mf.dou"}
    [pscustomobject]@{name="PRDEGGDBS03";hostname="PRDEGGDBS03.mf.dou"}
    [pscustomobject]@{name="PRDEGGSSIS01";hostname="PRDEGGSSIS01.mf.dou"}
    [pscustomobject]@{name="UATSQL1";hostname="UATSQL1.mf.dou"}
    [pscustomobject]@{name="STGEGGDBS01";hostname="STGEGGDBS01.mf.dou"}
    [pscustomobject]@{name="STGEGGDBS02";hostname="STGEGGDBS02.mf.dou"}
    [pscustomobject]@{name="STGEGGDBS03";hostname="STGEGGDBS03.mf.dou"}
    [pscustomobject]@{name="prd-ephesoft";hostname="prd-ephesoft.cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-ephesoft";hostname="uat-ephesoft.cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-carbon-black-app-control";hostname="prd-carbon-black-app-control.cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}

    [pscustomobject]@{name="prd-nservicebus";hostname="nservicebus-mint-adder.cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-nservicebus";hostname="uat-nservicebus-social-stinkbug.cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="stg-nservicebus";hostname="stg-nservicebus-model-sawfly.cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-nservicebus";hostname="sbx-nservicebus-obliging-bobcat.cweluei2okuj.us-east-1.rds.amazonaws.com"}
)

$username = "mfadmin"
$encrypted_password = Get-Content D:\CredStore\prd-nservicebus.txt | ConvertTo-SecureString
$prd_nservicebus_credential = New-Object System.Management.Automation.PsCredential($username, $encrypted_password)
$encrypted_password = Get-Content D:\CredStore\uat-nservicebus.txt | ConvertTo-SecureString
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
