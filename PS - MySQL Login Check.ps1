
#Import-Module SimplySql
#Remove-Module SimplySql

<#
#Run to create encrypted password file(s).
$credential = Get-Credential
$credential.Password | ConvertFrom-SecureString | Set-Content D:\CredStore\sbx.txt
#>

$search = "v-"

$mysql_array = @(
    [pscustomobject]@{name="sbx-agent-desk";hostname="sbx-agent-desk.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-auth-identity-service";hostname="sbx-auth-identity-service.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-card";hostname="sbx-card.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-collections";hostname="sbx-collections.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-comm";hostname="sbx-comm.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-csw";hostname="sbx-csw.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-fico";hostname="sbx-fico.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-insights";hostname="sbx-insights.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-logging";hostname="sbx-logging.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-note-service";hostname="sbx-note-service.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-ods-internal-tools";hostname="sbx-ods-internal-tools.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-payment-domain-db";hostname="sbx-payment-domain-db.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-payment-recon-db";hostname="sbx-payment-recon-db.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-statements-api";hostname="sbx-statements-api.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    
    [pscustomobject]@{name="uat-agent-desk";hostname="uat-agent-desk.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-auth-identity-service";hostname="uat-auth-identity-service.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-bestegg-web-cluster";hostname="uat-bestegg-web-cluster.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-card";hostname="uat-card.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-collections";hostname="uat-collections.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-comm";hostname="uat-comm.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-csw";hostname="uat-csw.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-fico-service";hostname="uat-fico-service.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-insights";hostname="uat-insights.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-loanpro-data-import";hostname="uat-loanpro-data-import.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-logging";hostname="uat-logging.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-note-service";hostname="uat-note-service.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-ods-internal-tools";hostname="uat-ods-internal-tools.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-payment-domain-db";hostname="uat-payment-domain-db.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-payment-recon-db";hostname="uat-payment-recon-db.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-statements-api";hostname="uat-statements-api.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    
    [pscustomobject]@{name="prd-agent-desk";hostname="prd-agent-desk.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-auth-identity-service";hostname="prd-auth-identity-service.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-bestegg-web";hostname="prd-bestegg-web.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-card";hostname="prd-card.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-collections";hostname="prd-collections.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-comm";hostname="prd-comm.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-csw";hostname="prd-csw.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-fico-service";hostname="prd-fico-service.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-insights";hostname="prd-insights.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    # [pscustomobject]@{name="pre-prod-loanpro-data-import";hostname="pre-prod-loanpro-data-import.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-loanpro-data-import";hostname="prd-loanpro-data-import.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-loanpro-data-import-serverless";hostname="prd-loanpro-data-import-serverless.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-logging";hostname="prd-logging.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-note-service";hostname="prd-note-service.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-ods-internal-tools";hostname="prd-ods-internal-tools.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-payment-domain-db";hostname="prd-payment-domain-db.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-payment-recon-db";hostname="prd-payment-recon-db.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-statements-api";hostname="prd-statements-api.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
)
$query = 'select User from mysql.user where user like "%' + $search + '%"'

$username = "nate.hughes"
$sbx_encrypted_password = Get-Content D:\CredStore\sbx.txt | ConvertTo-SecureString
$uat_encrypted_password = Get-Content D:\CredStore\uat.txt | ConvertTo-SecureString
$prd_encrypted_password = Get-Content D:\CredStore\prd.txt | ConvertTo-SecureString

$mysql_array | ForEach {
    $mysql_name = $_.name
    $mysql_hostname = $_.hostname
    $environment = $mysql_name.substring(0,3)
    
    $encrypted_password = Switch ($environment) {
        "sbx" {$sbx_encrypted_password;break}
        "uat" {$uat_encrypted_password;break}
        "prd" {$prd_encrypted_password;break}
        "pre" {$prd_encrypted_password;break}
    }

    Try {
        $credential = New-Object System.Management.Automation.PsCredential($username, $encrypted_password)
        
        $mysql = Open-MySqlConnection  -Credential $credential -Server $mysql_hostname -Port "3306"

        $users = Invoke-SQLQuery -Query $query

        $users | Select -Property @{Name = "Server"; Expression = {$mysql_name}}, User, @{Name = "Drop"; Expression = {"DROP USER '" + $users.User + "'@'%';"}}
    } Catch {
        
        Write-Host "Server: $mysql_name  Error: $_.Exception.Message" -ForegroundColor Red
    }
}
